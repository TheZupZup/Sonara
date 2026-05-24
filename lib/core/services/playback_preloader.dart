import 'dart:async';

import '../models/playback_state.dart';
import '../models/track.dart';
import '../repositories/download_preferences.dart';
import 'track_prefetcher.dart';

/// Warms the next few queued tracks into the offline cache as playback moves,
/// so the upcoming songs play instantly (and offline) instead of buffering a
/// fresh stream at each track change.
///
/// It listens to the [PlaybackState] stream and, each time the *playing track*
/// changes, asks a [TrackPrefetcher] to cache the next [aheadCount] entries of
/// the up-next list. Because the controller keeps `upNext` in effective play
/// order, this preloads the queue order in normal playback and the shuffled
/// order when shuffle is on — no special-casing needed.
///
/// Everything that bounds it lives downstream: the prefetcher skips local and
/// already-cached tracks, honours "Wi-Fi only", stays under the cache limit
/// (evicting preloads first), and never throws. This class only decides *what*
/// to preload and *when*, and does so off the playback path — a preload never
/// blocks or interrupts what's playing.
class PlaybackPreloader {
  PlaybackPreloader({
    required Stream<PlaybackState> playbackStates,
    required TrackPrefetcher prefetcher,
    required DownloadPreferences preferences,
    int aheadCount = defaultAheadCount,
  })  : _prefetcher = prefetcher,
        _preferences = preferences,
        _aheadCount = aheadCount {
    _subscription = playbackStates.listen(_onState);
  }

  /// How many upcoming tracks to keep warmed ahead of the current one. Small on
  /// purpose: enough for seamless next/auto-advance without hoarding the cache.
  static const int defaultAheadCount = 3;

  final TrackPrefetcher _prefetcher;
  final DownloadPreferences _preferences;
  final int _aheadCount;
  late final StreamSubscription<PlaybackState> _subscription;

  String? _lastTrackId;
  List<Track>? _pendingUpNext;
  bool _running = false;

  void _onState(PlaybackState state) {
    final String? id = state.currentTrack?.id;
    // Only react when the playing track changes, not on every position tick.
    if (id == _lastTrackId) return;
    _lastTrackId = id;
    if (id == null) return;
    // Remember the latest up-next and drain; a pass already running will pick
    // this up when it finishes, so the freshest queue always wins.
    _pendingUpNext = state.upNext;
    unawaited(_drain());
  }

  Future<void> _drain() async {
    if (_running) return;
    _running = true;
    try {
      while (_pendingUpNext != null) {
        final List<Track> upNext = _pendingUpNext!;
        _pendingUpNext = null;
        await _preloadUpcoming(upNext);
      }
    } finally {
      _running = false;
    }
  }

  Future<void> _preloadUpcoming(List<Track> upNext) async {
    if (upNext.isEmpty) return;
    if (!await _preferences.preloadEnabled()) return;
    final int count = upNext.length < _aheadCount ? upNext.length : _aheadCount;
    for (int i = 0; i < count; i++) {
      // Sequential on purpose: one warm fetch at a time keeps preload off the
      // critical path and lets the cache limit settle between writes.
      await _prefetcher.prefetch(upNext[i]);
    }
  }

  Future<void> dispose() => _subscription.cancel();
}
