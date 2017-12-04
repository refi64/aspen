import 'package:path/path.dart' as p;

import '../config.dart';
import '../loader.dart';
import 'console.dart';
import 'loader_map.dart';

import 'dart:async';
import 'dart:io';

final JS_BASE = r'window.aspenAssets$v1 = window.aspenAssets$v1 || {};';

String jsString(String str) {
  var escaped = str.replaceAll(r'\\', r'\\\\').replaceAll(r"'", r"\'");
  return "'$escaped'";
}

class GlobalProgressData {
  int completed = 0, total;
  GlobalProgressData({this.total});
}

GlobalProgressData globalProgressData;

class AssetResult {
  String code;
  String loader;
  AssetResult({this.code, this.loader});
}

Future<AssetResult> processAsset(Asset asset, BuildMode mode, LoaderMap loaderMap,
                                 LoaderContext context) async {
  var loader = loaderMap[asset.loader];
  var assetPath = new AssetPath(asset.modesToInputs[mode]);

  showProgress(current: globalProgressData.completed, total: globalProgressData.total,
               message: 'begin processing $assetPath');

  String js;
  try {
    js = await loader.toJs(context, assetPath, asset.options);
  } catch (ex) {
    print('');
    rethrow;
  }

  var kind = loader.kind;
  String code;

  if (loader is ScriptLoader) {
    code = js;
  } else {
    String globalLoad = loader is GlobalLoader ? loader.globalLoadJs : 'null';
    var jsName = jsString(asset.name);
    var variable = 'window.aspenAssets\$v1[$jsName]';

    if (asset.autoload) {
      code = '($globalLoad)(window.atob($js));';
    } else {
      code = '''
$variable = {
  value: ($js),
  globalLoad: ($globalLoad),
  kind: '$kind'
};
    ''';
    }
  }

  globalProgressData.completed += 1;
  showProgress(current: globalProgressData.completed, total: globalProgressData.total,
               message: 'done processing $assetPath');
  return new AssetResult(code: code, loader: asset.loader);
}

Future<Map<String, String>> processTarget(Target target, BuildMode mode,
                                          LoaderMap loaderMap) async {
  var context = new LoaderContext(Directory.current.path);

  globalProgressData = new GlobalProgressData(total: target.assets.length);
  var results = await Future.wait(target.assets.map((asset) =>
                                    processAsset(asset, mode, loaderMap, context)),
                                  eagerError: true);
  var loadersToCodeList = <String, List<String>>{};

  for (var result in results) {
    loadersToCodeList.putIfAbsent(result.loader, () => [JS_BASE]);
    loadersToCodeList[result.loader].add(result.code);
  }

  return new Map.fromIterables(loadersToCodeList.keys,
                loadersToCodeList.values.map((v) => v.join('\n')));
}

Future writeResult(String loader, String code,
                   Map<String, String> loadersToOutputs) async {
  var output = loadersToOutputs[loader];

  showProgress(current: globalProgressData.completed, total: globalProgressData.total,
               message: 'begin writing $loader: $output');

  await new Directory(p.dirname(output)).create(recursive: true);
  await new File(output).writeAsString(code);

  globalProgressData.completed += 1;
  showProgress(current: globalProgressData.completed, total: globalProgressData.total,
               message: 'done writing $loader: $output');

  return new Future.value();
}

Future writeResults(Map<String, String> loadersToOutputs,
                    Map<String, String> results) async {
  var defaultBuffer = new StringBuffer();

  for (var loader in new List.from(results.keys)) {
    if (!loadersToOutputs.containsKey(loader)) {
      defaultBuffer.write(results.remove(loader));
    }
  }

  var defaultCode = defaultBuffer.toString();
  if (!defaultCode.isEmpty) {
    results['default'] = defaultCode;
  }

  var loaders = new List.from(results.keys);
  globalProgressData = new GlobalProgressData(total: loaders.length);

  await Future.wait(loaders.map((loader) =>
                                  writeResult(loader, results[loader],
                                              loadersToOutputs)));
  return new Future.value();
}

Future generateTarget(Target target, BuildMode mode, LoaderMap loaderMap) async {
  note('Generating target ${target.name}...');

  var watch = new Stopwatch();
  watch.start();

  var results = await processTarget(target, mode, loaderMap);
  print('');

  await writeResults(target.loadersToOutputs, results);
  print('');

  watch.stop();

  var elapsed = watch.elapsed;
  var seconds = elapsed.inSeconds + (elapsed.inMilliseconds / 1000);
  success('Processed ${target.assets.length} assets in ${seconds.toStringAsFixed(3)}s.');
}
