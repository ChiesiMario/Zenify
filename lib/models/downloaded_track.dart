import 'package:isar/isar.dart';

part 'downloaded_track.g.dart';

@collection
class DownloadedTrack {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String songId;

  late int serverId;

  late String title;
  late String artist;
  String? album;
  String? albumId;
  String? coverArt;
  
  late int duration;
  late String localPath;
  late int sizeBytes;
  late DateTime downloadedAt;

  // Save the raw JSON string so we can easily convert it back to dynamic map
  late String rawData;

  bool isComplete = true; // Indicates whether the download finished
}
