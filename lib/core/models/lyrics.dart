import 'package:flutter/foundation.dart';

/// One line of a track's lyrics, with an optional timestamp for synced lyrics.
@immutable
class LyricLine {
  const LyricLine({required this.text, this.start});

  /// The line's text. May be empty — a deliberate blank line between stanzas.
  final String text;

  /// When this line begins, for time-synced lyrics; `null` for plain lyrics.
  final Duration? start;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LyricLine && other.text == text && other.start == start);

  @override
  int get hashCode => Object.hash(text, start);
}

/// A track's lyrics: an ordered list of [lines]. Source-agnostic so the UI
/// renders the same whether the lines came from Jellyfin or, later, a local
/// `.lrc`/tag reader.
@immutable
class Lyrics {
  const Lyrics({required this.lines});

  final List<LyricLine> lines;

  bool get isEmpty => lines.isEmpty;
  bool get isNotEmpty => lines.isNotEmpty;

  /// Whether any line carries a timestamp (time-synced rather than plain text).
  bool get isSynced => lines.any((LyricLine line) => line.start != null);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Lyrics && listEquals(other.lines, lines));

  @override
  int get hashCode => Object.hashAll(lines);
}
