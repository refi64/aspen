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
  external bool get globalLoadCompleted;
  external set globalLoadCompleted(bool value);
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
    if (asset.globalLoadCompleted) {
      throw new AssetError('Asset $name has already been globally loaded');
    }

    var globalLoad = asset.globalLoad;
    if (globalLoad == null) {
      throw new AssetError('Asset $name cannot be globally loaded');
    }
    globalLoad(utf8.decode(base64.decode(asset.value)));
    asset.globalLoadCompleted = true;

    return null;
  } else if (asset.kind == 'script') {
    throw new AssetError('Asset $name is a script and cannot be loaded');
  } else if (asset.kind != kind) {
    throw new AssetError('Asset $name has kind ${asset.kind}, not $kind');
  } else {
    var result = asset.value;
    switch (kind) {
    case 'object': return result;
    case 'string': return utf8.decode(base64.decode(result));
    case 'binary': return base64.decode(result);
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
