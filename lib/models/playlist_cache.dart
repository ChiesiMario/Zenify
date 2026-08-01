import 'package:isar/isar.dart';

part 'playlist_cache.g.dart';

@collection
class PlaylistCache {
  Id id = Isar.autoIncrement;

  late int serverId;
  
  @Index()
  late String playlistId;
  
  late String name;
  
  /// The complete raw JSON of the playlist (including its tracks if getPlaylist was called)
  late String rawData;
}
