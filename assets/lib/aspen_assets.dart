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

dynamic _load(String name, String kind) {
  _Asset asset = getProperty(_assets, name);
  if (asset == null) {
    throw new AssetError('Unknown asset $name');
  }

  if (kind == 'global') {
    var globalLoad = asset.globalLoad;
    if (globalLoad == null) {
      throw new AssetError('Asset $name cannot be globally loaded');
    }
    globalLoad(UTF8.decode(BASE64.decode(asset.value)));
    return null;
  } else if (asset.kind == 'script') {
    throw new AssetError('Asset $name is a script and cannot be loaded');
  } else if (asset.kind != kind) {
    throw new AssetError('Asset $name has kind ${asset.kind}, not $kind');
  } else {
    var result = asset.value;
    switch (kind) {
    case 'object': return result;
    case 'string': return UTF8.decode(BASE64.decode(result));
    case 'binary': return BASE64.decode(result);
    }
  }
}

/// Loads the given string asset.
String loadString(String name) => _load(name, 'string');
/// Loads the given binary asset.
List<int> loadBinary(String name) => _load(name, 'binary');
/// Loads the given object asset.
dynamic loadObject(String name) => _load(name, 'object');
/// Globally loads the given asset.
void loadGlobal(String name) { _load(name, 'global'); }
