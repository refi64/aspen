import '../loader.dart';
import 'console.dart';
import 'default_loaders.dart';

/// A set of loaders.
class LoaderMap {
  var _map = <String, Loader>{};
  var _extensions = DefaultLoaders.getExtensions();

  /// Creates a [LoaderMap] containing the default loaders.
  LoaderMap.withDefaults() {
    _map.addAll(DefaultLoaders.getMap());
  }

  /// Add the given set of aliases to the loader map.
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

  /// Retrieves the loader with the name [key], or null if not present.
  Loader operator[](String key) => _map[key];
  /// Retrieves the loader with the extension [ext], or null if not present.
  Loader forExtension(String ext) =>
      _extensions.containsKey(ext) ? _map[_extensions[ext]] : null;
  /// Does this contain a loader named [key]?
  bool contains(String key) => _map.containsKey(key);
}
