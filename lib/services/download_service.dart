import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:zenify/services/path_service.dart';
import 'package:path/path.dart' as p;
import 'package:zenify/api/subsonic_api.dart';
import 'package:zenify/models/downloaded_track.dart';
import 'package:zenify/services/database_service.dart';

class DownloadService {
  final DatabaseService _db;
  final SubsonicApi? _api;
  final double _cacheLimitGb;
  final Function(String, double)? onProgress;

  DownloadService(this._db, this._api, this._cacheLimitGb, {this.onProgress});

  Future<void> downloadSong(dynamic song, int serverId) async {
    if (_api == null) return;
    final songId = song['id'].toString();

    // Check if existing record exists and file is on disk
    var track = await _db.getDownloadedTrack(songId);
    if (track != null && track.isComplete && File(track.localPath).existsSync()) {
      bool changed = false;
      if (!track.isManualDownload) {
        track.isManualDownload = true;
        changed = true;
      }
      if (track.serverId != serverId) {
        track.serverId = serverId;
        changed = true;
      }
      if (changed) {
        await _db.saveDownloadedTrack(track);
      }
      if (onProgress != null) {
        onProgress!(songId, 1.0);
      }
      return;
    }

    try {
      final downloadDir = await PathService.getOfflineDir();
      final localPath = p.join(downloadDir.path, '$songId.mp3');
      final streamUrl = await _api!.getStreamUrl(songId);

      final request = http.Request('GET', Uri.parse(streamUrl));
      final response = await http.Client().send(request);

      if (response.statusCode != 200) {
        throw Exception('Server returned status code: ${response.statusCode}');
      }

      if (onProgress != null) {
        onProgress!(songId, 0.0);
      }

      final contentLength = response.contentLength ?? 0;
      int downloaded = 0;
      
      final file = File(localPath);
      if (file.existsSync()) {
        file.deleteSync(); // restart download
      }
      final sink = file.openWrite();

      await for (final chunk in response.stream) {
        sink.add(chunk);
        downloaded += chunk.length;
        if (contentLength > 0 && onProgress != null) {
          onProgress!(songId, downloaded / contentLength);
        }
      }
      await sink.close();

      track = DownloadedTrack()
        ..songId = songId
        ..serverId = serverId
        ..title = song['title'] ?? 'Unknown'
        ..artist = song['artist'] ?? 'Unknown'
        ..album = song['album']
        ..albumId = song['albumId']?.toString()
        ..coverArt = song['coverArt']
        ..duration = song['duration'] ?? 0
        ..localPath = localPath
        ..sizeBytes = downloaded
        ..downloadedAt = DateTime.now()
        ..rawData = jsonEncode(song)
        ..isComplete = true
        ..isManualDownload = true;

      await _db.saveDownloadedTrack(track);

      if (onProgress != null) {
        onProgress!(songId, 1.0); // complete
      }
    } catch (e) {
      print('Download error: $e');
      rethrow;
    }
  }

  Future<void> deleteDownload(String songId) async {
    final track = await _db.getDownloadedTrack(songId);
    if (track != null) {
      // User deleted an offline download, convert to cache
      track.isManualDownload = false;
      await _db.saveDownloadedTrack(track);
      
      // Immediately enforce cache limit in case converting this pushes it over
      await _db.enforceCacheLimit(_cacheLimitGb);
    }
  }

  Future<void> deleteAllManualDownloads(int serverId) async {
    final tracks = await _db.getDownloadedTracks(serverId);
    for (final track in tracks) {
      if (track.isManualDownload) {
        track.isManualDownload = false;
        await _db.saveDownloadedTrack(track);
      }
    }
    await _db.enforceCacheLimit(_cacheLimitGb);
  }

  Future<void> clearAllCaches() async {
    final deleted = await _db.deleteCacheTracks();
    for (final track in deleted) {
      final file = File(track.localPath);
      if (file.existsSync()) {
        try {
          file.deleteSync();
        } catch (_) {}
      }
    }
  }
}
