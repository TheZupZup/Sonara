import 'package:flutter_test/flutter_test.dart';
import 'package:linthra/core/models/jellyfin_session.dart';
import 'package:linthra/core/models/lyrics.dart';
import 'package:linthra/core/models/track.dart';
import 'package:linthra/core/services/jellyfin_lyrics_service.dart';

import '../sources/jellyfin/fake_jellyfin_client.dart';

const _session = JellyfinSession(
  baseUrl: 'https://music.example.com',
  userId: 'user-1',
  accessToken: 'tok',
  deviceId: 'device-1',
);

void main() {
  group('JellyfinLyricsService', () {
    late FakeJellyfinClient client;

    setUp(() => client = FakeJellyfinClient());

    JellyfinLyricsService build({JellyfinSession? session}) =>
        JellyfinLyricsService(client: client, session: () => session);

    test('fetches lyrics for a Jellyfin track by its item id', () async {
      client.lyrics = const Lyrics(
        lines: <LyricLine>[LyricLine(text: 'la la')],
      );
      final service = build(session: _session);

      final lyrics = await service.lyricsFor(
        const Track(id: 'item-7', title: 'Song', uri: 'jellyfin:item-7'),
      );

      expect(client.lastLyricsItemId, 'item-7');
      expect(lyrics?.lines.single.text, 'la la');
    });

    test('returns null for a local track without hitting the server', () async {
      final service = build(session: _session);

      final lyrics = await service.lyricsFor(
        const Track(id: '1', title: 'Local', uri: 'file:///1.mp3'),
      );

      expect(lyrics, isNull);
      expect(client.lastLyricsItemId, isNull);
    });

    test('returns null when signed out', () async {
      final service = build(session: null);

      final lyrics = await service.lyricsFor(
        const Track(id: 'item-7', title: 'Song', uri: 'jellyfin:item-7'),
      );

      expect(lyrics, isNull);
      expect(client.lastLyricsItemId, isNull);
    });
  });
}
