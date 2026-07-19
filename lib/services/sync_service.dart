import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenify/services/image_service.dart';
import 'package:zenify/models/album.dart';
import 'package:zenify/models/artist.dart';
import 'package:zenify/providers/app_providers.dart';

class SyncState {
  final bool isSyncing;
  final String message;
  final double progress; // 0.0 to 1.0

  SyncState({this.isSyncing = false, this.message = '', this.progress = 0.0});

  SyncState copyWith({bool? isSyncing, String? message, double? progress}) {
    return SyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      message: message ?? this.message,
      progress: progress ?? this.progress,
    );
  }
}

class SyncNotifier extends Notifier<SyncState> {
  @override
  SyncState build() {
    return SyncState();
  }

  Future<void> startSync() async {
    if (state.isSyncing) return;

    final api = ref.read(subsonicApiProvider);
    final server = await ref.read(activeServerProvider.future);
    final db = ref.read(databaseProvider);

    if (api == null || server == null) {
      state = state.copyWith(isSyncing: false, message: '錯誤：無法連線伺服器');
      return;
    }

    state = state.copyWith(isSyncing: true, message: '開始同步藝術家...', progress: 0.1);

    try {
      // 1. 同步藝術家
      final artistsData = await api.getArtists();
      List<Artist> artists = artistsData.map((data) {
        return Artist()
          ..artistId = data['id'].toString()
          ..serverId = server.id
          ..name = data['name']
          ..coverArt = data['coverArt']
          ..albumCount = data['albumCount']
          ..rawData = jsonEncode(data);
      }).toList();
      
      await db.saveArtists(artists);

      // 2. 同步專輯
      state = state.copyWith(message: '開始同步專輯...', progress: 0.3);
      
      List<Album> allAlbums = [];
      int offset = 0;
      final int size = 500;
      bool hasMore = true;

      while (hasMore) {
        final batch = await api.getAlbumList(size: size, offset: offset);
        if (batch.isEmpty) {
          hasMore = false;
        } else {
          allAlbums.addAll(batch.map((data) {
            return Album()
              ..albumId = data['id'].toString()
              ..serverId = server.id
              ..name = data['name']
              ..artist = data['artist']
              ..artistId = data['artistId']?.toString()
              ..songCount = data['songCount']
              ..duration = data['duration']
              ..year = data['year']
              ..coverArt = data['coverArt']
              ..rawData = jsonEncode(data);
          }));

          offset += size;
          state = state.copyWith(
            message: '已同步 ${allAlbums.length} 張專輯',
            progress: 0.3 + (0.6 * (allAlbums.length / (allAlbums.length + size))) // 粗略計算進度
          );

          if (batch.length < size) {
            hasMore = false;
          }
        }
      }

      await db.saveAlbums(allAlbums);

      // 3. 同步並下載封面圖片
      state = state.copyWith(message: '準備下載封面圖片...', progress: 0.9);
      
      final Set<String> coverIds = {};
      for (var artist in artists) {
        if (artist.coverArt != null) coverIds.add(artist.coverArt!);
      }
      for (var album in allAlbums) {
        if (album.coverArt != null) coverIds.add(album.coverArt!);
      }

      final List<String> coverIdsList = coverIds.toList();
      final int totalCovers = coverIdsList.length;
      int downloaded = 0;
      final int batchSize = 10;
      
      final imageService = ImageService();

      for (int i = 0; i < totalCovers; i += batchSize) {
        final end = (i + batchSize < totalCovers) ? i + batchSize : totalCovers;
        final batch = coverIdsList.sublist(i, end);
        
        await Future.wait(batch.map((coverId) async {
          final thumbUrl = api.getCoverArtUrl(coverId, size: 250);
          await imageService.downloadImage(thumbUrl, coverId, server.id, isThumb: true);
          
          final fullUrl = api.getCoverArtUrl(coverId); // 不加 size 就是抓原圖
          await imageService.downloadImage(fullUrl, coverId, server.id, isThumb: false);
        }));

        downloaded += batch.length;
        state = state.copyWith(
          message: '下載封面圖片中... ($downloaded/$totalCovers)',
          progress: 0.9 + (0.1 * (downloaded / totalCovers)),
        );
      }

      // 重新載入列表
      ref.invalidate(albumsProvider);
      ref.invalidate(artistsProvider);

      state = state.copyWith(isSyncing: false, message: '同步完成！共載入 ${allAlbums.length} 張專輯。', progress: 1.0);
    } catch (e) {
      state = state.copyWith(isSyncing: false, message: '同步失敗：$e', progress: 0.0);
    }
  }
}

final syncProvider = NotifierProvider<SyncNotifier, SyncState>(() {
  return SyncNotifier();
});
