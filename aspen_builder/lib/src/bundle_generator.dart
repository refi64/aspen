import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

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

    var current = type as InterfaceType;
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

    error(variableElement,
        'Asset type ${type.displayName} has no @LoadableAsset annotation');
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

    var loadableAsset = getLoadableAsset(variableElement);
    if (loadableAsset == null) {
      return Future.value();
    }

    assert(
        loadableAsset.url == 'package:aspen_builder/src/default_loaders.dart');

    var loader = defaultLoaders[loadableAsset.loader];

    var assetPathReader;

    if (options.config['release_asset'] == true) {
      assetPathReader = annotation.read('releasePath');
      if (assetPathReader.isNull) {
        assetPathReader = annotation.read('path');
      }
    } else {
      assetPathReader = annotation.read('path');
    }

    var assetId =
        AssetId.resolve(assetPathReader.stringValue, from: buildStep.inputId);
    if (!await buildStep.canRead(assetId)) {
      error(element, 'Asset ${assetId} cannot be found');
      return Future.value();
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

      return Future.value();
    }

    return Future.value(
        "const String _${variableElement.name}\$content = r'''${content}''';");
  }
}
