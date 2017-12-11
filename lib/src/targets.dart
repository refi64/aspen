import 'package:path/path.dart' as p;

import 'console.dart';
import 'loader_map.dart';
import '../config.dart';
import '../loader.dart';

/// For each target, verifies any given loaders and infers any others from the target's
/// input extensions.
void _assignTargetLoaders(Map<String, Target> targets, LoaderMap loaderMap) {
  for (var target in targets.values) {
    for (var asset in target.assets) {
      if (asset.loader != null) {
        if (!loaderMap.contains(asset.loader)) {
          error('Asset in target ${target.name} uses undefined loader ${asset.loader}');
        }
      } else {
        for (var mode in asset.modesToInputs.keys) {
          var path = asset.modesToInputs[mode];
          var ext = p.extension(path);
          if (ext.isEmpty) {
            error('Asset path $path in target ${target.name} has no extension; '
                  'try manually specifying a loader to use');
          }

          var thisModeLoader = loaderMap.forExtension(ext);
          if (thisModeLoader == null) {
            error('Asset path $path in target ${target.name} has an extension $ext '
                  'that is not associated with any known loader; try manually '
                  'specifying a loader to use');
          }

          if (asset.loader == null) {
            asset.loader = thisModeLoader.name;
          } else if (asset.loader != thisModeLoader.name) {
            error('Asset in target ${target.name} uses at least two different loaders: '
                  '${asset.loader} and ${thisModeLoader.name}');
          } else if (thisModeLoader is ScriptLoader && asset.name != null) {
            error('Asset ${asset.name} in target ${target.name} has a loader that '
                  'cannot be loaded by name, but it declares a name anyway');
          } else if (thisModeLoader is! ScriptLoader && asset.name == null &&
                     !(thisModeLoader is GlobalLoader && asset.autoload)) {
            error('Asset in target ${target.name} has a loader that can only be used '
                  'by name, but the asset has no name');
          }
        }
      }

      if (asset.autoload) {
        var thisModeLoader = loaderMap[asset.loader];
        if (thisModeLoader is! GlobalLoader ||
            (thisModeLoader as GlobalLoader).globalLoadJs == null) {
          error('Asset in target ${target.name} specifies autoload, but the loader '
                '${asset.loader} does not support global loading.');
        }
      }
    }
  }
}

/// For each derived target, adds the parent's outputs and assets to the child target.
void _setupDerivedTargets(Map<String, Target> targets) {
  for (var target in targets.values) {
    if (target.from == null) continue;
    else if (!targets.containsKey(target.from)) {
      error('Target ${target.name} derives from undefined target ${target.from}');
    }
    var origin = targets[target.from];

    for (var loader in origin.loadersToOutputs.keys) {
      if (!target.loadersToOutputs.containsKey(loader)) {
        target.loadersToOutputs[loader] = origin.loadersToOutputs[loader];
      }
    }

    target.assets.addAll(origin.assets);
  }
}

void setupTargets(Map<String, Target> targets, LoaderMap loaderMap) {
  _assignTargetLoaders(targets, loaderMap);
  _setupDerivedTargets(targets);
}
