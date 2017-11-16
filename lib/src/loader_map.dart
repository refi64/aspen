import '../loader.dart';
import 'console.dart';
import 'default_loaders.dart';

class LoaderMap {
  var _map = <String, Loader>{};
  var _extensions = DefaultLoaders.getExtensions();

  LoaderMap.withDefaults() {
    _map.addAll(DefaultLoaders.getMap());
  }

  void addAliases(Map<String, String> aliases) {
    _map.addAll(DefaultLoaders.getMap());

    for (var alias in aliases.keys) {
      var aliasTarget = aliases[alias];
      if (!_map.containsKey(aliasTarget)) {
        error('Loader alias $alias uses undefined loader $aliasTarget');
      }
      _map[alias] = _map[aliasTarget];
    }
  }

  Loader operator[](String key) => _map[key];
  Loader forExtension(String ext) =>
      _extensions.containsKey(ext) ? _map[_extensions[ext]] : null;
  bool containsKey(String key) => _map.containsKey(key);
}
