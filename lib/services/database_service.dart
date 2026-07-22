import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
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
      final dir = await getApplicationDocumentsDirectory();
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
    final cacheTracks = await isar.downloadedTracks.filter().isManualDownloadEqualTo(false).findAll();
    await isar.writeTxn(() async {
      for (var t in cacheTracks) {
        await isar.downloadedTracks.delete(t.id);
      }
    });
    return cacheTracks;
  }
}
