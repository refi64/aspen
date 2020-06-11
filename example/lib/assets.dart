import 'package:aspen/aspen.dart';
import 'package:aspen_assets/aspen_assets.dart';
import 'package:aspen_web/aspen_web.dart';

part 'assets.g.dart';

const assetsPrefix = 'asset:aspen_playground/assets/node_modules';

@Asset('$assetsPrefix/jquery/README.md')
const jqueryReadme = TextAsset(text: _jqueryReadme$content);

@Asset('$assetsPrefix/jquery/bower.json')
const bowerBinary = BinaryAsset(encoded: _bowerBinary$content);

@Asset('$assetsPrefix/octicons/build/data.json')
const octicons = JsonAsset(text: _octicons$content);

@Asset('$assetsPrefix/jquery/dist/jquery.slim.js',
    release: '$assetsPrefix/jquery/dist/jquery.slim.min.js')
const jquery = JsAsset(text: _jquery$content);

@Asset('$assetsPrefix/material-design-icons/iconfont/material-icons.css')
const icons = CssAsset(text: _icons$content, inline: CssAssetInline.all);
