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
    state = option;
    ref.read(sharedPreferencesProvider).setInt(_key, option.index);
  }
}

class ArtistSortNotifier extends Notifier<ArtistSortOption> {
  static const _key = 'artist_sort_option';

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
    state = option;
    ref.read(sharedPreferencesProvider).setInt(_key, option.index);
  }
}

final albumSortProvider = NotifierProvider<AlbumSortNotifier, AlbumSortOption>(() => AlbumSortNotifier());
final artistSortProvider = NotifierProvider<ArtistSortNotifier, ArtistSortOption>(() => ArtistSortNotifier());
