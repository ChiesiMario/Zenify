import 'package:flutter_riverpod/flutter_riverpod.dart';

final downloadsTabProvider = StateProvider<int>((ref) => 0);

class NavigationRequest {
  final String type; // 'artist' or 'album'
  final String id;
  final String name;
  
  NavigationRequest({required this.type, required this.id, required this.name});
}

final navigationRequestProvider = StateProvider<NavigationRequest?>((ref) => null);

final activePopoverSongIdProvider = StateProvider<String?>((ref) => null);
