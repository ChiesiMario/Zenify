import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenify/api/subsonic_api.dart';
import 'package:zenify/models/server.dart';
import 'package:zenify/services/database_service.dart';
import 'package:zenify/services/image_service.dart';
import 'package:zenify/providers/sort_providers.dart';

final databaseProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

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
  final serverAsyncValue = ref.watch(activeServerProvider);
  if (!serverAsyncValue.hasValue || serverAsyncValue.value == null) return [];
  
  final db = ref.watch(databaseProvider);
  final sortOption = ref.watch(albumSortProvider);
  
  final albums = await db.getAlbums(serverAsyncValue.value!.id);
  
  final result = albums.map((a) => jsonDecode(a.rawData)).toList();
  
  switch (sortOption) {
    case AlbumSortOption.nameAsc:
      result.sort((a, b) => (a['name']?.toString() ?? '').compareTo(b['name']?.toString() ?? ''));
      break;
    case AlbumSortOption.nameDesc:
      result.sort((a, b) => (b['name']?.toString() ?? '').compareTo(a['name']?.toString() ?? ''));
      break;
    case AlbumSortOption.yearDesc:
      result.sort((a, b) => (b['year'] as int? ?? 0).compareTo(a['year'] as int? ?? 0));
      break;
    case AlbumSortOption.yearAsc:
      result.sort((a, b) => (a['year'] as int? ?? 0).compareTo(b['year'] as int? ?? 0));
      break;
    case AlbumSortOption.random:
      result.shuffle();
      break;
    case AlbumSortOption.defaultOrder:
    default:
      // Leave as inserted order
      break;
  }
  
  return result;
});

final artistsProvider = FutureProvider<List<dynamic>>((ref) async {
  final serverAsyncValue = ref.watch(activeServerProvider);
  if (!serverAsyncValue.hasValue || serverAsyncValue.value == null) return [];
  
  final db = ref.watch(databaseProvider);
  final sortOption = ref.watch(artistSortProvider);
  
  final artists = await db.getArtists(serverAsyncValue.value!.id);
  
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
  final api = ref.watch(subsonicApiProvider);
  if (api == null) return {'artists': [], 'albums': [], 'songs': []};
  return await api.getStarred();
});

final albumDetailProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, id) async {
  final api = ref.watch(subsonicApiProvider);
  if (api == null) return null;
  return await api.getAlbum(id);
});

final artistDetailProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, id) async {
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
  if (artistName.isNotEmpty) {
    final topSongs = await api.getTopSongs(artistName, count: 10);
    artistData['topSongs'] = topSongs;
  } else {
    artistData['topSongs'] = [];
  }

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
  final serverAsyncValue = ref.watch(activeServerProvider);
  if (!serverAsyncValue.hasValue || serverAsyncValue.value == null) {
    return {'albums': 0, 'artists': 0, 'covers': 0};
  }
  
  final serverId = serverAsyncValue.value!.id;
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
