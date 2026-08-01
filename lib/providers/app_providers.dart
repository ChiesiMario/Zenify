import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenify/api/subsonic_api.dart';
import 'package:zenify/models/server.dart';
import 'package:zenify/services/database_service.dart';
import 'package:zenify/services/image_service.dart';
import 'package:zenify/providers/sort_providers.dart';
import 'package:zenify/providers/theme_provider.dart';
import 'package:zenify/providers/download_provider.dart';
import 'package:zenify/providers/network_provider.dart';
import 'package:zenify/models/album_detail_cache.dart';
export 'package:zenify/providers/network_provider.dart';

final databaseProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

class CacheLimitNotifier extends Notifier<double> {
  @override
  double build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getDouble('cache_limit_gb') ?? 10.0;
  }
  
  void setLimit(double val) {
    state = val;
    ref.read(sharedPreferencesProvider).setDouble('cache_limit_gb', val);
  }
}

final cacheLimitProvider = NotifierProvider<CacheLimitNotifier, double>(() {
  return CacheLimitNotifier();
});

final downloadsTabProvider = StateProvider<int>((ref) => 0);

final activeServerProvider = FutureProvider<Server?>((ref) async {
  final db = ref.watch(databaseProvider);
  return await db.getActiveServer();
});

final subsonicApiProvider = Provider<SubsonicApi?>((ref) {
  final serverAsyncValue = ref.watch(activeServerProvider);
  
  if (serverAsyncValue.hasValue && serverAsyncValue.value != null) {
    return SubsonicApi(serverAsyncValue.value!);
  }
  return null;
});

final serversListProvider = FutureProvider<List<Server>>((ref) async {
  final db = ref.watch(databaseProvider);
  return await db.getServers();
});

final albumsProvider = FutureProvider<List<dynamic>>((ref) async {
  final server = await ref.watch(activeServerProvider.future);
  if (server == null) return [];
  
  final db = ref.watch(databaseProvider);
  final sortOption = ref.watch(albumSortProvider);
  
  final albums = await db.getAlbums(server.id);
  
  final downloadedTracksAsync = ref.watch(downloadedTracksProvider);
  final downloadedTracks = downloadedTracksAsync.valueOrNull ?? [];
  final offlineAlbumIds = downloadedTracks
      .where((t) => t.isManualDownload && t.isComplete)
      .map((t) => t.albumId)
      .whereType<String>()
      .toSet();

  final result = albums.map((a) {
    final map = jsonDecode(a.rawData) as Map<String, dynamic>;
    map['isOfflineAlbum'] = offlineAlbumIds.contains(map['id'].toString());
    return map;
  }).toList();
  
  int compareOffline(dynamic a, dynamic b) {
    final aOffline = a['isOfflineAlbum'] == true ? 1 : 0;
    final bOffline = b['isOfflineAlbum'] == true ? 1 : 0;
    return bOffline.compareTo(aOffline); // 1 (offline) before 0 (not offline)
  }

  final networkState = ref.watch(networkProvider);
  final isOfflineMode = networkState.isOffline;

  switch (sortOption) {
    case AlbumSortOption.nameAsc:
      result.sort((a, b) {
        if (isOfflineMode) {
          final offCmp = compareOffline(a, b);
          if (offCmp != 0) return offCmp;
        }
        return (a['name']?.toString() ?? '').compareTo(b['name']?.toString() ?? '');
      });
      break;
    case AlbumSortOption.nameDesc:
      result.sort((a, b) {
        if (isOfflineMode) {
          final offCmp = compareOffline(a, b);
          if (offCmp != 0) return offCmp;
        }
        return (b['name']?.toString() ?? '').compareTo(a['name']?.toString() ?? '');
      });
      break;
    case AlbumSortOption.yearDesc:
      result.sort((a, b) {
        if (isOfflineMode) {
          final offCmp = compareOffline(a, b);
          if (offCmp != 0) return offCmp;
        }
        return (b['year'] as int? ?? 0).compareTo(a['year'] as int? ?? 0);
      });
      break;
    case AlbumSortOption.yearAsc:
      result.sort((a, b) {
        if (isOfflineMode) {
          final offCmp = compareOffline(a, b);
          if (offCmp != 0) return offCmp;
        }
        return (a['year'] as int? ?? 0).compareTo(b['year'] as int? ?? 0);
      });
      break;
    case AlbumSortOption.random:
      result.shuffle();
      if (isOfflineMode) {
        result.sort(compareOffline); // Move non-offline to bottom
      }
      break;
    case AlbumSortOption.defaultOrder:
    default:
      if (isOfflineMode) {
        // We use stable sort by grouping
        final offline = result.where((e) => e['isOfflineAlbum'] == true).toList();
        final notOffline = result.where((e) => e['isOfflineAlbum'] != true).toList();
        result.clear();
        result.addAll(offline);
        result.addAll(notOffline);
      }
      break;
  }
  
  return result;
});

