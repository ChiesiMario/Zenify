import 'package:isar/isar.dart';

part 'album_detail_cache.g.dart';

@collection
class AlbumDetailCache {
  Id id = Isar.autoIncrement;

  late int serverId;
  
  @Index(composite: [CompositeIndex('serverId')], unique: true, replace: true)
  late String albumId;
  
  /// The complete raw JSON of the album (including its 'song' list if fetched via getAlbum)
  late String rawData;
}
