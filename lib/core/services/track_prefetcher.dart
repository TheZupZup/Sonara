import '../models/track.dart';

/// Caches an upcoming track ahead of play ("preload").
///
/// This is the seam the [PlaybackPreloader] drives so the player feature can ask
/// for the next queued tracks to be warmed into the offline cache without
/// knowing anything about the download policy, connectivity, or the filesystem —
/// the [CacheDownloadRepository] implements it alongside the user-download
/// lifecycle so both share one limit and one eviction policy.
///
/// A preload is *best-effort and never user-visible as a download*: it caches a
/// remote track's bytes (skipping local tracks, which are already on disk),
/// honours the user's "Wi-Fi only" and "preload" preferences, stays under the
/// cache limit (evicting other preloads first), and silently does nothing on any
/// failure — the track still streams normally when it's reached.
abstract interface class TrackPrefetcher {
  /// Warms [track] into the offline cache if it isn't already cached and the
  /// current connection/preferences allow it. Never throws.
  Future<void> prefetch(Track track);
}
