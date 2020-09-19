# aspen

Aspen is a modern, easy-to-use asset packer for Dart, compatible with both server and client.

**NOTE:** Aspen 0.3 is an *enormous* breaking change from 0.2, but it's largely a net positive,
as it now integrates more closely with `package:build` and supports incremental builds.

## Installation

At minimum, you'll need the `aspen` and `aspen_assets` packages, as well as a dev dependency on
`aspen_builder`:

```yaml
dependencies:
  aspen: ^0.3.0
  aspen_assets: ^0.3.0
dev_dependencies:
  aspen_builder: ^0.3.0
```

If you want to embed web-related assets (e.g. JavaScript and CSS), you can add `aspen_web`, but
this will make your project web-only:

```yaml
dependencies:
  aspen: ^0.3.0
  aspen_assets: ^0.3.0
  aspen_web: ^0.3.0
dev_dependencies:
  aspen_builder: ^0.3.0
```

## Usage

### The idea

The basic idea of how Aspen works is that you create a `.dart` file, containing `@Asset`
annotations. Aspen will process this file and create a `.g.dart` file containing the
included assets.

### A simple example

Assume this all goes in `lib/assets.dart` in `my_package`:

```dart
import 'package:aspen/aspen.dart';
import 'package:aspen_assets/aspen_assets.dart';

// Here, we load the to-be-generated assets file, which contains the actual asset content.
part 'assets.g.dart';

// @Asset is an annotation from package:aspen that marks the asset to be packed.
@Asset('asset:my_package/web/my-asset.txt')
// We create a const (it must be const!) value that holds the generated asset content.
const myTextAsset = TextAsset(text: _myTextAsset$content);
// aspen_builder will use the value (here, it's TextAsset(...)) to determine what type of
// asset to use.

// We can also provide a different path to be used in release mode:
@Asset('asset:my_package/web/my-asset.bin', release: 'asset:my_package/web/my-assets.rel.bin')
// Here, instead, a BinaryAsset is used.
const myBinAsset = BinaryAsset(encoded: _myBinAsset$content);

// You can also have JSON assets (JsonAsset is a subclass of TextAsset).
@Asset('asset:my_package/web/my-asset.json')
const myJsonAsset = JsonAsset(text: _myJsonAsset$content);
```

Then, it can be accessed from our main file:

```dart
import 'package:my_package/assets.dart' as assets;

void main() {
  // The content of a text asset can be retrieved via the text property.
  String myTextAssetText = assets.myTextAsset.text;

  // The content of a binary asset can be decoded via the decode() method,
  // and the z85-encoded data can be retrieved via the encoded property.
  List<int> myBinaryAssetBytes = List<int>.from(assets.myBinAsset.decode());
  String myBinaryAssetUndecodedBytes = assets.myBinAsset.encoded;

  // A JSON asset can be parsed via the json() method.
  dynamic myJsonAssetParseJson = assets.myJsonAsset.json();
}
```

### Web assets

`package:aspen_web` provides some more assets handy for client-side web development. Say we put
this in `assets.dart`:

```dart
import 'package:aspen/aspen.dart';
import 'package:aspen_web/aspen_web.dart';

import 'assets.g.dart' as assets_g;

// A JsAsset (subclass of TextAsset) holds JavaScript code;
@Asset('asset:my_package/node_modules/vue/dist/vue.js',
       release: 'asset:my_package/node_modules/vue/dist/vue.min.js')
const myJsAsset = JsAsset(text: assets_g.myJsAsset$content);

// A CssAsset (again, subclass of TextAsset holds a CSS style sheet).
@Asset('asset:my_package/web/my-asset.css')
const myCssAsset = CssAsset(
  text: assets_g.myCssAsset$content,
  // Note the inline: argument below (if unset, it defaults to CssAssetInline.none).
  // If set to a value other than CssAssetInline.none, it will inline relative url(...)
  // expressions that may no longer work when the CSS is no longer being loaded from
  // next to the urls it references.
  // Valid values are CssAssetInline.all (inlines *all* url elements) and
  // CssAssetInline.only(['a', 'b']) (inlines only the urls in the given list).
  inline: CssAssetInline.all,
);
```

These can also be used from `index.dart`, but it also contains extra functionality:

```dart
import 'package:my_package/assets.dart' as assets;

void main() async {
  // A JsAsset and CssAsset are subclasses of TextAsset, so you can still use the text
  // property:
  String myJsAssetString = assets.myJsAsset.text;

  // However, they have some extra bonuses:

  // The JavaScript inside a JsAsset can be run in three ways: eval, evalSync, and evalAsync:
  //  - evalSync({dynamic scope, bool ddcAvoidMisdetect = true}) will run the JavaScript
  //    syncronously and return whatever result it may have. You can pass a custom scope to be
  //    used as the value of 'this' via the scope: argument. In addition, ddcAvoidMisdetect
  //    will use monkey-patching to avoid JavaScript code from thinking it's running in a
  //    CommonJS environment when using DDC rather than a browser.
  //  - evalAsync() will run the JavaScript asyncronously, returning a future that will complete
  //    once the code runs. You cannot check whether or not the code succeeded, nor can you
  //    get a result value. In addition, ddcAvoidMisdetect is impossible to emulate.
  //  - eval() will pick either evalSync() or evalAsync(), depending on whether or not
  //    ddcAvoidMisdetect is needed. It returns a future that either completes immediately
  //    (if the former is picked) or once the JS is run (if the latter is picked).

  // In general you'll want to use eval(), unless you have some other requirements.
  await assets.myJsAsset.eval();

  // The CSS inside a CssAsset can be globally applied to the entire document using the
  // apply method.
  assets.myCssAsset.apply;
}
```

### Using with JavaScript package managers

By default `package:build` only allows you to use assets from a [pre-defined
whitelist of directories](https://github.com/dart-lang/build/blob/build-v1.1.0/build_runner_core/lib/src/generate/options.dart#L19-L31). Therefore, aspen won't be able to read anything from e.g. a node_modules directory.

The easiest workaround is to save the assets into the `assets` directory, which *is* whitelisted. For instance,
with yarn, create a `.yarnrc` containing:

```
--*.modules-folder assets/node_modules
```

Then, whenever you run `yarn`, the modules will be saved to `assets/node_modules`, which will be picked up by `build`
because it's in the whitelisted `assets` directory.

## Changes from 0.2

...everything.

- The entire method of declaring assets has changed from a .yml file to a .dart file.
- Dart code is now generated, rather than JavaScript code. This allows you to import assets
  directly into your Dart code, and it also makes tree shaking far more effective.

You're best off reading this entire README first, then manually moving over from aspen.yml to
a .dart file.
