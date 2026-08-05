import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenify/providers/server_providers.dart';
import 'package:zenify/providers/sort_providers.dart';
import 'package:zenify/providers/download_provider.dart';
import 'package:zenify/providers/network_provider.dart';
import 'package:zenify/models/album_detail_cache.dart';

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
