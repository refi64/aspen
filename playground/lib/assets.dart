import 'package:aspen/aspen.dart';
import 'package:aspen_assets/aspen_assets.dart';
import 'package:aspen_web/aspen_web.dart';

import 'assets.g.dart' as assets_g;

@Asset('asset:aspen_playground/node_modules/jquery/README.md')
const jqueryReadme = TextAsset(text: assets_g.jqueryReadme$content);

@Asset('asset:aspen_playground/node_modules/jquery/bower.json')
const bowerBinary = BinaryAsset(encoded: assets_g.bowerBinary$content);

@Asset('asset:aspen_playground/node_modules/octicons/build/data.json')
const octicons = JsonAsset(text: assets_g.octicons$content);

@Asset('asset:aspen_playground/node_modules/jquery/dist/jquery.slim.js',
       release: 'asset:aspen_playground/node_modules/jquery/dist/jquery.slim.min.js')
const jquery = JsAsset(text: assets_g.jquery$content);

@Asset('asset:aspen_playground/node_modules/material-design-icons/iconfont/material-icons.css')
const icons = CssAsset(text: assets_g.icons$content, inline: CssAssetInline.all);
