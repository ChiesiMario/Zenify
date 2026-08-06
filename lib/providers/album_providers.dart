import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenify/providers/server_providers.dart';
import 'package:zenify/providers/sort_providers.dart';
import 'package:zenify/providers/download_provider.dart';
import 'package:zenify/providers/network_provider.dart';
import 'package:zenify/models/album_detail_cache.dart';
import 'package:zenify/models/album.dart';

final albumsProvider = FutureProvider<List<Album>>((ref) async {
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

  final result = albums.toList(); // Copy list for sorting
  
  int compareOffline(Album a, Album b) {
    final aOffline = offlineAlbumIds.contains(a.albumId) ? 1 : 0;
    final bOffline = offlineAlbumIds.contains(b.albumId) ? 1 : 0;
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
        return (a.name ?? '').compareTo(b.name ?? '');
      });
      break;
    case AlbumSortOption.nameDesc:
      result.sort((a, b) {
        if (isOfflineMode) {
          final offCmp = compareOffline(a, b);
          if (offCmp != 0) return offCmp;
        }
        return (b.name ?? '').compareTo(a.name ?? '');
      });
      break;
    case AlbumSortOption.yearDesc:
      result.sort((a, b) {
        if (isOfflineMode) {
          final offCmp = compareOffline(a, b);
          if (offCmp != 0) return offCmp;
        }
        return (b.year ?? 0).compareTo(a.year ?? 0);
      });
      break;
    case AlbumSortOption.yearAsc:
      result.sort((a, b) {
        if (isOfflineMode) {
          final offCmp = compareOffline(a, b);
          if (offCmp != 0) return offCmp;
        }
        return (a.year ?? 0).compareTo(b.year ?? 0);
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
        final offline = result.where((e) => offlineAlbumIds.contains(e.albumId)).toList();
        final notOffline = result.where((e) => !offlineAlbumIds.contains(e.albumId)).toList();
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
