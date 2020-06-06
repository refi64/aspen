import 'dart:async';

import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

abstract class LoaderContext {
  BuildStep get buildStep;

  void error(String message, {bool ownLine = false});
}

abstract class Loader {
  Future<String> load(LoaderContext ctx, AssetId asset, ConstantReader options);
}
