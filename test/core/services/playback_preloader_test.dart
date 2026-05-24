import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:linthra/core/models/playback_state.dart';
import 'package:linthra/core/models/track.dart';
import 'package:linthra/core/services/playback_preloader.dart';
import 'package:linthra/core/services/track_prefetcher.dart';
import 'package:linthra/data/repositories/in_memory_download_preferences.dart';

/// Records the ids it was asked to warm, in order.
class _RecordingPrefetcher implements TrackPrefetcher {
  final List<String> prefetched = <String>[];

  @override
  Future<void> prefetch(Track track) async {
    prefetched.add(track.id);
  }
}

Track _t(String id) => Track(id: id, title: id, uri: 'jellyfin:$id');

PlaybackState _playing(Track current, List<Track> upNext) => PlaybackState(
      status: PlaybackStatus.playing,
      currentTrack: current,
      upNext: upNext,
    );

/// Drains the microtask chain the listener + prefetch awaits run on.
Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  group('PlaybackPreloader', () {
    late StreamController<PlaybackState> states;
    late _RecordingPrefetcher prefetcher;
    late InMemoryDownloadPreferences preferences;

    setUp(() {
      states = StreamController<PlaybackState>.broadcast();
      prefetcher = _RecordingPrefetcher();
      preferences = InMemoryDownloadPreferences();
    });

    PlaybackPreloader build({int aheadCount = 3}) => PlaybackPreloader(
          playbackStates: states.stream,
          prefetcher: prefetcher,
          preferences: preferences,
          aheadCount: aheadCount,
        );

    test('warms the next few upcoming tracks when the track changes', () async {
      final preloader = build(aheadCount: 2);

      states.add(_playing(_t('a'), <Track>[_t('b'), _t('c'), _t('d')]));
      await _settle();

      // Only the first two upcoming tracks, in queue order.
      expect(prefetcher.prefetched, <String>['b', 'c']);
      await preloader.dispose();
    });

    test('does nothing while the preload preference is off', () async {
      preferences = InMemoryDownloadPreferences(preloadEnabled: false);
      final preloader = build();

      states.add(_playing(_t('a'), <Track>[_t('b'), _t('c')]));
      await _settle();

      expect(prefetcher.prefetched, isEmpty);
      await preloader.dispose();
    });

    test('reacts to a track change, not to every state update', () async {
      final preloader = build(aheadCount: 1);

      states.add(_playing(_t('a'), <Track>[_t('b')]));
      await _settle();
      // A position-only update keeps the same playing track.
      states.add(_playing(_t('a'), <Track>[_t('b')]));
      await _settle();

      expect(prefetcher.prefetched, <String>['b']);
      await preloader.dispose();
    });

    test('re-preloads against the new queue after advancing', () async {
      final preloader = build(aheadCount: 1);

      states.add(_playing(_t('a'), <Track>[_t('b'), _t('c')]));
      await _settle();
      states.add(_playing(_t('b'), <Track>[_t('c'), _t('d')]));
      await _settle();

      expect(prefetcher.prefetched, <String>['b', 'c']);
      await preloader.dispose();
    });

    test('does nothing with an empty up-next list', () async {
      final preloader = build();

      states.add(_playing(_t('a'), const <Track>[]));
      await _settle();

      expect(prefetcher.prefetched, isEmpty);
      await preloader.dispose();
    });
  });
}
