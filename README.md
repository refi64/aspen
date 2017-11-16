# aspen

Aspen is a modern, easy-to-use asset packer for Dart. It can combine together your
JavaScript, CSS, and binary assets into one .js file, or multiple different files if
you prefer.

```yaml
kinds:
  custom-js: js

targets:
  default:
    out:
      default: .vendor.js
      css: .vendor.css

    assets:
    - dev: node_modules/vue/vue.js
      prod: node_modules/vue/vue.min.js
    - default: node_modules/arrive/arrive.min.js
      configs: [vendor-js]
      kind: custom-js
  prod:
    from: default
    assets:
    - secrets.js
```

```dart
import 'package:aspen_assets/aspen_assets.dart' as aspen;

void main() {
  Uint8List binaryAsset = aspen.loadBinary('myfile.png');
  String stringAsset = aspen.loadString('myfile.css');
  aspen.loadGlobal('myfile.css');
}
```
