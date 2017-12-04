import 'package:aspen_assets/aspen_assets.dart' as aspen;
import 'dart:html';

void main() {
  // aspen.loadGlobal('mdl');
  // print('l1');
  aspen.loadGlobal('mdl');
  // aspen.loadGlobal('md-icons');
  var svg = aspen.loadString('svg');
  var validator = new NodeValidatorBuilder()..allowSvg();
  document.querySelector('#svg').appendHtml(svg, validator: validator);
  print(aspen.loadBinary('font-awesome'));
  // print(aspen.loadObject('json'));
}
