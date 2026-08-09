import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenify/providers/server_providers.dart';
import 'package:zenify/providers/sort_providers.dart';
import 'package:zenify/providers/network_provider.dart';
import 'package:zenify/models/album_detail_cache.dart';
import 'package:zenify/models/album.dart';

class AlbumsPaginationState {
  final List<Album> albums;
  final bool isLoadingMore;
  final bool hasMore;
  final int totalCount;

  AlbumsPaginationState({
    required this.albums,
    this.isLoadingMore = false,
    this.hasMore = true,
    required this.totalCount,
  });

  AlbumsPaginationState copyWith({
    List<Album>? albums,
    bool? isLoadingMore,
    bool? hasMore,
    int? totalCount,
  }) {
    return AlbumsPaginationState(
      albums: albums ?? this.albums,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}

class AlbumsPaginationNotifier extends AsyncNotifier<AlbumsPaginationState> {
  static const int _limit = 50;
  int _offset = 0;

  @override
  Future<AlbumsPaginationState> build() async {
    _offset = 0;
    
    final server = await ref.watch(activeServerProvider.future);
    if (server == null) {
      return AlbumsPaginationState(albums: [], hasMore: false, totalCount: 0);
    }
    
    final db = ref.watch(databaseProvider);
    final totalCount = await db.getAlbumCount(server.id);
    
    final albums = await _fetchPage(0);
    return AlbumsPaginationState(
      albums: albums,
      hasMore: albums.length == _limit,
      totalCount: totalCount,
    );
  }

  Future<List<Album>> _fetchPage(int offset) async {
    final server = await ref.watch(activeServerProvider.future);
    if (server == null) return [];
    
    final db = ref.watch(databaseProvider);
    final sortOption = ref.watch(albumSortProvider);
    final networkState = ref.watch(networkProvider);
    final isOfflineMode = networkState.isOffline;
    
    final albums = await db.getAlbumsPaginated(
      server.id,
      offset: offset,
      limit: _limit,
      sort: sortOption,
      offlineFirst: isOfflineMode,
    );
    
    if (sortOption == AlbumSortOption.random) {
       albums.shuffle();
    }
    return albums;
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.hasError) return;
    final currentState = state.value;
    if (currentState == null || currentState.isLoadingMore || !currentState.hasMore) return;
    
    state = AsyncValue.data(currentState.copyWith(isLoadingMore: true));
    
    try {
      final newAlbums = await _fetchPage(_offset + _limit);
      _offset += _limit;
      state = AsyncValue.data(currentState.copyWith(
        albums: [...currentState.albums, ...newAlbums],
        hasMore: newAlbums.length == _limit,
        isLoadingMore: false,
      ));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final albumsProvider = AsyncNotifierProvider<AlbumsPaginationNotifier, AlbumsPaginationState>(() {
  return AlbumsPaginationNotifier();
});

final albumDetailProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, id) async {
  final networkState = ref.watch(networkProvider);
  final db = ref.read(databaseProvider);
  final server = await ref.watch(activeServerProvider.future);
  
  if (server == null) return null;

  if (networkState.isOffline) {
    final cache = await db.getAlbumDetail(server.id, id);
    if (cache != null) {
      try {
        return jsonDecode(cache.rawData);
      } catch (_) {}
    }
    return null;
  }

  final api = ref.watch(subsonicApiProvider);
  if (api == null) return null;
  final result = await api.getAlbum(id);
  
  // Save to cache when online
  if (result != null) {
    final cache = AlbumDetailCache()
      ..serverId = server.id
      ..albumId = id
      ..rawData = jsonEncode(result);
    db.saveAlbumDetail(cache);
  }
  return result;
});
