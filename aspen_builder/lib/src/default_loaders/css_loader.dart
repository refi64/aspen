import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:csslib/parser.dart' as css;
import 'package:csslib/visitor.dart';
import 'package:source_gen/source_gen.dart';

import '../../loader.dart';
import '../default_loaders.dart';

// Embeds the contents of URLs into the stylesheets.
class _UrlEmbedVisitor extends Visitor {
  LoaderContext ctx;
  AssetId asset;
  // If empty, then inline everything.
  List<String> inline;

  var futures = <Future>[];

  _UrlEmbedVisitor(this.ctx, this.asset, this.inline);

  @override
  void visitUriTerm(UriTerm node) {
    futures.add(visitUriTermAsync(node));
  }

  Future visitUriTermAsync(UriTerm node) async {
    if (inline.isNotEmpty && !inline.contains(node.value)) {
      // Skip inlining.
      return Future.value();
    }

    Uri uri;

    try {
      uri = Uri.parse(node.value);
    } on FormatException {
      ctx.error(node.span.message('invalid URI'), ownLine: true);
      return Future.value();
    }

    if (uri.hasAbsolutePath || uri.hasScheme) {
      return Future.value();
    }

    var target = AssetId.resolve(node.value, from: asset);
    if (!await ctx.buildStep.canRead(target)) {
      ctx.error(node.span.message('target of URI does not exist'),
          ownLine: true);
      return Future.value();
    }

    var contents = await ctx.buildStep.readAsBytes(target);
    var b64 = base64.encode(contents);
    node.text = 'data:;base64,$b64';
  }

  Future visitAndWait(StyleSheet style) {
    futures.clear();
    style.visit(this);
    return Future.wait(futures);
  }
}

class CssLoader extends TextLoader {
  @override
  Future<String> load(
      LoaderContext ctx, AssetId asset, ConstantReader options) async {
    var inlineOption = options.read('inline');
    var inlineAll = false;
    var inlineOnly = <String>[];

    if (!inlineOption.isNull) {
      inlineAll = inlineOption.read('inlineAll').boolValue;
      inlineOnly = inlineOption
          .read('inlineOnly')
          .listValue
          .map((x) => x.toStringValue())
          .toList();
    }

    var styleString = await ctx.buildStep.readAsString(asset);

    if (!inlineAll && inlineOnly.isEmpty) {
      return styleString;
    }

    var style = css.parse(styleString);

    var visitor = _UrlEmbedVisitor(ctx, asset, inlineOnly);
    await visitor.visitAndWait(style);

    var printer = CssPrinter();
    style.visit(printer);
    return Future.value(printer.toString());
  }
}
