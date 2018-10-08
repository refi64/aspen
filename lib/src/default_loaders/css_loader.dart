import '../../loader.dart';
import '../console.dart';

import 'package:csslib/parser.dart' as css;
import 'package:csslib/visitor.dart';
import 'package:path/path.dart' as p;

import 'dart:async';
import 'dart:convert';


/// Embeds the contents of URLs into the stylesheets.
class _UrlEmbedVisitor extends Visitor {
  LoaderContext context;
  AssetPath asset;
  /// An optional list of URLs whose contents should be inlined into the CSS file. If
  /// null, everything will be inlined.
  List<String> inline;

  var futures = <Future>[];

  _UrlEmbedVisitor(this.context, this.asset, this.inline);

  void visitUriTerm(UriTerm node) {
    futures.add(visitUriTermAsync(node));
  }

  Future visitUriTermAsync(UriTerm node) async {
    if (inline != null && !inline.contains(node.value)) {
      // Skip inlining.
      return new Future.value();
    }

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
    var b64 = base64.encode(contents);
    node.text = 'data:;base64,$b64';
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

  Future<String> process(LoaderContext context, AssetPath asset, Map options) async {
    var inlineOption = options['inline'] ?? false;
    List<String> inline;

    if (inlineOption is List) {
      for (var item in inlineOption) {
        if (item is! String) {
          print(''); // close off progress.
          error('CSS loader inline option should be a bool or list of strings.');
        }
      }

      inline = inlineOption;
    } else if (inlineOption is bool) {
      if (inlineOption) {
        // Signal the _UrlEmbedVisitor to inline everything.
        inline = null;
      } else {
        return context.readAsString(asset);
      }
    } else {
      print(''); // close off progress.
      error('CSS loader inline option should be a bool or list of strings.');
    }

    var styleString = await context.readAsString(asset);
    var style = css.parse(styleString);

    var visitor = new _UrlEmbedVisitor(context, asset, inline);
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
