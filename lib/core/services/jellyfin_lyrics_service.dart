import '../models/jellyfin_session.dart';
import '../models/lyrics.dart';
import '../models/track.dart';
import '../sources/jellyfin/jellyfin_client.dart';
import '../sources/jellyfin/jellyfin_track_mapper.dart';
import 'lyrics_service.dart';

/// A [LyricsService] backed by a signed-in Jellyfin server.
///
/// Only Jellyfin tracks (the `jellyfin:<id>` scheme) are looked up; a local
/// track or being signed out returns `null` so the UI shows "no lyrics". The
/// session (with its token) is read lazily through [_session] so signing in/out
/// is picked up without a rebuild, mirroring the streaming/download path.
class JellyfinLyricsService implements LyricsService {
  JellyfinLyricsService({
    required JellyfinClient client,
    required JellyfinSession? Function() session,
  })  : _client = client,
        _session = session;

  final JellyfinClient _client;
  final JellyfinSession? Function() _session;

  @override
  Future<Lyrics?> lyricsFor(Track track) async {
    if (!track.uri.startsWith(JellyfinTrackMapper.uriScheme)) return null;
    final JellyfinSession? session = _session();
    if (session == null) return null;
    final String itemId =
        track.uri.substring(JellyfinTrackMapper.uriScheme.length);
    return _client.fetchLyrics(session, itemId);
  }
}
