import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:linthra/core/models/playback_state.dart';
import 'package:linthra/core/models/repeat_mode.dart';
import 'package:linthra/core/models/track.dart';
import 'package:linthra/core/services/smart_precache_service.dart';
import 'package:linthra/core/services/track_prefetcher.dart';
import 'package:linthra/data/repositories/in_memory_download_preferences.dart';

/// Records the ids it was asked to warm, in order. (The real prefetcher dedups
/// and bounds; here we only assert *what* the service decides to pre-cache.)
class _RecordingPrefetcher implements TrackPrefetcher {
  final List<String> prefetched = <String>[];

  @override
  Future<void> prefetch(Track track) async {
    prefetched.add(track.id);
  }
}

Track _t(String id) => Track(id: id, title: id, uri: 'jellyfin:$id');

PlaybackState _playing(
  Track current,
  List<Track> upNext, {
  bool shuffle = false,
  RepeatMode repeat = RepeatMode.off,
}) =>
    PlaybackState(
      status: PlaybackStatus.playing,
      currentTrack: current,
      upNext: upNext,
      shuffleEnabled: shuffle,
      repeatMode: repeat,
    );

/// Drains the microtask chain the listener + prefetch awaits run on.
Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  group('SmartPrecacheService', () {
    late StreamController<PlaybackState> states;
    late _RecordingPrefetcher prefetcher;
    late InMemoryDownloadPreferences preferences;

    setUp(() {
      states = StreamController<PlaybackState>.broadcast();
      prefetcher = _RecordingPrefetcher();
      preferences = InMemoryDownloadPreferences();
    });

    SmartPrecacheService build() => SmartPrecacheService(
          playbackStates: states.stream,
          prefetcher: prefetcher,
          preferences: preferences,
        );

    test('disabled smart pre-cache does nothing', () async {
      preferences = InMemoryDownloadPreferences(preloadEnabled: false);
      final service = build();

      states.add(_playing(_t('a'), <Track>[_t('b'), _t('c')]));
      await _settle();

      expect(prefetcher.prefetched, isEmpty);
      await service.dispose();
    });

    test('enabled pre-caches the next N tracks from the count preference',
        () async {
      preferences = InMemoryDownloadPreferences(precacheCount: 3);
      final service = build();

      states.add(
        _playing(_t('a'), <Track>[_t('b'), _t('c'), _t('d'), _t('e')]),
      );
      await _settle();

      // The first three upcoming tracks, in queue order — never the whole list.
      expect(prefetcher.prefetched, <String>['b', 'c', 'd']);
      await service.dispose();
    });

    test('honours a smaller upcoming-tracks count', () async {
      preferences = InMemoryDownloadPreferences(precacheCount: 1);
      final service = build();

      states.add(_playing(_t('a'), <Track>[_t('b'), _t('c'), _t('d')]));
      await _settle();

      expect(prefetcher.prefetched, <String>['b']);
      await service.dispose();
    });

    test('shuffle uses the shuffled upcoming order', () async {
      preferences = InMemoryDownloadPreferences(precacheCount: 3);
      final service = build();

      // upNext is already the effective (shuffled) play order, so pre-caching
      // its head pre-caches the shuffled-next songs, not the catalog order.
      states.add(
        _playing(
          _t('a'),
          <Track>[_t('d'), _t('b'), _t('c'), _t('e'), _t('f')],
          shuffle: true,
        ),
      );
      await _settle();

      expect(prefetcher.prefetched, <String>['d', 'b', 'c']);
      await service.dispose();
    });

    test('repeat-one does not pre-cache aggressively (caches nothing extra)',
        () async {
      preferences = InMemoryDownloadPreferences(precacheCount: 3);
      final service = build();

      states.add(
        _playing(
          _t('a'),
          <Track>[_t('b'), _t('c'), _t('d')],
          repeat: RepeatMode.one,
        ),
      );
      await _settle();

      expect(prefetcher.prefetched, isEmpty);
      await service.dispose();
    });

    test('repeat-all pre-caches the upcoming tracks normally', () async {
      preferences = InMemoryDownloadPreferences(precacheCount: 3);
      final service = build();

      states.add(
        _playing(
          _t('a'),
          <Track>[_t('b'), _t('c'), _t('d'), _t('e')],
          repeat: RepeatMode.all,
        ),
      );
      await _settle();

      expect(prefetcher.prefetched, <String>['b', 'c', 'd']);
      await service.dispose();
    });

    test('reacts to a track change, not to every state update', () async {
      preferences = InMemoryDownloadPreferences(precacheCount: 1);
      final service = build();

      states.add(_playing(_t('a'), <Track>[_t('b')]));
      await _settle();
      // A position-only update keeps the same playing track and queue.
      states.add(_playing(_t('a'), <Track>[_t('b')]));
      await _settle();

      expect(prefetcher.prefetched, <String>['b']);
      await service.dispose();
    });

    test('re-pre-caches against the new queue after advancing', () async {
      preferences = InMemoryDownloadPreferences(precacheCount: 1);
      final service = build();

      states.add(_playing(_t('a'), <Track>[_t('b'), _t('c')]));
      await _settle();
      states.add(_playing(_t('b'), <Track>[_t('c'), _t('d')]));
      await _settle();

      expect(prefetcher.prefetched, <String>['b', 'c']);
      await service.dispose();
    });

    test('re-pre-caches the new order when shuffle toggles on', () async {
      preferences = InMemoryDownloadPreferences(precacheCount: 1);
      final service = build();

      states.add(_playing(_t('a'), <Track>[_t('b'), _t('c'), _t('d')]));
      await _settle();
      // Same playing track, but shuffle reorders up-next: react to the change.
      states.add(
        _playing(_t('a'), <Track>[_t('d'), _t('c'), _t('b')], shuffle: true),
      );
      await _settle();

      expect(prefetcher.prefetched, <String>['b', 'd']);
      await service.dispose();
    });

    test('starts pre-caching once repeat-one is turned off', () async {
      preferences = InMemoryDownloadPreferences(precacheCount: 1);
      final service = build();

      states.add(
        _playing(_t('a'), <Track>[_t('b')], repeat: RepeatMode.one),
      );
      await _settle();
      expect(prefetcher.prefetched, isEmpty);

      // Same track and queue, but repeat-one cleared: now warm the next track.
      states.add(_playing(_t('a'), <Track>[_t('b')]));
      await _settle();

      expect(prefetcher.prefetched, <String>['b']);
      await service.dispose();
    });

    test('does nothing with an empty up-next list', () async {
      final service = build();

      states.add(_playing(_t('a'), const <Track>[]));
      await _settle();

      expect(prefetcher.prefetched, isEmpty);
      await service.dispose();
    });
  });
}
