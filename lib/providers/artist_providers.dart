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
class ArtistDetailArgs {
  final String id;
  final String name;

  const ArtistDetailArgs({required this.id, required this.name});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArtistDetailArgs &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}

final artistDetailProvider = FutureProvider.family<Map<String, dynamic>?, ArtistDetailArgs>((ref, args) async {
  final networkState = ref.watch(networkProvider);
  if (networkState.isOffline) return null;

  final api = ref.watch(subsonicApiProvider);
  if (api == null) return null;

  // 併發取得藝術家基本資料、額外資訊 (bio) 與熱門歌曲
  final results = await Future.wait([
    api.getArtist(args.id),
    api.getArtistInfo2(args.id),
    if (args.name.isNotEmpty) api.getTopSongs(args.name, count: 10) else Future.value([]),
  ]);

  final artistData = results[0] as Map<String, dynamic>?;
  final artistInfo = results[1] as Map<String, dynamic>?;
  final fetchedTop = results[2] as List<dynamic>;

  if (artistData == null) return null;

  if (artistInfo != null) {
    artistData['biography'] = artistInfo['biography'];
  }

  // 取得熱門歌曲 (Top 10)
  List<dynamic> topSongs = List<dynamic>.from(fetchedTop);

  // 排序 by playCount descending
  topSongs.sort((a, b) {
    final countA = a['playCount'] as int? ?? 0;
    final countB = b['playCount'] as int? ?? 0;
    return countB.compareTo(countA);
  });


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
