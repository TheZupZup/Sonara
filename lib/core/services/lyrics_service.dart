import '../models/lyrics.dart';
import '../models/track.dart';

/// Fetches a track's lyrics, hiding the source from the UI.
///
/// The shipped implementation reads lyrics from a signed-in Jellyfin server for
/// remote tracks; a local track (or being signed out) yields `null`, and the UI
/// shows an honest "no lyrics" state. A future local `.lrc`/tag reader slots in
/// behind this same seam without the player changing.
abstract interface class LyricsService {
  /// The lyrics for [track], or `null` when none are available. May throw a
  /// [JellyfinException] for a fetch failure (offline, expired session) so the
  /// UI can tell "couldn't load" apart from "no lyrics".
  Future<Lyrics?> lyricsFor(Track track);
}
