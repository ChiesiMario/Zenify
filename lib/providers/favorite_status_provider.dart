import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenify/api/subsonic_api.dart';

final favoriteStatusProvider = StateNotifierProvider<FavoriteStatusNotifier, Map<String, bool>>((ref) {
  return FavoriteStatusNotifier();
});

class FavoriteStatusNotifier extends StateNotifier<Map<String, bool>> {
  FavoriteStatusNotifier() : super({});

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
