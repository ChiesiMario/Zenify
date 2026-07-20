import 'package:flutter_riverpod/flutter_riverpod.dart';

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

final albumSortProvider = StateProvider<AlbumSortOption>((ref) => AlbumSortOption.defaultOrder);
final artistSortProvider = StateProvider<ArtistSortOption>((ref) => ArtistSortOption.defaultOrder);
