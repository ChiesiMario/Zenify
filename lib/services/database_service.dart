import 'dart:io';
import 'package:isar/isar.dart';
import 'package:zenify/services/path_service.dart';
import 'package:zenify/models/server.dart';
import 'package:zenify/models/album.dart';
import 'package:zenify/models/artist.dart';
import 'package:zenify/models/downloaded_track.dart';
import 'package:zenify/providers/sort_providers.dart';
import 'package:zenify/models/favorite_item.dart';
import 'package:zenify/models/playlist_cache.dart';
import 'package:zenify/models/album_detail_cache.dart';
import 'package:zenify/models/offline_preference.dart';

class DatabaseService {
  late Future<Isar> db;

  DatabaseService() {
    db = openDB();
  }

  Future<Isar> openDB() async {
    if (Isar.instanceNames.isEmpty) {
      await PathService.ensureInitialized();
      final dir = await PathService.getSupportDir();
      return await Isar.open(
        [ServerSchema, AlbumSchema, ArtistSchema, DownloadedTrackSchema, FavoriteItemSchema, PlaylistCacheSchema, AlbumDetailCacheSchema, OfflinePreferenceSchema],
        directory: dir.path,
        inspector: true,
      );
    }
    return Future.value(Isar.getInstance());
  }

  /// Get all servers
  Future<List<Server>> getServers() async {
    final isar = await db;
    return await isar.servers.where().findAll();
  }

