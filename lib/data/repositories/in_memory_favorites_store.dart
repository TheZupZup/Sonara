import '../../core/repositories/favorites_store.dart';

/// A non-persistent [FavoritesStore] for development and tests.
class InMemoryFavoritesStore implements FavoritesStore {
  InMemoryFavoritesStore([FavoritesData initial = FavoritesData.empty])
      : _data = initial;

  FavoritesData _data;

  @override
  Future<FavoritesData> load() async => _data;

  @override
  Future<void> save(FavoritesData data) async {
    _data = data;
  }
}
