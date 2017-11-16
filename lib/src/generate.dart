import 'package:path/path.dart' as p;

import '../config.dart';
import '../loader.dart';
import 'loader_map.dart';

import 'dart:async';
import 'dart:io';

final JS_BASE = r'window.aspenAssets$v1 = window.aspenAssets$v1 || {};';

String jsString(String str) {
  var escaped = str.replaceAll(r'\\', r'\\\\').replaceAll(r"'", r"\'");
  return "'$escaped'";
}

class AssetResult {
  String code;
  String loader;
  AssetResult({this.code, this.loader});
}

Future<AssetResult> processAsset(Asset asset, BuildMode mode,
                                 LoaderMap loaderMap, LoaderContext context) async {
  var loader = loaderMap[asset.loader];
  var assetPath = new AssetPath(asset.modesToInputs[mode]);

  var js = await loader.toJs(context, assetPath);
  var kind = loader.kind;
  String code;

  if (loader is ScriptLoader) {
    code = js;
  } else {
    String globalLoad = loader is GlobalLoader ? loader.globalLoadJs : 'null';

    code = '''
window.aspenAssets\$v1[${jsString(asset.name)}] = {
  value: ($js),
  globalLoad: ($globalLoad),
  kind: '$kind'
};
    ''';
  }

  return new AssetResult(code: code, loader: asset.loader);
}

Future<Map<String, String>> processTarget(Target target, BuildMode mode,
                                          LoaderMap loaderMap) async {
  var context = new LoaderContext(Directory.current.path);
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
  await new Directory(p.dirname(output)).create(recursive: true);
  new File(output).writeAsString(code);
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

  await Future.wait(results.keys.map((loader) =>
                                      writeResult(loader, results[loader],
                                                  loadersToOutputs)));
  return new Future.value();
}

Future generateTarget(Target target, BuildMode mode, LoaderMap loaderMap) async {
  var results = await processTarget(target, mode, loaderMap);
  await writeResults(target.loadersToOutputs, results);
}
