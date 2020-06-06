import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/bundle_generator.dart';

Builder bundleBuilder(BuilderOptions options) =>
    LibraryBuilder(BundleGenerator(options));
