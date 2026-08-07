import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenify/providers/theme_provider.dart';
import 'package:zenify/models/downloaded_track.dart';
import 'package:zenify/providers/app_providers.dart';
import 'package:zenify/services/download_service.dart';

final downloadProgressProvider = StateProvider<Map<String, double>>((ref) => {});

class ShowCachedDownloadsNotifier extends Notifier<bool> {
  static const _key = 'show_cached_downloads';

  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool(_key) ?? false;
  }

  void toggle() {
    final prefs = ref.read(sharedPreferencesProvider);
    state = !state;
    prefs.setBool(_key, state);
  }
}

final showCachedDownloadsProvider = NotifierProvider<ShowCachedDownloadsNotifier, bool>(() {
  return ShowCachedDownloadsNotifier();
});

final downloadedTracksProvider = FutureProvider<List<DownloadedTrack>>((ref) async {
  final serverAsyncValue = ref.watch(activeServerProvider);
  if (!serverAsyncValue.hasValue || serverAsyncValue.value == null) return [];
  
  final db = ref.watch(databaseProvider);
  return await db.getDownloadedTracks(serverAsyncValue.value!.id);
});

final downloadServiceProvider = Provider<DownloadService>((ref) {
  final db = ref.watch(databaseProvider);
  final api = ref.watch(subsonicApiProvider);
  final cacheLimit = ref.watch(cacheLimitProvider);
  
  return DownloadService(
    db, 
    api,
    cacheLimit,
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
