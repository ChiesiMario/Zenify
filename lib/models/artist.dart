import 'package:isar/isar.dart';

part 'artist.g.dart';

@collection
class Artist {
  Id id = Isar.autoIncrement;

  @Index(composite: [CompositeIndex('serverId')], unique: true, replace: true)
  late String artistId;

  late int serverId;

  String? name;
  String? coverArt;
  int? albumCount;

  // Save the raw JSON string so we can easily convert it back to dynamic map
  late String rawData;
}
