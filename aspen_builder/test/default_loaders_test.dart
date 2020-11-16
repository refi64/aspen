import 'package:aspen_assets/aspen_assets.dart';
import 'package:aspen_builder/loader.dart';
import 'package:aspen_builder/src/default_loaders.dart';
import 'package:build/build.dart';
import 'package:mockito/mockito.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';

void main() {
  group('BinaryLoader', () {
    BinaryLoader loader;
    LoaderContextMock ctx;
    AssetIdMock asset;
    ConstantReaderMock options;
    BuildStepMock buildStep;
    Future<List<int>> Function(List<int> source) encodeAndDecode;
    setUp(() {
      ctx = LoaderContextMock();
      asset = AssetIdMock();
      options = ConstantReaderMock();
      buildStep = BuildStepMock();
      encodeAndDecode = (source) async {
        when(buildStep.readAsBytes(asset))
            .thenAnswer((_) => Future.value(source));

        final encoded = await loader.load(ctx, asset, options);
        return BinaryAsset(AssetData('', encoded)).decode().toList();
      };

      when(ctx.buildStep).thenReturn(buildStep);

      loader = BinaryLoader();
    });

    test('handles files with length % 4 == 0', () async {
      final source = ''.codeUnits;
      final result = await encodeAndDecode(source);

      expect(result, equals(source));
    });

    test('handles files with length % 4 == 1', () async {
      final source = 'A'.codeUnits;
      final result = await encodeAndDecode(source);

      expect(result, equals(source));
    });

    test('handles files with length % 4 == 2', () async {
      final source = 'AB'.codeUnits;
      final result = await encodeAndDecode(source);

      expect(result, equals(source));
    });

    test('handles files with length % 4 == 3', () async {
      final source = 'ABC'.codeUnits;
      final result = await encodeAndDecode(source);

      expect(result, equals(source));
    });
  });
}

class LoaderContextMock extends Mock implements LoaderContext {}

class AssetIdMock extends Mock implements AssetId {}

class ConstantReaderMock extends Mock implements ConstantReader {}

class BuildStepMock extends Mock implements BuildStep {}
