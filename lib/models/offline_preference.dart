import 'package:isar/isar.dart';

part 'offline_preference.g.dart';

@collection
class OfflinePreference {
  Id id = Isar.autoIncrement;

  @Index(composite: [CompositeIndex('type'), CompositeIndex('targetId')], unique: true, replace: true)
  late int serverId;

  /// Type of the preference: 'album', 'favorites', etc.
  late String type;

  /// The target ID: 'favorites' for favorite songs, or the album ID
  late String targetId;

  /// Whether offline is enabled
  late bool isOffline;
}
