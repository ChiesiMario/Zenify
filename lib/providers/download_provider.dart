import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenify/models/downloaded_track.dart';
import 'package:zenify/providers/app_providers.dart';
import 'package:zenify/services/download_service.dart';

final downloadProgressProvider = StateProvider<Map<String, double>>((ref) => {});

final downloadedTracksProvider = FutureProvider<List<DownloadedTrack>>((ref) async {
  final serverAsyncValue = ref.watch(activeServerProvider);
  if (!serverAsyncValue.hasValue || serverAsyncValue.value == null) return [];
  
  final db = ref.watch(databaseProvider);
  return await db.getDownloadedTracks(serverAsyncValue.value!.id);
});

final downloadServiceProvider = Provider<DownloadService>((ref) {
  final db = ref.watch(databaseProvider);
  final api = ref.watch(subsonicApiProvider);
  
  return DownloadService(
    db, 
    api,
    onProgress: (songId, progress) {
      final currentMap = ref.read(downloadProgressProvider);
      ref.read(downloadProgressProvider.notifier).state = {
        ...currentMap,
        songId: progress,
      };
      
      if (progress >= 1.0) {
        // Refresh downloaded tracks list when complete
        ref.invalidate(downloadedTracksProvider);
      }
    },
  );
});
