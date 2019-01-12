class LoadableAsset {
  final String url, loader;

  const LoadableAsset({this.url, this.loader});
}

class Asset {
  final String path, releasePath;

  const Asset(this.path, {String release}): releasePath = release;
}
