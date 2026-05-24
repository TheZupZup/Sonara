import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/repositories/favorites_store.dart';

/// A [FavoritesStore] backed by `shared_preferences`.
///
/// Favourites are a small set of non-secret track ids, so a key/value document
/// is the right weight (the same reasoning the offline-download set follows).
/// Stored as `{ "local": [...], "remote": [...] }` so the device-local
/// favourites and the server-mirrored ones survive a restart and can be
/// reconciled independently.
class SharedPreferencesFavoritesStore implements FavoritesStore {
  const SharedPreferencesFavoritesStore();

  static const String _key = 'favorites_v1';

  @override
  Future<FavoritesData> load() async {
    final prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return FavoritesData.empty;
    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      // A corrupt record reads as "no favourites" rather than crashing.
      return FavoritesData.empty;
    }
    if (decoded is! Map<String, dynamic>) return FavoritesData.empty;
    return FavoritesData(
      localIds: _ids(decoded['local']),
      remoteIds: _ids(decoded['remote']),
    );
  }

  @override
  Future<void> save(FavoritesData data) async {
    final prefs = await SharedPreferences.getInstance();
    final String raw = jsonEncode(<String, dynamic>{
      'local': data.localIds.toList(),
      'remote': data.remoteIds.toList(),
    });
    await prefs.setString(_key, raw);
  }

  static Set<String> _ids(Object? value) {
    if (value is! List) return <String>{};
    return <String>{
      for (final Object? id in value)
        if (id is String && id.isNotEmpty) id,
    };
  }
}
