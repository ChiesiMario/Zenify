import 'dart:io';
import 'package:isar/isar.dart';
import 'package:zenify/services/path_service.dart';
import 'package:zenify/models/server.dart';
import 'package:zenify/models/album.dart';
import 'package:zenify/models/artist.dart';
import 'package:zenify/models/downloaded_track.dart';

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
        [ServerSchema, AlbumSchema, ArtistSchema, DownloadedTrackSchema],
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
}
