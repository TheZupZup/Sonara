import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/lyrics.dart';
import '../../core/models/track.dart';
import '../../core/services/jellyfin_lyrics_service.dart';
import '../../core/services/lyrics_service.dart';
import '../settings/jellyfin/jellyfin_settings_controller.dart';
import '../settings/jellyfin/jellyfin_settings_providers.dart';

/// The lyrics backend. Defaults to "no lyrics" so tests and local-only use need
/// no Jellyfin wiring; the app overrides it with the Jellyfin-backed service.
final lyricsServiceProvider = Provider<LyricsService>((ref) {
  return const _NoLyricsService();
});

/// Lyrics for a single track, fetched on demand and cached while the sheet is
/// open. Auto-disposed so closing the sheet drops the request.
final trackLyricsProvider =
    FutureProvider.autoDispose.family<Lyrics?, Track>((ref, track) {
  return ref.watch(lyricsServiceProvider).lyricsFor(track);
});

/// Production binding: read lyrics from the signed-in Jellyfin server. Reads the
/// live client + session lazily so signing in/out is picked up without a
/// rebuild. Applied in `main`; tests keep the no-lyrics default.
final jellyfinLyricsOverride = lyricsServiceProvider.overrideWith((ref) {
  return JellyfinLyricsService(
    client: ref.read(jellyfinClientProvider),
    session: () =>
        ref.read(jellyfinSettingsControllerProvider.notifier).session,
  );
});

/// The honest local-only default: no lyrics source wired, so every track
/// resolves to "none" and the UI shows a calm placeholder.
class _NoLyricsService implements LyricsService {
  const _NoLyricsService();

  @override
  Future<Lyrics?> lyricsFor(Track track) async => null;
}
