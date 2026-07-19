import 'package:isar/isar.dart';

part 'album.g.dart';

@collection
class Album {
  Id id = Isar.autoIncrement;

  @Index(composite: [CompositeIndex('serverId')], unique: true, replace: true)
  late String albumId;

  late int serverId;

  String? name;
  String? artist;
  String? artistId;
  int? songCount;
  int? duration;
  int? year;
  String? coverArt;
  
  // Save the raw JSON string so we can easily convert it back to dynamic map
  late String rawData;
}
