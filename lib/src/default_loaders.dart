import '../loader.dart';

import 'default_loaders/css_loader.dart';

/// Loads a generic binary file.
class BasicBinaryLoader extends BinaryLoader {
  final name = 'binary';
}

/// Loads a generic text file.
class BasicTextLoader extends StringLoader {
  final name = 'text';
}

/// Loads a file containing a valid JavaScript expression.
class BasicObjectLoader extends ObjectLoader {
  final name = 'object';
}

/// Loads a JSON file.
class JsonLoader extends ObjectLoader {
  final name = 'json';
  final extensions = ['.json'];
}

/// Loads a JavaScript script that will be immediately executed.
class JsLoader extends ScriptLoader {
  final name = 'js';
  final extensions = ['.js'];
}

final _defaultLoaderList = <Loader>[
  new BasicBinaryLoader(),
  new BasicTextLoader(),
  new BasicObjectLoader(),
  new CssLoader(),
  new JsonLoader(),
  new JsLoader(),
];

/// Stores the default loaders and allows for access.
class DefaultLoaders  {
  static Map<String, Loader> getMap() {
    var loaderMap = <String, Loader>{};
    for (var loader in _defaultLoaderList) {
      loaderMap[loader.name] = loader;
    }
    return loaderMap;
  }

  static Map<String, String> getExtensions() {
    var extensionsToLoaders = <String, String>{};
    for (var loader in _defaultLoaderList) {
      for (var extension in loader.extensions ?? []) {
        extensionsToLoaders[extension] = loader.name;
      }
    }

    return extensionsToLoaders;
  }
}
