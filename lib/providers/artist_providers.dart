import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenify/providers/server_providers.dart';
import 'package:zenify/providers/sort_providers.dart';
import 'package:zenify/providers/network_provider.dart';
import 'package:zenify/models/artist.dart';

class ArtistsPaginationState {
  final List<Artist> artists;
  final bool isLoadingMore;
  final bool hasMore;
  final int totalCount;

  ArtistsPaginationState({
    required this.artists,
    this.isLoadingMore = false,
    this.hasMore = true,
    required this.totalCount,
  });

  ArtistsPaginationState copyWith({
    List<Artist>? artists,
    bool? isLoadingMore,
    bool? hasMore,
    int? totalCount,
  }) {
    return ArtistsPaginationState(
      artists: artists ?? this.artists,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}

class ArtistsPaginationNotifier extends AsyncNotifier<ArtistsPaginationState> {
  static const int _limit = 50;
  int _offset = 0;

  @override
  Future<ArtistsPaginationState> build() async {
    _offset = 0;
    
    final server = await ref.watch(activeServerProvider.future);
    if (server == null) {
      return ArtistsPaginationState(artists: [], hasMore: false, totalCount: 0);
    }
    
    final db = ref.watch(databaseProvider);
    final totalCount = await db.getArtistCount(server.id);
    
    final artists = await _fetchPage(0);
    return ArtistsPaginationState(
      artists: artists,
      hasMore: artists.length == _limit,
      totalCount: totalCount,
    );
  }

  Future<List<Artist>> _fetchPage(int offset) async {
    final server = await ref.watch(activeServerProvider.future);
    if (server == null) return [];
    
    final db = ref.watch(databaseProvider);
    final sortOption = ref.watch(artistSortProvider);
    final networkState = ref.watch(networkProvider);
    final isOfflineMode = networkState.isOffline;
    
    final artists = await db.getArtistsPaginated(
      server.id,
      offset: offset,
      limit: _limit,
      sort: sortOption,
      offlineFirst: isOfflineMode,
    );
    
    if (sortOption == ArtistSortOption.random) {
       artists.shuffle();
    }
    return artists;
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.hasError) return;
    final currentState = state.value;
    if (currentState == null || currentState.isLoadingMore || !currentState.hasMore) return;
    
    state = AsyncValue.data(currentState.copyWith(isLoadingMore: true));
    
    try {
      final newArtists = await _fetchPage(_offset + _limit);
      _offset += _limit;
      state = AsyncValue.data(currentState.copyWith(
        artists: [...currentState.artists, ...newArtists],
        hasMore: newArtists.length == _limit,
        isLoadingMore: false,
      ));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final artistsProvider = AsyncNotifierProvider<ArtistsPaginationNotifier, ArtistsPaginationState>(() {
  return ArtistsPaginationNotifier();
});
final artistDetailProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, id) async {
  final networkState = ref.watch(networkProvider);
  if (networkState.isOffline) return null;

  final api = ref.watch(subsonicApiProvider);
  if (api == null) return null;

  // 取得藝術家基本資料與專輯
  final artistData = await api.getArtist(id);
  if (artistData == null) return null;

  // 取得額外資訊 (bio)
  final artistInfo = await api.getArtistInfo2(id);
  if (artistInfo != null) {
    artistData['biography'] = artistInfo['biography'];
  }

  // 取得熱門歌曲 (Top 10)
  final String artistName = artistData['name'] ?? '';
  List<dynamic> topSongs = [];
  if (artistName.isNotEmpty) {
    final fetchedTop = await api.getTopSongs(artistName, count: 10);
    topSongs = List<dynamic>.from(fetchedTop);
  }

  // 排序 by playCount descending
  topSongs.sort((a, b) {
    final countA = a['playCount'] as int? ?? 0;
    final countB = b['playCount'] as int? ?? 0;
    return countB.compareTo(countA);
  });

  // 如果不足 10 首，從該歌手的專輯中隨機挑選補充
  if (topSongs.length < 10) {
    var albums = artistData['album'];
    if (albums != null) {
      if (albums is! List) albums = [albums];
      final albumList = List<dynamic>.from(albums)..shuffle();
      
      List<dynamic> additionalSongs = [];
      Set<String> existingSongIds = topSongs.map((s) => s['id'].toString()).toSet();

      // 抽取最多 5 張專輯
      final albumsToFetch = albumList.take(5);
      final futures = albumsToFetch.map((album) => api.getAlbum(album['id'].toString()));
      final fetchedAlbums = await Future.wait(futures);

      List<dynamic> pool = [];
      for (var albumData in fetchedAlbums) {
        if (albumData != null) {
          var songs = albumData['song'];
          if (songs != null) {
            if (songs is! List) songs = [songs];
            pool.addAll(songs);
          }
        }
      }

      // 將所有抽取的專輯歌曲倒進大池子徹底打散
      pool.shuffle();

      for (var song in pool) {
        final sId = song['id'].toString();
        if (!existingSongIds.contains(sId)) {
          additionalSongs.add(song);
          existingSongIds.add(sId);
          if (additionalSongs.length >= (10 - topSongs.length)) break;
        }
      }
      topSongs.addAll(additionalSongs);
    }
  }

  // 為了確保最多只有 10 首
  if (topSongs.length > 10) {
    topSongs = topSongs.sublist(0, 10);
  }

  artistData['topSongs'] = topSongs;

  // 將專輯依年份排序 (新 -> 舊)
  var albums = artistData['album'];
  if (albums != null) {
    if (albums is! List) albums = [albums];
    final albumList = List<dynamic>.from(albums);
    albumList.sort((a, b) {
      final yearA = a['year'] as int? ?? 0;
      final yearB = b['year'] as int? ?? 0;
      return yearB.compareTo(yearA); // descending
    });
    artistData['album'] = albumList;
  }

  return artistData;
});
