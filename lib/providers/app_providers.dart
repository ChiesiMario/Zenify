import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenify/api/subsonic_api.dart';
import 'package:zenify/models/server.dart';
import 'package:zenify/services/database_service.dart';
import 'package:zenify/services/image_service.dart';

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
  final albums = await db.getAlbums(serverAsyncValue.value!.id);
  
  return albums.map((a) => jsonDecode(a.rawData)).toList();
});

final artistsProvider = FutureProvider<List<dynamic>>((ref) async {
  final serverAsyncValue = ref.watch(activeServerProvider);
  if (!serverAsyncValue.hasValue || serverAsyncValue.value == null) return [];
  
  final db = ref.watch(databaseProvider);
  final artists = await db.getArtists(serverAsyncValue.value!.id);
  
  return artists.map((a) => jsonDecode(a.rawData)).toList();
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