final artistsProvider = FutureProvider<List<dynamic>>((ref) async {
  final server = await ref.watch(activeServerProvider.future);
  if (server == null) return [];
  
  final db = ref.watch(databaseProvider);
  final sortOption = ref.watch(artistSortProvider);
  
  final artists = await db.getArtists(server.id);
  
  final result = artists.map((a) => jsonDecode(a.rawData)).toList();
  
  switch (sortOption) {
    case ArtistSortOption.nameAsc:
      result.sort((a, b) => (a['name']?.toString() ?? '').compareTo(b['name']?.toString() ?? ''));
      break;
    case ArtistSortOption.nameDesc:
      result.sort((a, b) => (b['name']?.toString() ?? '').compareTo(a['name']?.toString() ?? ''));
      break;
    case ArtistSortOption.albumCountDesc:
      result.sort((a, b) => (b['albumCount'] as int? ?? 0).compareTo(a['albumCount'] as int? ?? 0));
      break;
    case ArtistSortOption.random:
      result.shuffle();
      break;
    case ArtistSortOption.defaultOrder:
    default:
      // Leave as inserted order
      break;
  }
  
  return result;
});

final favoritesProvider = FutureProvider<Map<String, List<dynamic>>>((ref) async {
  final networkState = ref.watch(networkProvider);
  
  if (networkState.isOffline) {
    final server = await ref.watch(activeServerProvider.future);
    if (server == null) {
      return {'artists': [], 'albums': [], 'songs': []};
    }
    final db = ref.read(databaseProvider);
    final favs = await db.getFavorites(server.id);
    
    List<dynamic> artists = [];
    List<dynamic> albums = [];
    List<dynamic> songs = [];
    
    for (var f in favs) {
      try {
        final decoded = jsonDecode(f.rawData);
        if (f.itemType == 'artist') artists.add(decoded);
        else if (f.itemType == 'album') albums.add(decoded);
        else if (f.itemType == 'song') songs.add(decoded);
      } catch (_) {}
    }
    
    return {'artists': artists, 'albums': albums, 'songs': songs};
  }

  final api = ref.watch(subsonicApiProvider);
  if (api == null) return {'artists': [], 'albums': [], 'songs': []};
  return await api.getStarred();
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

final serverStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final server = await ref.watch(activeServerProvider.future);
  if (server == null) {
    return {'albums': 0, 'artists': 0, 'covers': 0};
  }
  
  final serverId = server.id;
  final db = ref.watch(databaseProvider);
  
  final imageService = ImageService();
  
  final albumCount = await db.getAlbumCount(serverId);
  final artistCount = await db.getArtistCount(serverId);
  final coverCount = await imageService.getDownloadedCoverCount(serverId);
  
  return {
    'albums': albumCount,
    'artists': artistCount,
    'covers': coverCount,
  };
});

class NavigationRequest {
  final String type; // 'artist' or 'album'
  final String id;
  final String name;
  
  NavigationRequest({required this.type, required this.id, required this.name});
}

final navigationRequestProvider = StateProvider<NavigationRequest?>((ref) => null);
