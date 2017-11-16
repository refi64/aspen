@JS()
library aspen_assets;

import 'package:js/js.dart';
import 'package:js/js_util.dart';

import 'dart:convert';
import 'dart:typed_data';

@anonymous
@JS()
class _Asset {
  external Function get globalLoad;
  external String get kind;
  external dynamic get value;
}

@JS(r'aspenAssets$v1')
external dynamic get _assets;

class AssetError implements Exception {
  String _cause;
  AssetError(this._cause);
  String toString() => 'AssetError: $_cause';
}

dynamic _load(String path, String kind) {
  _Asset asset = getProperty(_assets, path);
  if (asset == null) {
    throw new AssetError('Unknown asset $path');
  }

  if (kind == 'global') {
    var globalLoad = asset.globalLoad;
    if (globalLoad == null) {
      throw new AssetError('Asset $path cannot be globally loaded');
    }
    globalLoad(asset.value);
    return null;
  } else if (asset.kind == 'script') {
    throw new AssetError('Asset $path is a script and cannot be loaded');
  } else if (asset.kind != kind) {
    throw new AssetError('Asset $path has kind ${asset.kind}, not $kind');
  } else {
    var result = asset.value;
    switch (kind) {
    case 'object': return result;
    case 'string': return UTF8.decode(BASE64.decode(result));
    case 'binary': return BASE64.decode(result);
    }
  }
}

String loadString(String path) => _load(path, 'string');
List<int> loadBinary(String path) => _load(path, 'binary');
dynamic loadObject(String path) => _load(path, 'object');
void loadGlobal(String path) { _load(path, 'global'); }
