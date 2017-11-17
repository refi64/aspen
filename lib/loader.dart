import 'package:path/path.dart' as p;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// An input asset.
class AssetPath {
  String path;
  AssetPath(this.path);
}

/// The context passed to loader processing methods. Used for accessing the file system
/// from the loader.
class LoaderContext {
  String _root;
  LoaderContext(this._root);

  File _getFileForAsset(AssetPath asset) {
    var path = p.join(this._root, asset.path);
    return new File(path);
  }

  /// Checks if the asset exists.
  Future<bool> exists(AssetPath asset) => _getFileForAsset(asset).exists();

  /// Reads the asset's contents as a string.
  Future<String> readAsString(AssetPath asset) =>
    _getFileForAsset(asset).readAsString();
  /// Reads the asset's contains as a list of bytes.
  Future<List<int>> readAsBytes(AssetPath asset) =>
    _getFileForAsset(asset).readAsBytes();
}

/// An abstract loader. Custom loaders should derive from one of the below subclasses,
/// not this one.
abstract class Loader {
  /// The loader's name.
  String get name;
  /// The loader's "kind". Custom loaders should not override this.
  String get kind;
  /// A list of extensions the custom loader accepts.
  List<String> get extensions => null;
  /// Converts the given asset to a JavaScript expression or statement. Custom loaders
  /// should not override this!
  Future<String> toJs(LoaderContext context, AssetPath asset);
}

abstract class _BaseEncoder {
  /// Returns a string containing the contents of the given asset.
  ///
  /// Custom loaders that subclass [ObjectLoader] and [ScriptLoader] may override
  /// this method to apply custom transformations to the asset.
  Future<String> process(LoaderContext context, AssetPath asset) =>
    context.readAsString(asset);
  Future<String> toJs(LoaderContext context, AssetPath asset) async =>
    process(context, asset);
}

abstract class _BinaryEncoder {
  /// Returns a list of bytes containing the contents of the given asset.
  ///
  /// Custom loaders that subclass [ObjectLoader] and [ScriptLoader] may override
  /// this method to apply custom transformations to the asset.
  Future<List<int>> process(LoaderContext context, AssetPath asset) =>
    context.readAsBytes(asset);
  Future<String> toJs(LoaderContext context, AssetPath asset) async =>
    new Future.value("'${BASE64.encode(await process(context, asset))}'");
}

abstract class _StringEncoder {
  /// Returns a string containing the contents of the given asset.
  ///
  /// Custom loaders that subclass [ObjectLoader] and [ScriptLoader] may override
  /// this method to apply custom transformations to the asset.
  Future<String> process(LoaderContext context, AssetPath asset) =>
    context.readAsString(asset);
  Future<String> toJs(LoaderContext context, AssetPath asset) async =>
    new Future.value("'${BASE64.encode(UTF8.encode(await process(context, asset)))}'");
}

/// A loader that supports aspen.loadGlobal. Custom loaders should derive from either
/// [BinaryLoader], [StringLoader], or [ObjectLoader] instead.
abstract class GlobalLoader extends Loader {
  /// Returns a JavaScript function that will be called with an asset's contents and will
  /// be used to globally load it.
  ///
  /// If this returns null, then the given loader will not support global loading.
  String get globalLoadJs => null;
}

/// A [BinaryLoader] loads a generic binary file whose contents will be accessible via
/// loadBinary.
abstract class BinaryLoader extends GlobalLoader with _BinaryEncoder {
  final kind = 'binary';
}

/// A [StringLoader] loads a generic string whose contents will be accessible via
/// loadString.
abstract class StringLoader extends GlobalLoader with _StringEncoder {
  final kind = 'string';
}

/// An [ObjectLoader] loads a valid JavaScript expression that will be accessible via
/// loadObject.
abstract class ObjectLoader extends GlobalLoader with _BaseEncoder {
  final kind = 'object';
}

/// A [ScriptLoader] loads a JavaScript script.
///
/// The script cannot be accessed via loadBinary, loadString, or loadGlobal; it will be
/// immediately executed when the output script is loaded.
abstract class ScriptLoader extends Loader with _BaseEncoder {
  final kind = 'script';
}
