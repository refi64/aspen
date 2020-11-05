import 'dart:convert' as convert;

import 'package:aspen/aspen.dart';
import 'package:z85/z85.dart';

/// An asset containing plain text.
@LoadableAsset(
    url: 'package:aspen_builder/src/default_loaders.dart', loader: 'TextLoader')
class TextAsset implements FileAsset {
  final AssetData _data;

  const TextAsset(this._data);

  String get text => _data.content;
  String get assetId => _data.assetId;
}

/// An asset containing binary data, encoded via z85 encoding. The number of padding bytes
/// used to reach a length of a multiple of 4 (required by z85) is stored in the last byte,
/// and it includes itself.
///
/// The decoded data can be accessed via [decode()].
@LoadableAsset(
    url: 'package:aspen_builder/src/default_loaders.dart',
    loader: 'BinaryLoader')
class BinaryAsset implements FileAsset {
  final AssetData _data;

  const BinaryAsset(this._data);

  /// The z85-encoded data as a string.
  String get encoded => _data.content;
  String get assetId => _data.assetId;

  /// Return an iterable of the decoded binary data.
  Iterable<int> decode() {
    var decoded = z85.decode(encoded);
    var padding = decoded.last;
    return decoded.getRange(0, decoded.length - padding);
  }
}

/// An asset containing Json data. The data can be parsed via [json()].
class JsonAsset extends TextAsset {
  const JsonAsset(AssetData data) : super(data);

  /// Parse and return the json object.
  dynamic json() => convert.json.decode(text);
}

class AssetData {
  final String assetId;
  final String content;
  const AssetData(this.assetId, this.content);
}

abstract class FileAsset {
  // marker interface
}

/// An asset containing all files selected by the glob in [@Asset].
/// Limited to the current package.
class DirAsset<S extends FileAsset, T> {
  final Map<T, S> _fileAssets;
  const DirAsset(Map<T, S> fileAssets) : _fileAssets = fileAssets;
  S operator[](T assetKey) => _fileAssets[assetKey];
}