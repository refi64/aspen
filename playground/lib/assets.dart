import 'package:aspen/aspen.dart';
import 'package:aspen_assets/aspen_assets.dart';
import 'package:aspen_web/aspen_web.dart';

import 'assets.g.dart' as assets_g;

const assetsPrefix = 'asset:aspen_playground/assets/node_modules';

@Asset('$assetsPrefix/jquery/README.md')
const jqueryReadme = TextAsset(text: assets_g.jqueryReadme$content);

@Asset('$assetsPrefix/jquery/bower.json')
const bowerBinary = BinaryAsset(encoded: assets_g.bowerBinary$content);

@Asset('$assetsPrefix/octicons/build/data.json')
const octicons = JsonAsset(text: assets_g.octicons$content);

@Asset('$assetsPrefix/jquery/dist/jquery.slim.js',
    release: '$assetsPrefix/jquery/dist/jquery.slim.min.js')
const jquery = JsAsset(text: assets_g.jquery$content);

@Asset('$assetsPrefix/material-design-icons/iconfont/material-icons.css')
const icons =
    CssAsset(text: assets_g.icons$content, inline: CssAssetInline.all);
