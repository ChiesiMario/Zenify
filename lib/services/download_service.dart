import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:zenify/api/subsonic_api.dart';
import 'package:zenify/models/downloaded_track.dart';
import 'package:zenify/services/database_service.dart';

class DownloadService {
  final DatabaseService _db;
  final SubsonicApi? _api;
  final Function(String, double)? onProgress;

  DownloadService(this._db, this._api, {this.onProgress});

  Future<void> downloadSong(dynamic song, int serverId) async {
    if (_api == null) return;
    final songId = song['id'].toString();

    // Check if existing record exists
    final existing = await _db.getDownloadedTrack(songId);
    if (existing != null) {
      if (existing.isManualDownload && existing.isComplete) return;

      if (existing.isComplete && File(existing.localPath).existsSync()) {
        // Upgrade auto-cache track to manual download
        existing.isManualDownload = true;
        await _db.saveDownloadedTrack(existing);
        if (onProgress != null) {
          onProgress!(songId, 1.0);
        }
        return;
      } else if (!existing.isComplete) {
        // Mark as manual download so when stream finishes it stays as manual download
        existing.isManualDownload = true;
        await _db.saveDownloadedTrack(existing);
      }
    }

    final dir = await getApplicationDocumentsDirectory();
    final downloadDir = Directory('${dir.path}/zenify_downloads');
    if (!downloadDir.existsSync()) {
      downloadDir.createSync(recursive: true);
    }

    final localPath = '${downloadDir.path}/${songId}.mp3';
    final streamUrl = _api.getStreamUrl(songId);

    try {
      final request = http.Request('GET', Uri.parse(streamUrl));
      final response = await http.Client().send(request);

      if (response.statusCode != 200) return;

      final contentLength = response.contentLength ?? 0;
      int downloaded = 0;
      final file = File(localPath);
      final sink = file.openWrite();

      await for (final chunk in response.stream) {
        sink.add(chunk);
        downloaded += chunk.length;
        if (contentLength > 0 && onProgress != null) {
          onProgress!(songId, downloaded / contentLength);
        }
      }
      await sink.close();

      // Save to database
      final track = existing ?? DownloadedTrack();
      track
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
    }
  }

  Future<void> deleteDownload(String songId) async {
    final track = await _db.getDownloadedTrack(songId);
    if (track != null) {
      final file = File(track.localPath);
      if (file.existsSync()) {
        file.deleteSync();
      }
      await _db.deleteDownloadedTrack(track.id);
    }
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
