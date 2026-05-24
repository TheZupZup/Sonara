import '../../core/models/cache_size.dart';
import '../../core/repositories/download_preferences.dart';

/// A non-persistent [DownloadPreferences] for development and tests.
class InMemoryDownloadPreferences implements DownloadPreferences {
  InMemoryDownloadPreferences({
    bool wifiOnly = false,
    int maxCacheBytes = CacheSize.defaultLimit,
    bool preloadEnabled = true,
    int precacheCount = kDefaultPrecacheCount,
  })  : _wifiOnly = wifiOnly,
        _maxCacheBytes = maxCacheBytes,
        _preloadEnabled = preloadEnabled,
        _precacheCount = sanitizePrecacheCount(precacheCount);

  bool _wifiOnly;
  int _maxCacheBytes;
  bool _preloadEnabled;
  int _precacheCount;

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

  @override
  Future<int> precacheCount() async => _precacheCount;

  @override
  Future<void> setPrecacheCount(int value) async {
    _precacheCount = sanitizePrecacheCount(value);
  }
}