  /// Add or Update a server
  Future<void> saveServer(Server server) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.servers.put(server);
    });
  }

  /// Delete a server
  Future<void> deleteServer(int id) async {
    final isar = await db;
    await isar.writeTxn(() async {
      // 1. Delete physical files from DownloadedTrack
      final tracks = await isar.downloadedTracks.filter().serverIdEqualTo(id).findAll();
      for (final track in tracks) {
        final file = File(track.localPath);
        if (file.existsSync()) {
          try {
            file.deleteSync();
          } catch (_) {}
        }
      }

      // 2. Delete related records
      await isar.downloadedTracks.filter().serverIdEqualTo(id).deleteAll();
      await isar.offlinePreferences.filter().serverIdEqualTo(id).deleteAll();
      await isar.playlistCaches.filter().serverIdEqualTo(id).deleteAll();
      await isar.favoriteItems.filter().serverIdEqualTo(id).deleteAll();
      await isar.albumDetailCaches.filter().serverIdEqualTo(id).deleteAll();
      await isar.albums.filter().serverIdEqualTo(id).deleteAll();
      await isar.artists.filter().serverIdEqualTo(id).deleteAll();

      // 3. Delete server record
      await isar.servers.delete(id);
    });
  }

  /// Get currently active server
  Future<Server?> getActiveServer() async {
    final isar = await db;
    return await isar.servers.filter().isActiveEqualTo(true).findFirst();
  }

  /// Set a server as active (and deactivate others)
  Future<void> setActiveServer(int id) async {
    final isar = await db;
    final servers = await isar.servers.where().findAll();
    
    await isar.writeTxn(() async {
      for (var server in servers) {
        if (server.id == id) {
          server.isActive = true;
        } else {
          server.isActive = false;
        }
        await isar.servers.put(server);
      }
    });
  }

  /// Get all albums for a server
  Future<List<Album>> getAlbums(int serverId) async {
    final isar = await db;
    return await isar.albums.filter().serverIdEqualTo(serverId).findAll();
  }

  /// Save multiple albums
  Future<void> saveAlbums(List<Album> albums) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.albums.putAll(albums);
    });
  }

  /// Get albums paginated
  Future<List<Album>> getAlbumsPaginated(
    int serverId, {
    required int offset,
    required int limit,
    required AlbumSortOption sort,
    bool offlineFirst = false,
  }) async {
    final isar = await db;
    final q = isar.albums.filter().serverIdEqualTo(serverId);
    
    if (offlineFirst) {
      switch (sort) {
        case AlbumSortOption.nameAsc:
          return await q.sortByHasOfflineTracksDesc().thenByName().offset(offset).limit(limit).findAll();
        case AlbumSortOption.nameDesc:
          return await q.sortByHasOfflineTracksDesc().thenByNameDesc().offset(offset).limit(limit).findAll();
        case AlbumSortOption.yearDesc:
          return await q.sortByHasOfflineTracksDesc().thenByYearDesc().offset(offset).limit(limit).findAll();
        case AlbumSortOption.yearAsc:
          return await q.sortByHasOfflineTracksDesc().thenByYear().offset(offset).limit(limit).findAll();
        default:
          return await q.sortByHasOfflineTracksDesc().offset(offset).limit(limit).findAll();
      }
    } else {
      switch (sort) {
        case AlbumSortOption.nameAsc:
          return await q.sortByName().offset(offset).limit(limit).findAll();
        case AlbumSortOption.nameDesc:
          return await q.sortByNameDesc().offset(offset).limit(limit).findAll();
        case AlbumSortOption.yearDesc:
          return await q.sortByYearDesc().offset(offset).limit(limit).findAll();
        case AlbumSortOption.yearAsc:
          return await q.sortByYear().offset(offset).limit(limit).findAll();
        default:
          return await q.offset(offset).limit(limit).findAll();
      }
    }
  }

  /// Get all artists for a server
  Future<List<Artist>> getArtists(int serverId) async {
    final isar = await db;
    return await isar.artists.filter().serverIdEqualTo(serverId).findAll();
  }

  /// Save multiple artists
  Future<void> saveArtists(List<Artist> artists) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.artists.putAll(artists);
    });
  }

  /// Get artists paginated
  Future<List<Artist>> getArtistsPaginated(
    int serverId, {
    required int offset,
    required int limit,
    required ArtistSortOption sort,
    bool offlineFirst = false,
  }) async {
    final isar = await db;
    final q = isar.artists.filter().serverIdEqualTo(serverId);
    
    if (offlineFirst) {
      switch (sort) {
        case ArtistSortOption.nameAsc:
          return await q.sortByHasOfflineTracksDesc().thenByName().offset(offset).limit(limit).findAll();
        case ArtistSortOption.nameDesc:
          return await q.sortByHasOfflineTracksDesc().thenByNameDesc().offset(offset).limit(limit).findAll();
        case ArtistSortOption.albumCountDesc:
          return await q.sortByHasOfflineTracksDesc().thenByAlbumCountDesc().offset(offset).limit(limit).findAll();
        default:
          return await q.sortByHasOfflineTracksDesc().offset(offset).limit(limit).findAll();
      }
    } else {
      switch (sort) {
        case ArtistSortOption.nameAsc:
          return await q.sortByName().offset(offset).limit(limit).findAll();
        case ArtistSortOption.nameDesc:
          return await q.sortByNameDesc().offset(offset).limit(limit).findAll();
        case ArtistSortOption.albumCountDesc:
          return await q.sortByAlbumCountDesc().offset(offset).limit(limit).findAll();
        default:
          return await q.offset(offset).limit(limit).findAll();
      }
    }
  }

  /// Get total album count for a server
  Future<int> getAlbumCount(int serverId) async {
    final isar = await db;
    return await isar.albums.filter().serverIdEqualTo(serverId).count();
  }

  /// Get total artist count for a server
  Future<int> getArtistCount(int serverId) async {
    final isar = await db;
    return await isar.artists.filter().serverIdEqualTo(serverId).count();
  }

  /// Get all downloaded tracks for a server
  Future<List<DownloadedTrack>> getDownloadedTracks(int serverId) async {
    final isar = await db;
    return await isar.downloadedTracks.filter().serverIdEqualTo(serverId).findAll();
  }

  /// Get a single downloaded track by song ID
  Future<DownloadedTrack?> getDownloadedTrack(String songId) async {
    final isar = await db;
    return await isar.downloadedTracks.filter().songIdEqualTo(songId).findFirst();
  }

  /// Save or update a downloaded track
  Future<void> saveDownloadedTrack(DownloadedTrack track) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.downloadedTracks.put(track);
    });
  }

  /// Delete a downloaded track by ID (local path needs to be deleted separately)
  Future<void> deleteDownloadedTrack(Id id) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.downloadedTracks.delete(id);
    });
  }

  /// Get album detail cache
  Future<AlbumDetailCache?> getAlbumDetail(int serverId, String albumId) async {
    final isar = await db;
    return await isar.albumDetailCaches
        .filter()
        .serverIdEqualTo(serverId)
        .and()
        .albumIdEqualTo(albumId)
        .findFirst();
  }

  /// Save album detail cache
  Future<void> saveAlbumDetail(AlbumDetailCache cache) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.albumDetailCaches.put(cache);
    });
  }

  /// Get all favorites for a server
  Future<List<FavoriteItem>> getFavorites(int serverId) async {
    final isar = await db;
    return await isar.favoriteItems.filter().serverIdEqualTo(serverId).findAll();
  }

  /// Save favorites
  Future<void> saveFavorites(List<FavoriteItem> items) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.favoriteItems.putAll(items);
    });
  }
  
  /// Clear favorites for a server
  Future<void> clearFavorites(int serverId) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.favoriteItems.filter().serverIdEqualTo(serverId).deleteAll();
    });
  }

  /// Get all playlists for a server
  Future<List<PlaylistCache>> getPlaylists(int serverId) async {
    final isar = await db;
    return await isar.playlistCaches.filter().serverIdEqualTo(serverId).findAll();
  }
  
  /// Get single playlist by ID
  Future<PlaylistCache?> getPlaylist(int serverId, String playlistId) async {
    final isar = await db;
    return await isar.playlistCaches.filter().serverIdEqualTo(serverId).and().playlistIdEqualTo(playlistId).findFirst();
  }

  /// Save playlists
  Future<void> savePlaylists(List<PlaylistCache> items) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.playlistCaches.putAll(items);
    });
  }
  
  /// Clear playlists for a server
  Future<void> clearPlaylists(int serverId) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.playlistCaches.filter().serverIdEqualTo(serverId).deleteAll();
    });
  }

  /// Delete all auto-cache tracks from database
  Future<List<DownloadedTrack>> deleteCacheTracks() async {
    final isar = await db;
    final deleted = <DownloadedTrack>[];
    await isar.writeTxn(() async {
      final cacheTracks = await isar.downloadedTracks.filter().isManualDownloadEqualTo(false).findAll();
      deleted.addAll(cacheTracks);
      for (final t in cacheTracks) {
        await isar.downloadedTracks.delete(t.id);
      }
    });
    return deleted;
  }

  /// Update all downloaded track local paths when root directory changes
  Future<void> updateAllDownloadPaths(String oldRoot, String newRoot) async {
    final isar = await db;
    await isar.writeTxn(() async {
      final tracks = await isar.downloadedTracks.where().findAll();
      for (final track in tracks) {
        if (track.localPath.startsWith(oldRoot)) {
          track.localPath = track.localPath.replaceFirst(oldRoot, newRoot);
          await isar.downloadedTracks.put(track);
        }
      }
    });
  }


  Future<void> enforceCacheLimit(double limitGb) async {
    if (limitGb > 10.0) return; // Unlimited
    final isar = await db;
    final maxBytes = (limitGb * 1024 * 1024 * 1024).toInt();

    final allCaches = await isar.downloadedTracks
        .where()
        .filter()
        .isManualDownloadEqualTo(false)
        .sortByDownloadedAt()
        .findAll();

    int currentBytes = 0;
    for (final track in allCaches) {
      currentBytes += track.sizeBytes;
    }

    if (currentBytes <= maxBytes) return;

    await isar.writeTxn(() async {
      for (final track in allCaches) {
        if (currentBytes <= maxBytes) break;
        final file = File(track.localPath);
        if (file.existsSync()) {
          try {
            file.deleteSync();
          } catch (_) {}
        }
        currentBytes -= track.sizeBytes;
        await isar.downloadedTracks.delete(track.id);
      }
    });
  }

  /// Get offline preference
  Future<OfflinePreference?> getOfflinePreference(int serverId, String type, String targetId) async {
    final isar = await db;
    return await isar.offlinePreferences
        .filter()
        .serverIdEqualTo(serverId)
        .and()
        .typeEqualTo(type)
        .and()
        .targetIdEqualTo(targetId)
        .findFirst();
  }

  /// Get all offline preferences that are true
  Future<List<OfflinePreference>> getActiveOfflinePreferences() async {
    final isar = await db;
    return await isar.offlinePreferences.filter().isOfflineEqualTo(true).findAll();
  }

  /// Save offline preference
  Future<void> saveOfflinePreference(OfflinePreference pref) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.offlinePreferences.put(pref);
    });
  }
}
