import 'package:path/path.dart' as p;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';


class AssetPath {
  String path;
  AssetPath(this.path);
}

class LoaderContext {
  String _root;
  LoaderContext(this._root);

  File _getFileForAsset(AssetPath asset) {
    var path = p.join(this._root, asset.path);
    return new File(path);
  }

  Future<bool> exists(AssetPath asset) => _getFileForAsset(asset).exists();

  Future<String> readAsString(AssetPath asset) =>
    _getFileForAsset(asset).readAsString();
  Future<Uint8List> readAsBytes(AssetPath asset) =>
    _getFileForAsset(asset).readAsBytes();
}

abstract class Loader {
  String get name;
  String get kind;
  List<String> get extensions => null;
  Future<String> toJs(LoaderContext context, AssetPath asset);
}

abstract class _BaseEncoder {
  Future<String> process(LoaderContext context, AssetPath asset) =>
    context.readAsString(asset);
  Future<String> toJs(LoaderContext context, AssetPath asset) async =>
    process(context, asset);
}

abstract class _BinaryEncoder {
  Future<List<int>> process(LoaderContext context, AssetPath asset) =>
    context.readAsBytes(asset);
  Future<String> toJs(LoaderContext context, AssetPath asset) async =>
    new Future.value("'${BASE64.encode(await process(context, asset))}'");
}

abstract class _StringEncoder {
  Future<String> process(LoaderContext context, AssetPath asset) =>
    context.readAsString(asset);
  Future<String> toJs(LoaderContext context, AssetPath asset) async =>
    new Future.value("'${BASE64.encode(UTF8.encode(await process(context, asset)))}'");
}

abstract class GlobalLoader extends Loader {
  String get globalLoadJs => null;
}

abstract class BinaryLoader extends GlobalLoader with _BinaryEncoder {
  final kind = 'binary';
}

abstract class StringLoader extends GlobalLoader with _StringEncoder {
  final kind = 'string';
}

abstract class ObjectLoader extends GlobalLoader with _BaseEncoder {
  final kind = 'object';
}

abstract class ScriptLoader extends Loader with _BaseEncoder {
  final kind = 'script';
}
