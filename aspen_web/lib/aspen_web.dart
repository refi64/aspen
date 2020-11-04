@JS()
library aspen_web;

import 'dart:async';
import 'dart:html';

import 'package:aspen/aspen.dart';
import 'package:aspen_assets/aspen_assets.dart';
import 'package:js/js.dart';
import 'package:js/js_util.dart';

@JS('window')
external dynamic get _window;

@JS('eval.call')
external dynamic _eval(dynamic scope, String code);

int _jsCounter = 0;

/// An asset containing JavaScript code. The code within can be executed via [eval],
/// [evalSync], or [evalAsync].
class JsAsset extends TextAsset {
  const JsAsset({String text}) : super(text: text);

  /// Syncronously evaluate the code, with the given [scope] (the top-level window is the
  /// default scope).

  /// If [ddcAvoidMisdetect] is true and this file was compiled with DDC, steps will be
  /// taken to avoid the JavaScript code from thinking that DDC's window.define.amd means
  /// that this isn't being run in a browser.
  dynamic evalSync({dynamic scope, bool ddcAvoidMisdetect = true}) {
    dynamic define, amd;

    if (ddcAvoidMisdetect) {
      define = getProperty(_window, 'define');
      if (define != null) {
        amd = getProperty(define, 'amd');
        setProperty(define, 'amd', null);
      }
    }

    dynamic result = _eval(scope ?? _window, text);

    if (amd != null) {
      setProperty(define, 'amd', amd);
    }

    return result;
  }

  /// Asyncronously evaluate the code, completing the future once the code is run. Note
  /// that no DDC workarounds are performed, unlike evalSync.
  Future evalAsync() {
    var attr = r'aspen$js' + (_jsCounter++).toString();

    var el = ScriptElement();
    el.async = true;
    el.text = text + '; window.$attr()';

    var completer = Completer();
    setProperty(_window, attr, allowInterop(() => completer.complete()));

    document.head.append(el);
    return completer.future;
  }

  /// Evaluate the JavaScript code. If DDC is detected, [evalSync] is used to enable
  /// avoiding DDC's module loading being misinterpreted (see the [evalSync] docs for)
  /// more info. Otherwise, [evalAsync] is used.
  Future eval() async {
    dynamic define = getProperty(_window, 'define');
    if (define != null && getProperty(define, 'amd') != null) {
      evalSync();
    } else {
      await evalAsync();
    }

    return Future.value();
  }
}

class CssAssetInline {
  final bool inlineAll;
  final List<String> inlineOnly;

  const CssAssetInline._all(this.inlineAll) : inlineOnly = const <String>[];

  /// Only inline URIs in the given list.
  const CssAssetInline.only(this.inlineOnly) : inlineAll = false;

  /// Inline all URIs.
  static const all = CssAssetInline._all(true);

  /// Inline no URIs.
  static const none = CssAssetInline._all(false);
}

/// An asset containing a CSS stylesheet. URIs referenced from it can be inlined via the
/// [inline] constructor parameter. The CSS can be globally applied via [apply].
@LoadableAsset(
    url: 'package:aspen_builder/src/default_loaders.dart',
    loader: 'CssLoader')
class CssAsset extends TextAsset {
  /// Takes on one of:
  /// - [CssAssetInline.none] - Do not inline anything (the default).
  /// - [CssAssetInline.all] - Inline all URIs the stylesheet references.
  /// - [CssAssetInline.only()] - Only inline URIs in the given list.
  final CssAssetInline inline;

  const CssAsset({String text, this.inline = CssAssetInline.none})
      : super(text: text);

  void apply() {
    var el = StyleElement();
    el.text = text;
    document.head.append(el);
  }
}
