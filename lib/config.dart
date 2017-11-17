import 'package:yaml/yaml.dart';

import 'dart:io';

import 'src/console.dart';

/// A build mode: dev for development/debug builds, and prod for production.
enum BuildMode { dev, prod }

/// Converts [str] (either 'dev' or 'prod') to a [BuildMode].
BuildMode buildModeFromString(String str) {
  var modeString = 'BuildMode.$str';
  return BuildMode.values.firstWhere((m) => m.toString() == modeString);
}

/// An asset the user has declared in their config file.
class Asset {
  /// The asset name. May be null.
  String name;
  /// A mapping of a [BuildMode] to the input file that should be used.
  Map<BuildMode, String> modesToInputs;
  /// The loader this asset needs. This may be null until [setupTargets] fills in the
  /// loader for the proper file extension.
  String loader;
  Asset({this.name, this.modesToInputs, this.loader});

  /// Read in an asset from [m] from inside [target] (only used for error messages).
  factory Asset.parse(String target, dynamic m) {
    if (m is String) {
      return new Asset(modesToInputs: {BuildMode.dev: m, BuildMode.prod: m},
                       loader: null);
    } else if (m is! Map) {
      error('Target $target asset value should be a string or map');
    }

    String name, loader;
    var modesToInputs = <BuildMode, String>{};

    for (var key in m.keys) {
      check(key is String, 'Target $target asset keys should be strings');
      var value = m[key];
      check(value is String, 'Target $target asset $key value should be a string');

      switch (key) {
      case 'name':
        if (name != null) {
          error('Target $target asset $name has more than one name declaration');
        }
        name = value;
        break;
      case 'default':
      case 'dev':
      case 'prod':
        if (key == 'default') {
          if (modesToInputs.isNotEmpty) {
            error('Target $target asset cannot define default and dev/prod');
          }
        } else if (modesToInputs.containsKey(key)) {
          error('Target $target asset contains duplicate build mode define $key');
        }

        if (key == 'dev' || key == 'default') {
          modesToInputs[BuildMode.dev] = value;
        }
        if (key == 'prod' || key == 'default') {
          modesToInputs[BuildMode.prod] = value;
        }
        break;
      case 'loader':
        if (loader != null) {
          error('Target $target asset defines multiple loaders');
        }
        loader = value;
        break;
      default:
        error('Target $target asset contains unknown key $key');
        break;
      }
    }

    return new Asset(name: name, modesToInputs: modesToInputs, loader: loader);
  }
}

/// A target the user has declared in the config file.
class Target {
  /// The name of the target.
  String name;
  /// The target this one is derived from (may be null).
  String from;
  /// A mapping of loader names to the output file that should be used.
  Map<String, String> loadersToOutputs;
  /// A list of assets within this target.
  List<Asset> assets;
  Target({this.name, this.from, this.loadersToOutputs, this.assets});

  /// Read in a target named [name] from the map [m].
  factory Target.parse(String name, Map m) {
    var loadersToOutputs = <String, String>{};
    var assets = <Asset>[];
    String from;

    for (var key in m.keys) {
      var value = m[key];
      check(key is String, 'Target keys should be strings');

      switch (key) {
        case 'outputs':
          check(value is Map, 'Target $name outputs value should be a map');
          for (var outLoader in value.keys) {
            check(outLoader is String, 'Target $name output key should be a string');
            var outValue = value[outLoader];
            check(outValue is String, 'Target $name output $outLoader should be a '
                                      'string');

            loadersToOutputs[outLoader] = outValue;
          }
          break;
        case 'assets':
          check(value is List, 'Target $name assets should be a list');
          assets.addAll(value.map((a) => new Asset.parse(name, a)));
          break;
        case 'from':
          check(value is String, 'Target $name from value should be a string');
          from = value;
          break;
        default:
          error('Unknown key $key in target $name');
          break;
      }
    }

    return new Target(name: name, from: from, loadersToOutputs: loadersToOutputs,
                      assets: assets);
  }
}

/// The user's config file.
class Config {
  /// A mapping of strong loader aliases to the loader they alias.
  Map<String, String> loaderAliases;
  /// A mapping of target names to their targets.
  Map<String, Target> targets;
  Config({this.loaderAliases, this.targets});

  /// Read in a config file from the map [m].
  factory Config.parse(Map m) {
    var loaderAliases = <String, String>{};
    var targets = <String, Target>{};

    for (var key in m.keys) {
      var value = m[key];
      check(key is String, 'Config keys should be strings');

      switch (key) {
      case 'loader-aliases':
        check(value is Map, 'Loader-aliases value should be a map');
        for (var loaderName in value.keys) {
          check(loaderName is String, 'Loader name should be a string');
          var loaderValue = value[loaderName];
          check(loaderValue is String,
                'Loader $loaderName value should be a string');

          loaderAliases[loaderName] = loaderValue;
        }
        break;
      case 'targets':
        check(value is Map, 'Targets value should be a map');
        for (var targetName in value.keys) {
          check(targetName is String, 'Target name should be a string');
          var targetValue = value[targetName];
          check(targetValue is Map, 'Target $targetName value should be a list');
          targets[targetName] = new Target.parse(targetName, targetValue);
        }
        break;
      case 'default':
        error('Unknown key $key');
        break;
      }
    }

    return new Config(loaderAliases: loaderAliases, targets: targets);
  }
}

/// Parses and returns the YAML config file at [path].
Config parseConfig(String path) {
  var file = new File(path);
  if (!file.existsSync()) {
    error('Config file $path does not exist!');
  }

  var contents = file.readAsStringSync();
  return new Config.parse(loadYaml(contents));
}
