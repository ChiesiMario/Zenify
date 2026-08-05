import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenify/providers/server_providers.dart';
import 'package:zenify/providers/sort_providers.dart';
import 'package:zenify/providers/network_provider.dart';

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
