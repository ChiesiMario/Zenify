import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenify/api/subsonic_api.dart';
import 'package:zenify/providers/favorite_providers.dart';

final favoriteStatusProvider = StateNotifierProvider<FavoriteStatusNotifier, Map<String, bool>>((ref) {
  return FavoriteStatusNotifier(ref);
});

class FavoriteStatusNotifier extends StateNotifier<Map<String, bool>> {
  final Ref ref;

  FavoriteStatusNotifier(this.ref) : super({});

  Future<void> toggleStar({
    required String id,
    required bool isCurrentlyStarred,
    required SubsonicApi api,
    bool isAlbum = false,
  }) async {
    // Optimistic Update
    state = {...state, id: !isCurrentlyStarred};
    
    try {
      if (!isCurrentlyStarred) {
        if (isAlbum) {
          await api.star(albumId: id);
        } else {
          await api.star(id: id);
        }
      } else {
        if (isAlbum) {
          await api.unstar(albumId: id);
        } else {
          await api.unstar(id: id);
        }
      }

      // Refresh favoritesProvider so the newly starred/unstarred item is reflected immediately
      ref.invalidate(favoritesProvider);
    } catch (e) {
      print('Failed to toggle star: $e');
      // Revert state on failure
      state = {...state, id: isCurrentlyStarred};
    }
  }

  void updateStatusLocally(String id, bool isStarred) {
    if (state[id] != isStarred) {
      state = {...state, id: isStarred};
    }
  }
}
