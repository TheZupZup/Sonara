import '../../core/models/cache_size.dart';
import '../../core/repositories/download_preferences.dart';

/// A non-persistent [DownloadPreferences] for development and tests.
class InMemoryDownloadPreferences implements DownloadPreferences {
  InMemoryDownloadPreferences({
    bool wifiOnly = false,
    int maxCacheBytes = CacheSize.defaultLimit,
    bool preloadEnabled = true,
  })  : _wifiOnly = wifiOnly,
        _maxCacheBytes = maxCacheBytes,
        _preloadEnabled = preloadEnabled;

  bool _wifiOnly;
  int _maxCacheBytes;
  bool _preloadEnabled;

  @override
  Future<bool> wifiOnly() async => _wifiOnly;

  @override
  Future<void> setWifiOnly(bool value) async {
    _wifiOnly = value;
  }

  @override
  Future<int> maxCacheBytes() async => _maxCacheBytes;

  @override
  Future<void> setMaxCacheBytes(int bytes) async {
    _maxCacheBytes = bytes;
  }

  @override
  Future<bool> preloadEnabled() async => _preloadEnabled;

  @override
  Future<void> setPreloadEnabled(bool value) async {
    _preloadEnabled = value;
  }
}
