import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zenify/providers/theme_provider.dart';

enum AlbumSortOption {
  defaultOrder,
  nameAsc,
  nameDesc,
  yearDesc,
  yearAsc,
  random,
}

enum ArtistSortOption {
  defaultOrder,
  nameAsc,
  nameDesc,
  albumCountDesc,
  random,
}

class AlbumSortNotifier extends Notifier<AlbumSortOption> {
  static const _key = 'album_sort_option';
  
  int _randomSeed = DateTime.now().millisecondsSinceEpoch;
  int get randomSeed => _randomSeed;

  @override
  AlbumSortOption build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final savedIndex = prefs.getInt(_key) ?? 0;
    if (savedIndex >= 0 && savedIndex < AlbumSortOption.values.length) {
      return AlbumSortOption.values[savedIndex];
    }
    return AlbumSortOption.defaultOrder;
  }

  void setSort(AlbumSortOption option) {
    if (option == AlbumSortOption.random) {
      _randomSeed = DateTime.now().millisecondsSinceEpoch;
    }
    state = option;
    ref.read(sharedPreferencesProvider).setInt(_key, option.index);
  }
}

class ArtistSortNotifier extends Notifier<ArtistSortOption> {
  static const _key = 'artist_sort_option';

  int _randomSeed = DateTime.now().millisecondsSinceEpoch;
  int get randomSeed => _randomSeed;

  @override
  ArtistSortOption build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final savedIndex = prefs.getInt(_key) ?? 0;
    if (savedIndex >= 0 && savedIndex < ArtistSortOption.values.length) {
      return ArtistSortOption.values[savedIndex];
    }
    return ArtistSortOption.defaultOrder;
  }

  void setSort(ArtistSortOption option) {
    if (option == ArtistSortOption.random) {
      _randomSeed = DateTime.now().millisecondsSinceEpoch;
    }
    state = option;
    ref.read(sharedPreferencesProvider).setInt(_key, option.index);
  }
}

final albumSortProvider = NotifierProvider<AlbumSortNotifier, AlbumSortOption>(() => AlbumSortNotifier());
final artistSortProvider = NotifierProvider<ArtistSortNotifier, ArtistSortOption>(() => ArtistSortNotifier());

enum SongSortOption {
  defaultOrder,
  nameAsc,
  nameDesc,
  random,
}

class SongSortNotifier extends Notifier<SongSortOption> {
  static const _key = 'song_sort_option';

  int _randomSeed = DateTime.now().millisecondsSinceEpoch;
  int get randomSeed => _randomSeed;

  @override
  SongSortOption build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final savedIndex = prefs.getInt(_key) ?? 0;
    if (savedIndex >= 0 && savedIndex < SongSortOption.values.length) {
      return SongSortOption.values[savedIndex];
    }
    return SongSortOption.defaultOrder;
  }

  void setSort(SongSortOption option) {
    if (option == SongSortOption.random) {
      _randomSeed = DateTime.now().millisecondsSinceEpoch;
    }
    state = option;
    ref.read(sharedPreferencesProvider).setInt(_key, option.index);
  }
}

final songSortProvider = NotifierProvider<SongSortNotifier, SongSortOption>(() => SongSortNotifier());
