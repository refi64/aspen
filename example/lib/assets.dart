import 'package:aspen/aspen.dart';
import 'package:aspen_assets/aspen_assets.dart';
import 'package:aspen_web/aspen_web.dart';

part 'assets.g.dart';

const assetsPrefix = 'asset:aspen_playground/assets/node_modules';

@Asset('$assetsPrefix/jquery/README.md')
const jqueryReadme = TextAsset(_jqueryReadme$asset);

@Asset('$assetsPrefix/jquery/bower.json')
const bowerBinary = BinaryAsset(_bowerBinary$asset);

@Asset('$assetsPrefix/octicons/build/data.json')
const octicons = JsonAsset(_octicons$asset);

@Asset('$assetsPrefix/jquery/dist/jquery.slim.js',
    release: '$assetsPrefix/jquery/dist/jquery.slim.min.js')
const jquery = JsAsset(_jquery$asset);

@Asset('$assetsPrefix/material-design-icons/iconfont/material-icons.css')
const icons = CssAsset(_icons$asset, inline: CssAssetInline.all);

@Asset('$assetsPrefix/octicons/build/svg/git-*.svg')
const gitIcons = DirAsset<TextAsset, GitIcons>(_gitIcons$asset);