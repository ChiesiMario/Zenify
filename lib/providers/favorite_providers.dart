import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenify/providers/server_providers.dart';
import 'package:zenify/providers/network_provider.dart';

final favoritesProvider = FutureProvider<Map<String, List<dynamic>>>((ref) async {
  final networkState = ref.watch(networkProvider);
  
  if (networkState.isOffline) {
    final server = await ref.watch(activeServerProvider.future);
    if (server == null) {
      return {'artists': [], 'albums': [], 'songs': []};
    }
    final db = ref.read(databaseProvider);
    final favs = await db.getFavorites(server.id);
    
    List<dynamic> artists = [];
    List<dynamic> albums = [];
    List<dynamic> songs = [];
    
    for (var f in favs) {
      try {
        final decoded = jsonDecode(f.rawData);
        if (f.itemType == 'artist') {
          artists.add(decoded);
        } else if (f.itemType == 'album') albums.add(decoded);
        else if (f.itemType == 'song') songs.add(decoded);
      } catch (_) {}
    }
    
    return {'artists': artists, 'albums': albums, 'songs': songs};
  }

  final api = ref.watch(subsonicApiProvider);
  if (api == null) return {'artists': [], 'albums': [], 'songs': []};
  return await api.getStarred();
});
