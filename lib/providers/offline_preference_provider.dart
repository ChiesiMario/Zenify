import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:zenify/models/offline_preference.dart';
import 'package:zenify/providers/app_providers.dart';

class OfflinePreferenceState {
  final Map<String, bool> albumPreferences;
  final bool favoritesPreference;

  OfflinePreferenceState({
    this.albumPreferences = const {},
    this.favoritesPreference = false,
  });

  OfflinePreferenceState copyWith({
    Map<String, bool>? albumPreferences,
    bool? favoritesPreference,
  }) {
    return OfflinePreferenceState(
      albumPreferences: albumPreferences ?? this.albumPreferences,
      favoritesPreference: favoritesPreference ?? this.favoritesPreference,
    );
  }
}

class OfflinePreferenceNotifier extends StateNotifier<AsyncValue<OfflinePreferenceState>> {
  final Ref ref;

  OfflinePreferenceNotifier(this.ref) : super(const AsyncValue.loading()) {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final db = ref.read(databaseProvider);
      final activeServer = await ref.read(activeServerProvider.future);
      if (activeServer == null) {
        state = AsyncValue.data(OfflinePreferenceState());
        return;
      }

      final prefs = await db.getActiveOfflinePreferences();
      final albumPrefs = <String, bool>{};
      bool favPref = false;

      for (final pref in prefs) {
        if (pref.serverId == activeServer.id) {
          if (pref.type == 'favorites') {
            favPref = pref.isOffline;
          } else if (pref.type == 'album') {
            albumPrefs[pref.targetId] = pref.isOffline;
          }
        }
      }

      state = AsyncValue.data(OfflinePreferenceState(
        albumPreferences: albumPrefs,
        favoritesPreference: favPref,
      ));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> setFavoritesOffline(bool isOffline) async {
    try {
      final db = ref.read(databaseProvider);
      final activeServer = await ref.read(activeServerProvider.future);
      if (activeServer == null) return;

      var pref = await db.getOfflinePreference(activeServer.id, 'favorites', 'favorites');
      if (pref == null) {
        pref = OfflinePreference()
          ..serverId = activeServer.id
          ..type = 'favorites'
          ..targetId = 'favorites'
          ..isOffline = isOffline;
      } else {
        pref.isOffline = isOffline;
      }
      
      await db.saveOfflinePreference(pref);
      
      // Update state
      final currentState = state.valueOrNull ?? OfflinePreferenceState();
      state = AsyncValue.data(currentState.copyWith(favoritesPreference: isOffline));
    } catch (e) {
      debugPrint('Error saving favorites offline preference: $e');
    }
  }

  Future<void> setAlbumOffline(String albumId, bool isOffline) async {
    try {
      final db = ref.read(databaseProvider);
      final activeServer = await ref.read(activeServerProvider.future);
      if (activeServer == null) return;

      var pref = await db.getOfflinePreference(activeServer.id, 'album', albumId);
      if (pref == null) {
        pref = OfflinePreference()
          ..serverId = activeServer.id
          ..type = 'album'
          ..targetId = albumId
          ..isOffline = isOffline;
      } else {
        pref.isOffline = isOffline;
      }
      
      await db.saveOfflinePreference(pref);
      
      // Update state
      final currentState = state.valueOrNull ?? OfflinePreferenceState();
      final newAlbumPrefs = Map<String, bool>.from(currentState.albumPreferences);
      newAlbumPrefs[albumId] = isOffline;
      state = AsyncValue.data(currentState.copyWith(albumPreferences: newAlbumPrefs));
    } catch (e) {
      debugPrint('Error saving album offline preference: $e');
    }
  }
}

final offlinePreferenceProvider = StateNotifierProvider<OfflinePreferenceNotifier, AsyncValue<OfflinePreferenceState>>((ref) {
  return OfflinePreferenceNotifier(ref);
});
