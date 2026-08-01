import 'package:isar/isar.dart';

part 'favorite_item.g.dart';

@collection
class FavoriteItem {
  Id id = Isar.autoIncrement;

  late int serverId;
  
  /// The subsonic ID of the item
  late String itemId;
  
  /// The type of item: 'song', 'album', 'artist'
  @Index()
  late String itemType;
  
  /// The raw JSON of the item
  late String rawData;

  /// The timestamp it was starred (useful for sorting if needed)
  DateTime? starredAt;
}
