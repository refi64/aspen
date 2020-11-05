import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:aspen_assets/aspen_assets.dart';
import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:source_gen/source_gen.dart';
import 'package:path/path.dart' as p;

import 'package:aspen/aspen.dart';

import '../loader.dart';
import 'default_loaders.dart';

class LoaderException implements Exception {
  final String message;
  final bool ownLine;

  LoaderException(this.message, {this.ownLine});
  @override
  String toString() => message;
}

class LoaderContextImpl implements LoaderContext {
  @override
  final BuildStep buildStep;

  LoaderContextImpl(this.buildStep);

  @override
  void error(String message, {bool ownLine = false}) {
    throw LoaderException(message, ownLine: ownLine);
  }
}

class BundleGenerator extends GeneratorForAnnotation<Asset> {
  BuilderOptions options;

  BundleGenerator(this.options);

  void error(Element element, String error) {
    log.severe(spanForElement(element).message(error));
  }

  LoadableAsset getLoadableAsset(VariableElement variableElement) {
    DartType type = variableElement.computeConstantValue().type;
    if (!(type is InterfaceType)) {
      error(variableElement,
          '@Asset(...) ${variableElement.displayName} has an invalid type');
    }

    final loadableAsset = getLoadableAssetForType(type);

    if (loadableAsset == null) {
      error(variableElement,
          'Asset type ${type.getDisplayString(withNullability: true)} has no @LoadableAsset annotation');
    }
    return loadableAsset;
  }

  LoadableAsset getLoadableAssetForType(InterfaceType type) {
    var current = type;
    while (current != null) {
      for (var ann in current.element.metadata) {
        var annValue = ann.computeConstantValue();
        if (annValue != null && typeNameOf(annValue.type) == 'LoadableAsset') {
          return LoadableAsset(
              url: annValue.getField('url').toStringValue(),
              loader: annValue.getField('loader').toStringValue());
        }
      }

      current = current.superclass;
    }
    return null;
  }

  @override
  Future<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) async {
    if (!(element is VariableElement)) {
      error(element, '@Asset(...) may only be used on variables');
      return Future.value();
    }

    var variableElement = element as VariableElement;
    var value = variableElement.computeConstantValue();
    if (value == null) {
      error(element,
          '@Asset(...) ${element.displayName} must have a constant value');
      return Future.value();
    }

    final assetPathReader = _getAssetPathReader(annotation);
    final assetPath = assetPathReader.stringValue;

    if (variableElement.type.element.name == 'DirAsset') {
      final assetDirId = AssetId.resolve(assetPath, from: buildStep.inputId);
      if (buildStep.inputId.package != assetDirId.package) {
        error(element,
            'DirAsset only works for the current package (current: ${buildStep.inputId.package}, requested: ${assetDirId.package})');
      }
      var assetDirPath = assetDirId.path;
      final firstIndexOfWildcard = assetDirPath.indexOf('*');
      if (firstIndexOfWildcard == -1) {
        assetDirPath = '$assetDirPath/*.*';
      }

      final assetType =
          (variableElement.type as InterfaceType).typeArguments[0];
      final loadableAsset = getLoadableAssetForType(assetType);

      if (loadableAsset == null) {
        error(variableElement,
            'DirAsset type $assetType has no @LoadableAsset annotation');
        return Future.value();
      }

      final enumName =
          '${element.name[0].toUpperCase()}${element.name.substring(1)}';
      final enumValues = <String, AssetData>{};
      final enumValueSanitzerRegExp = RegExp('[^a-zA-Z0-9]');

      final assetIds = buildStep.findAssets(Glob(assetDirPath));
      await for (final assetId in assetIds) {
        var enumValue =
            '${p.basenameWithoutExtension(assetId.path).replaceAll(enumValueSanitzerRegExp, '')}';
        final extension = p.extension(assetId.path);
        if (extension.isNotEmpty) {
          enumValue =
              '$enumValue\$${extension.replaceAll(enumValueSanitzerRegExp, '')}';
        }
        enumValues[enumValue] = await _loadAssetData(
            loadableAsset, buildStep, assetId, element, value);
      }

      return Future.value('''
enum $enumName {
  ${enumValues.keys.join(', ')}
}
const _${variableElement.name}\$asset = {
  ${enumValues.entries.map((entry) => '$enumName.${entry.key}: ${assetType.element.name}(AssetData(r\'${entry.value.assetId}\', r\'\'\'${entry.value.content}\'\'\'))').join(',\n')}
};
''');
    } else {
      final assetId = AssetId.resolve(assetPath, from: buildStep.inputId);
      final loadableAsset = getLoadableAsset(variableElement);
      final assetData = await _loadAssetData(
          loadableAsset, buildStep, assetId, element, value);

      return Future.value(
          "const _${variableElement.name}\$asset = AssetData(r'${assetData.assetId}', r'''${assetData.content}''');");
    }
  }

  Future<AssetData> _loadAssetData(
      LoadableAsset loadableAsset,
      BuildStep buildStep,
      AssetId assetId,
      Element element,
      DartObject value) async {
    final assetIdString = assetId.toString();
    if (loadableAsset == null) {
      return AssetData(assetIdString, '');
    }

    assert(
        loadableAsset.url == 'package:aspen_builder/src/default_loaders.dart');

    final loader = defaultLoaders[loadableAsset.loader];

    if (!await buildStep.canRead(assetId)) {
      error(element, 'Asset ${assetId} cannot be found');
      return AssetData(assetIdString, '');
    }

    String content;

    try {
      content = await loader()
          .load(LoaderContextImpl(buildStep), assetId, ConstantReader(value));
    } on LoaderException catch (ex) {
      if (ex.ownLine) {
        error(element, '${loadableAsset} failed');
        log.severe(ex.message);
      } else {
        error(element, '${loadableAsset.loader} failed with: ${ex.message}');
      }

      return AssetData(assetIdString, '');
    }
    return AssetData(assetIdString, content);
  }

  ConstantReader _getAssetPathReader(ConstantReader annotation) {
    var assetPathReader;

    if (options.config['release_asset'] == true) {
      assetPathReader = annotation.read('releasePath');
      if (assetPathReader.isNull) {
        assetPathReader = annotation.read('path');
      }
    } else {
      assetPathReader = annotation.read('path');
    }
    return assetPathReader;
  }
}
