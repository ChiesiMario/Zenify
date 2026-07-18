import 'package:isar/isar.dart';

part 'server.g.dart';

@collection
class Server {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String url;

  late String username;
  
  late String password; // In a real app, this should be stored securely or we should use a token/salt
  
  // To store the subsonic version or extra info
  String? version;
  
  bool isActive = false;
}
