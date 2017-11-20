import 'package:args/args.dart';

import 'package:aspen/src/targets.dart';
import 'package:aspen/src/loader_map.dart';
import 'package:aspen/src/console.dart';
import 'package:aspen/src/generate.dart';
import 'package:aspen/config.dart';

import 'dart:async';
import 'dart:io';

Future main(List<String> args) async {
  var parser = new ArgParser();
  parser.addOption('config', abbr: 'c', help: 'Path to the Aspen config file',
                   defaultsTo: 'aspen.yml');
  parser.addOption('mode', abbr: 'm', help: 'The build mode', defaultsTo: 'dev',
                   allowed: ['dev', 'prod']);
  parser.addFlag('help', abbr: 'h', help: 'Show this screen');

  ArgResults results;
  try {
    results = parser.parse(args);
  } on ArgParserException catch (ex) {
    error("Error parsing arguments: ${ex.message}");
  }

  if (results['help']) {
    print('usage: aspen <targets to run> [-c <config>] [-m <mode>] [-h]');
    print('Aspen is an asset packer for Dart.');

    print('If no targets to run are passed, "default" will be used.');
    print('\nArguments:\n');
    print(parser.usage);
    exit(0);
  }

  var config = parseConfig(results['config']);
  var mode = buildModeFromString(results['mode']);

  String targetName;
  if (results.rest.length == 0) {
    targetName = 'default';
  } else if (results.rest.length == 1) {
    targetName = results.rest[0];
  } else {
    error('Only one target can be passed to Aspen');
  }

  if (!config.targets.containsKey(targetName)) {
    error('Invalid target $targetName');
  }

  var loaderMap = new LoaderMap.withDefaults();
  loaderMap.addAliases(config.loaderAliases);

  setupTargets(config.targets, loaderMap);

  var target = config.targets[targetName];
  await generateTarget(target, mode, loaderMap);

  return new Future.value();
}
