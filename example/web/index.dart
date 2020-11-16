// import 'package:aspen_assets/aspen_assets.dart' as aspen;
// import 'dart:html';

import 'package:aspen_assets/aspen_assets.dart';
import 'package:aspen_playground/assets.dart';
import 'package:aspen_web/aspen_web.dart';

void main() {
  JsAsset(AssetData('testasset', 'console.log("loading...")'))
      .evalAsync()
      .then((_) => print('evalAsync done'));
  print('after evalAsync');

  jqueryReadme.text.substring(0);
  jquery.eval();
  icons.apply();

  // print(ascii.decode(bowerBinary.decode().toList()));
  octicons.json();
  // print(octicons.json());
}
