import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenify/providers/app_providers.dart';
import 'package:zenify/providers/download_provider.dart';
import 'package:zenify/api/subsonic_api.dart';
import 'package:zenify/providers/offline_preference_provider.dart';

class BackgroundSyncService {
  final Ref ref;
  Timer? _timer;

  BackgroundSyncService(this.ref);

  void start() {
    // Check every 10 minutes
    _timer = Timer.periodic(const Duration(minutes: 10), (_) {
      _syncOfflineContent();
    });
    // Trigger an initial check after a short delay
    Future.delayed(const Duration(seconds: 10), _syncOfflineContent);

    // Listen to changes in favorites
    ref.listen<AsyncValue<Map<String, List<dynamic>>>>(favoritesProvider, (previous, next) {
      if (next.hasValue && previous?.value != null) {
        _onFavoritesChanged(previous!.value!, next.value!);
      }
    });
  }

  Future<void> _onFavoritesChanged(Map<String, List<dynamic>> prev, Map<String, List<dynamic>> next) async {
    try {
      final isOfflineFavoritesOn = ref.read(offlinePreferenceProvider).valueOrNull?.favoritesPreference == true;
      if (!isOfflineFavoritesOn) return;

      final server = await ref.read(activeServerProvider.future);
      if (server == null) return;
      
      final downloadService = ref.read(downloadServiceProvider);
      
      final prevSongs = prev['songs'] ?? [];
      final nextSongs = next['songs'] ?? [];
      
      final prevIds = prevSongs.map((s) => s['id'].toString()).toSet();
      final nextIds = nextSongs.map((s) => s['id'].toString()).toSet();
      
      final addedIds = nextIds.difference(prevIds);
      final removedIds = prevIds.difference(nextIds);
      
      // Handle added songs
      for (final song in nextSongs) {
        final id = song['id'].toString();
        if (addedIds.contains(id)) {
          downloadService.downloadSong(song, server.id).catchError((e) {
            print('Background auto-download favorite song error: $e');
          });
        }
      }
      
      // Handle removed songs
      for (final id in removedIds) {
        await downloadService.deleteDownload(id);
      }
      
      if (addedIds.isNotEmpty || removedIds.isNotEmpty) {
        ref.invalidate(downloadedTracksProvider);
      }
    } catch (e) {
      print('Error processing favorites changes: $e');
    }
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _syncOfflineContent() async {
    final networkState = ref.read(networkProvider);
    if (networkState.isOffline) return; // Skip if offline

    try {
      final db = ref.read(databaseProvider);
      final activeServer = await ref.read(activeServerProvider.future);
      if (activeServer == null) return;
      
      final api = SubsonicApi(activeServer);
      final prefs = await db.getActiveOfflinePreferences();
      final downloadService = ref.read(downloadServiceProvider);
      
      final downloadedTracks = await db.getDownloadedTracks(activeServer.id);
      final downloadedIds = downloadedTracks
          .where((t) => t.isManualDownload && t.isComplete && File(t.localPath).existsSync())
          .map((t) => t.songId)
          .toSet();

      for (final pref in prefs) {
        if (pref.serverId != activeServer.id) continue;
        
        List<dynamic> targetSongs = [];
        if (pref.type == 'favorites') {
          final favoritesCache = await db.getFavorites(activeServer.id);
          for (final fav in favoritesCache) {
            if (fav.itemType == 'song') {
              // Usually the songs are grouped into a JSON object inside favorites
              // Wait, the favorites are stored as individual items or a single JSON?
              // Let's check how favoritesProvider fetches them. It gets from api.getStarred() or cache.
              // Actually we can just fetch from API to ensure we have the latest.
              try {
                final favorites = await api.getStarred();
                targetSongs = favorites['songs'] ?? [];
              } catch (e) {
                print('Background sync failed to fetch favorites: $e');
              }
              break;
            }
          }
        } else if (pref.type == 'album') {
          try {
            final albumDetail = await api.getAlbum(pref.targetId);
            if (albumDetail != null) {
              var songs = albumDetail['song'];
              if (songs != null) {
                if (songs is! List) songs = [songs];
                targetSongs = songs;
              }
            }
          } catch (e) {
            print('Background sync failed to fetch album ${pref.targetId}: $e');
          }
        }

        // Check if any of these songs are missing from downloads
        for (final song in targetSongs) {
          final songId = song['id'].toString();
          if (!downloadedIds.contains(songId)) {
            // Not downloaded or incomplete, trigger download
            try {
              await downloadService.downloadSong(song, activeServer.id);
            } catch (e) {
              print('Background sync failed to download song $songId: $e');
            }
          }
        }
      }
      
      // Invalidate provider so UI updates if there were any changes
      ref.invalidate(downloadedTracksProvider);
      
    } catch (e) {
      print('Background sync error: $e');
    }
  }
}

final backgroundSyncServiceProvider = Provider<BackgroundSyncService>((ref) {
  return BackgroundSyncService(ref);
});
