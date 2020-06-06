import 'dart:convert' as convert;

import 'package:aspen/aspen.dart';
import 'package:z85/z85.dart';

/// An asset containing plain text.
@LoadableAsset(
    url: 'package:aspen_generator/src/default_loaders.dart',
    loader: 'TextLoader')
class TextAsset {
  final String text;

  const TextAsset({this.text});
}

/// An asset containing binary data, encoded via z85 encoding. The number of padding bytes
/// used to reach a length of a multiple of 4 (required by z85) is stored in the last byte,
/// and it includes itself.
///
/// The decoded data can be accessed via [decode()].
@LoadableAsset(
    url: 'package:aspen_generator/src/default_loaders.dart',
    loader: 'BinaryLoader')
class BinaryAsset {
  /// The z85-encoded data as a string.
  final String encoded;

  const BinaryAsset({this.encoded});

  /// Return an iterable of the decoded binary data.
  Iterable<int> decode() {
    var decoded = z85.decode(encoded);
    var padding = decoded.last;
    return decoded.getRange(0, decoded.length - padding);
  }
}

/// An asset containing Json data. The data can be parsed via [json()].
class JsonAsset extends TextAsset {
  const JsonAsset({String text}) : super(text: text);

  /// Parse and return the json object.
  dynamic json() => convert.json.decode(text);
}
