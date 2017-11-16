import '../loader.dart';

class BasicBinaryLoader extends BinaryLoader {
  final name = 'binary';
}

class BasicTextLoader extends StringLoader {
  final name = 'text';
}

class BasicObjectLoader extends ObjectLoader {
  final name = 'object';
}

class CssLoader extends StringLoader {
  final name = 'css';
  final extensions = ['.css'];

  final globalLoadJs = '''
  function (data) { document.head.append(data); }
  ''';
}

class JsonLoader extends ObjectLoader {
  final name = 'json';
  final extensions = ['.json'];
}

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
