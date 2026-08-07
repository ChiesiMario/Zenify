import 'package:zenify/l10n/app_localizations.dart';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenify/services/image_service.dart';
import 'package:zenify/models/album.dart';
import 'package:zenify/models/artist.dart';
import 'package:zenify/providers/app_providers.dart';
import 'package:zenify/views/playlists_view.dart';
import 'package:zenify/models/favorite_item.dart';
import 'package:zenify/models/playlist_cache.dart';
import 'package:zenify/models/album_detail_cache.dart';

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

  Future<void> startSync(AppLocalizations l10n, {bool force = false}) async {
    if (state.isSyncing && !force) return;

    final api = ref.read(subsonicApiProvider);
    final server = await ref.read(activeServerProvider.future);
    final db = ref.read(databaseProvider);

    if (api == null || server == null) {
      state = state.copyWith(isSyncing: false, message: l10n.errorCannotConnectServer);
      return;
    }

    state = state.copyWith(isSyncing: true, message: l10n.startSyncingArtists, progress: 0.1);

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
      ref.invalidate(artistsProvider);

      // 2. 同步專輯
      state = state.copyWith(message: l10n.startSyncingAlbums, progress: 0.3);
      
      List<Album> allAlbums = [];
      int offset = 0;
      final int size = 500;
      bool hasMore = true;

      while (hasMore) {
        final batch = await api.getAlbumList(size: size, offset: offset);
        if (batch.isEmpty) {
          hasMore = false;
        } else {
          final mappedBatch = batch.map((data) {
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
          }).toList();

          allAlbums.addAll(mappedBatch);
          await db.saveAlbums(mappedBatch);
          ref.invalidate(albumsProvider);

          offset += size;
          state = state.copyWith(
            message: l10n.syncedAlbumsCount(allAlbums.length.toString()),
            progress: 0.3 + (0.6 * (allAlbums.length / (allAlbums.length + size))) // 粗略計算進度
          );

          if (batch.length < size) {
            hasMore = false;
          }
        }
      }

      // 3. 同步並下載封面圖片
      state = state.copyWith(message: l10n.preparingToDownloadCovers, progress: 0.9);
      
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
          message: l10n.downloadingCoversProgress(downloaded.toString(), totalCovers.toString()),
          progress: 0.9 + (0.1 * (downloaded / totalCovers)),
        );
      }

      // 4. 同步最愛 (Favorites)
      state = state.copyWith(message: l10n.syncingFavorites, progress: 0.95);
      final starred = await api.getStarred();
      List<FavoriteItem> favItems = [];
      
      void addFavs(List<dynamic> items, String type) {
        for (var item in items) {
          favItems.add(FavoriteItem()
            ..serverId = server.id
            ..itemId = item['id'].toString()
            ..itemType = type
            ..rawData = jsonEncode(item)
          );
        }
      }
      
      addFavs(starred['artists'] ?? [], 'artist');
      addFavs(starred['albums'] ?? [], 'album');
      addFavs(starred['songs'] ?? [], 'song');
      
      await db.clearFavorites(server.id);
      await db.saveFavorites(favItems);

      // 5. 同步播放清單 (Playlists)
      state = state.copyWith(message: l10n.syncingPlaylists, progress: 0.97);
      final playlists = await api.getPlaylists();
      List<PlaylistCache> playlistCaches = [];
      
      for (var p in playlists) {
        final pId = p['id'].toString();
        // Fetch detailed playlist to get tracks
        final detailed = await api.getPlaylist(pId);
        if (detailed != null) {
          playlistCaches.add(PlaylistCache()
            ..serverId = server.id
            ..playlistId = pId
            ..name = detailed['name'] ?? p['name'] ?? 'Unknown'
            ..rawData = jsonEncode(detailed)
          );
        } else {
          playlistCaches.add(PlaylistCache()
            ..serverId = server.id
            ..playlistId = pId
            ..name = p['name'] ?? 'Unknown'
            ..rawData = jsonEncode(p)
          );
        }
      }
      
      await db.clearPlaylists(server.id);
      await db.savePlaylists(playlistCaches);

      // 6. 同步已離線歌曲的專輯資訊
      state = state.copyWith(message: l10n.syncingOfflineAlbums, progress: 0.98);
      
      final downloadedTracks = await db.getDownloadedTracks(server.id);
      final offlineAlbumIds = downloadedTracks
          .where((t) => t.isComplete && t.albumId != null)
          .map((t) => t.albumId!)
          .toSet();

      int offlineAlbumsFetched = 0;
      final totalOfflineAlbums = offlineAlbumIds.length;
      
      for (final aId in offlineAlbumIds) {
        final existing = await db.getAlbumDetail(server.id, aId);
        if (existing == null) {
          final result = await api.getAlbum(aId);
          if (result != null) {
            final cache = AlbumDetailCache()
              ..serverId = server.id
              ..albumId = aId
              ..rawData = jsonEncode(result);
            await db.saveAlbumDetail(cache);
          }
        }
        offlineAlbumsFetched++;
        state = state.copyWith(
          message: l10n.syncingOfflineAlbumsProgress(offlineAlbumsFetched.toString(), totalOfflineAlbums.toString()),
          progress: 0.98 + (0.01 * (offlineAlbumsFetched / (totalOfflineAlbums > 0 ? totalOfflineAlbums : 1))),
        );
      }

      // 重新載入其餘列表
      ref.invalidate(favoritesProvider);
      ref.invalidate(playlistsProvider);

      state = state.copyWith(isSyncing: false, message: l10n.syncCompleteAlbumsLoaded(allAlbums.length.toString()), progress: 1.0);
    } catch (e) {
      state = state.copyWith(isSyncing: false, message: l10n.syncFailed(e.toString()), progress: 0.0);
    }
  }
}

final syncProvider = NotifierProvider<SyncNotifier, SyncState>(() {
  return SyncNotifier();
});
