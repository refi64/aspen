# aspen

Aspen is a modern, easy-to-use asset packer for Dart, partly inspired by Poi and
Webpack. It can combine together your JavaScript, CSS, and text/binary assets into one
.js file, or multiple different files if you prefer.

**NOTE:** All of this is outdated and isn't even remotely still accurate.

## Installation

```
$ pub global activate aspen
```

If you need to use the `aspen_assets` package (see below for more info), add this to
your `pubspec.yaml`:

```yaml
dependencies:
  aspen_assets: ^0.2.0
```

## Usage

### Declaring JavaScript assets

The simplest way to use Aspen is kind of like this:

```yaml
targets:
  default:
    outputs:
      default: web/vendor.js

    assets:
    - node_modules/vue/dist/vue.js
```

This is defining the default target (fittingly named *default*) that consists of just
one asset.

Now just save this to `aspen.yml` run `aspen`. Aspen will combine the input assets and
output *web/vendor.js*. When you load *web/vendor.js* in your web browser, it will
automatically run *vue.js*.

However, in many cases you want to use a different file for development and
production builds. Aspen lets you do this via the *dev* and *prod* keys:

```yaml
targets:
  default:
    outputs:
      default: web/vendor.js

    assets:
    - dev: node_modules/vue/dist/vue.js
      prod: node_modules/vue/dist/vue.min.js
```

Now, *vue.js* is used for development builds and *vue.min.js* for production builds.
(You can perform a production build using `aspen -m prod`.)

Going back to the first example, this:

```yaml
assets:
- node_modules/vue/dist/vue.js
```

is just shorthand for this:

```yaml
assets:
- default: node_modules/vue/dist/vue.js
```

The *default* parameter just sets the same file to be used for both development and
production builds.

### Declaring CSS assets

CSS files work in a similar way:

```yaml
targets:
  default:
    outputs:
      default: web/vendor.js

    assets:
    - name: material-css  # <-- Note this for later!
      dev: node_modules/material-design-lite/material.css
      prod: node_modules/material-design-lite/material.min.css
```

However, unlike JavaScript assets, CSS assets won't be automatically applied. In order
to do so, you need to use the `aspen_assets` package. Here's an example:

```dart
import 'package:aspen_assets/aspen_assets.dart' as aspen;

void main() {
  aspen.loadGlobal('material-css');
}
```

Note that `aspen.loadGlobal` takes the name we specified above with `name: material-css`.

You can also access the CSS stylesheet by itself via `aspen.loadString`:

```dart
import 'package:aspen_assets/aspen_assets.dart' as aspen;

void main() {
  String css = aspen.loadString('material-css');
  print(css);
}
```

If you want your CSS to be applied automatically, use `autoload`:

```yaml
targets:
  default:
    outputs:
      default: web/vendor.js

    assets:
    - dev: node_modules/material-design-lite/material.css
      prod: node_modules/material-design-lite/material.min.css
      autoload: true
      # Notice we don't need a name now, but you can still pass one
```

### Loaders

The core idea behind Aspen is a *loader*, which defines how input assets are processed.
These are the built-in loaders (custom loaders will come in a future version):

- *binary*
- *text*
- *css*
- *json*
- *js*

The *js* loader is automatically picked for *.js* files, and the *css* loader is
automatically picked for *.css* files. The others must be manually specified. You can
do so like this:

```yaml
targets:
  default:
    outputs:
      default: web/vendor.js

    assets:
    - name: eye-octicon
      default: node_modules/octicons/eye.svg
      loader: text
```

The important thing to note is the `loader: text` section. This says that the input
asset will be using the *text* loader. Now it can be accessed like so:

```dart
import 'package:aspen_assets/aspen_assets.dart' as aspen;

void main() {
  String svg = aspen.loadString('eye-octicon');
  print(svg);
  // Do something with the svg contents.
}
```

The same thing can be done for binary assets:

```yaml
targets:
  default:
    outputs:
      default: web/vendor.js

    assets:
    - name: binary-asset
      default: some-file.bin
      loader: binary
```

```dart
import 'package:aspen_assets/aspen_assets.dart' as aspen;

void main() {
  List<int> binaryData = aspen.loadBinary('binary-asset');
}
```

Some loaders can take options. Well, right now it's only the CSS loader. It can take
an *inline* option specifying whether or not to inline assets. For instance, given
`inline-demo.css`:

```css
* {
  something: url('something');
  something-else: url('something-else');
}
```

You can use *inline* to specify some assets to inline:

```yaml
targets:
  default:
    outputs:
      default: web/vendor.js

    assets:
    - name: inline-demo-1
      default: inline-demo.css
      options:
        # inline: true means that everything will be inlined.
        inline: true

    - name: inline-demo-2
      default: inline-demo.css
      options:
        # You can also pass a list of paths to be inlined.
        inline: [something-else]

    - name: inline-demo-3
      default: inline-demo.css
      # If not specified, the default value of inline is false, meaning nothing will ever be inlined.
```

### Multiple output files

You can split assets into multiple different files based on their loader:

```yaml
targets:
  default:
    outputs:
      default: web/vendor.js
      text: web/text.js

    assets:
    - dev: node_modules/vue/dist/vue.js
      prod: node_modules/vue/dist/vue.min.js
    - name: material-css
      dev: node_modules/material-design-lite/material.css
      prod: node_modules/material-design-lite/material.min.css
    - name: eye-octicon
      default: node_modules/octicons/eye.svg
      loader: text
```

Here, all the assets will be placed in `web/vendor.js`, except for assets using the
`text` loader, which will be placed in `web/text.js`.

What if you have two files using the same loader that should be placed in different
output files? You can use loader aliases for that:

```yaml
loader-aliases:
  svg: text

targets:
  default:
    outputs:
      default: web/vendor.js
      text: web/text.js
      svg: web/svg.js

    assets:
    - dev: node_modules/vue/dist/vue.js
      prod: node_modules/vue/dist/vue.min.js
    - name: material-css
      dev: node_modules/material-design-lite/material.css
      prod: node_modules/material-design-lite/material.min.css
    - name: eye-octicon
      default: node_modules/octicons/eye.svg
      loader: svg
    - name: readme
      default: README.md
      loader: text
```

Here, a loader alias *svg* is created for the *text* loader. Now, *svg* is treated as if
it were its own loader, so anything redirected to this loader can be sent to a different
output file.
