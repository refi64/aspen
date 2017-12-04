import '../../loader.dart';
import '../console.dart';

import 'package:csslib/parser.dart' as css;
import 'package:csslib/visitor.dart';
import 'package:path/path.dart' as p;

import 'dart:async';
import 'dart:convert';


// Embeds the contents of URLs into the stylesheets.
class _UrlEmbedVisitor extends Visitor {
  LoaderContext context;
  AssetPath asset;

  var futures = <Future>[];

  _UrlEmbedVisitor(this.context, this.asset);

  void visitUriTerm(UriTerm node) {
    futures.add(visitUriTermAsync(node));
  }

  Future visitUriTermAsync(UriTerm node) async {
    Uri uri;

    try {
      uri = Uri.parse(node.value);
    } on FormatException {
      var message = node.span.message('invalid URI');
      warn('$asset: $message');
      return new Future.value();
    }

    if (uri.hasAbsolutePath || uri.hasScheme) {
      return new Future.value();
    }

    var target = new AssetPath(p.join(p.dirname(asset.path), node.value));
    if (!await context.exists(target)) {
      var message = node.span.message('target of URI does not exist');
      warn('$asset: $message');
      return new Future.value();
    }

    var contents = await context.readAsBytes(target);
    var base64 = BASE64.encode(contents);
    node.text = 'data:;base64,$base64';
  }

  Future visitAndWait(StyleSheet style) {
    futures.clear();
    style.visit(this);
    return Future.wait(futures);
  }
}


/// Loads a CSS stylesheet. The stylesheet will be appended to the document head if
/// loadGlobal is called.
class CssLoader extends StringLoader {
  final name = 'css';
  final extensions = ['.css'];

  Future<String> process(LoaderContext context, AssetPath asset) async {
    var styleString = await context.readAsString(asset);
    var style = css.parse(styleString);

    var visitor = new _UrlEmbedVisitor(context, asset);
    await visitor.visitAndWait(style);

    var printer = new CssPrinter();
    style.visit(printer);
    return new Future.value(printer.toString());
  }

  final globalLoadJs = '''
  function (data) {
    var st = document.createElement('style');
    st.appendChild(document.createTextNode(data));
    document.head.appendChild(st);
  }
  ''';
}
