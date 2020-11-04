import 'package:analyzer/dart/element/element.dart';
import 'package:aspen_builder/src/bundle_generator.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:mockito/mockito.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';

void main() {
  group('BundleGenerator', () {
    BundleGenerator generator;
    BuildStep buildStep;

    setUp(() async {
      generator = BundleGenerator(BuilderOptions({'release_asset': true}));
      buildStep = BuildStepMock();
    });

    test('creates TextAsset', () async {
      final assetId =
          AssetId.resolve('asset:packageName/assets//textAsset.txt');
      when(buildStep.canRead(assetId)).thenAnswer((_) => Future.value(true));
      when(buildStep.readAsString(assetId))
          .thenAnswer((_) => Future.value('content of textAsset.txt'));

      final result = await generate(textAsset, generator, buildStep);

      expect(
          result,
          equals(
              r"const String _textAsset$content = r'''content of textAsset.txt''';"));
    });

    test('creates BinaryAsset', () async {
      final assetId =
          AssetId.resolve('asset:packageName/assets/binaryAsset.jpg');
      when(buildStep.canRead(assetId)).thenAnswer((_) => Future.value(true));
      when(buildStep.readAsBytes(assetId))
          .thenAnswer((_) => Future.value('this is binary content'.codeUnits));

      final result = await generate(binaryAsset, generator, buildStep);

      expect(
          result,
          equals(
              r"const String _binaryAsset$content = r'''BzbxfazC)tvRGZ*A^n^qz/fVdzGC<W''';"));
    });

    test('creates JsonAsset', () async {
      final assetId =
          AssetId.resolve('asset:packageName/assets/jsonAsset.json');
      when(buildStep.canRead(assetId)).thenAnswer((_) => Future.value(true));
      when(buildStep.readAsString(assetId))
          .thenAnswer((_) => Future.value('["jsonAsset": true]'));

      final result = await generate(jsonAsset, generator, buildStep);

      expect(
          result,
          equals(r"const String _jsonAsset$content = r'''["
              '"jsonAsset"'
              ": true]''';"));
    });

    test('creates JsAsset', () async {
      final assetId = AssetId.resolve('asset:packageName/assets/jsAsset.js');
      when(buildStep.canRead(assetId)).thenAnswer((_) => Future.value(true));
      when(buildStep.readAsString(assetId))
          .thenAnswer((_) => Future.value('let js = true;'));

      final result = await generate(jsAsset, generator, buildStep);

      expect(result,
          equals(r"const String _jsAsset$content = r'''let js = true;''';"));
    });

    test('creates JsAsset with release version', () async {
      final assetId =
      AssetId.resolve('asset:packageName/assets/jsAsset.min.js');
      when(buildStep.canRead(assetId)).thenAnswer((_) => Future.value(true));
      when(buildStep.readAsString(assetId))
          .thenAnswer((_) => Future.value('let releaseJs = true;'));

      final result =
      await generate(releaseVersionOfAsset, generator, buildStep);

      expect(
          result,
          equals(
              r"const String _jsAsset$content = r'''let releaseJs = true;''';"));
    });

    test('creates CssAsset', () async {
      final assetId = AssetId.resolve('asset:packageName/assets/cssAsset.css');
      when(buildStep.canRead(assetId)).thenAnswer((_) => Future.value(true));
      when(buildStep.readAsString(assetId))
          .thenAnswer((_) => Future.value('body {}'));

      final result = await generate(cssAsset, generator, buildStep);

      expect(result,
          equals(r"const String _cssAsset$content = r'''body {" '\n' "}''';"));
    });
  });
}

Future<String> generate(
    String source, BundleGenerator generator, BuildStep buildStep) async {
  final libraryElement = await resolveSource<LibraryElement>(
      source, (resolver) => resolver.findLibraryByName(''));

  return await generator.generate(LibraryReader(libraryElement), buildStep);
}

class BuildStepMock extends Mock implements BuildStep {}

final textAsset = r'''
import 'package:aspen/aspen.dart';
import 'package:aspen_assets/aspen_assets.dart';

@Asset('asset:packageName/assets/textAsset.txt')
const textAsset = TextAsset(text: _textAsset$content);
''';

final binaryAsset = r'''
import 'package:aspen/aspen.dart';
import 'package:aspen_assets/aspen_assets.dart';

@Asset('asset:packageName/assets/binaryAsset.jpg')
const binaryAsset = BinaryAsset(encoded: _binaryAsset$content);
''';

final jsonAsset = r'''
import 'package:aspen/aspen.dart';
import 'package:aspen_assets/aspen_assets.dart';

@Asset('asset:packageName/assets/jsonAsset.json')
const jsonAsset = JsonAsset(text: _jsonAsset$content);
''';

final jsAsset = r'''
import 'package:aspen/aspen.dart';
import 'package:aspen_web/aspen_web.dart';

@Asset('asset:packageName/assets/jsAsset.js')
const jsAsset = JsAsset(text: _jsAsset$content);
''';

final cssAsset = r'''
import 'package:aspen/aspen.dart';
import 'package:aspen_web/aspen_web.dart';

@Asset('asset:packageName/assets/cssAsset.css')
const cssAsset = CssAsset(text: _cssAsset$content, inline: CssAssetInline.all);
''';

final releaseVersionOfAsset = r'''
import 'package:aspen/aspen.dart';
import 'package:aspen_web/aspen_web.dart';

@Asset('asset:packageName/assets/jsAsset.js', release: 'asset:packageName/assets/jsAsset.min.js')
const jsAsset = JsAsset(text: _jsAsset$content);
''';
