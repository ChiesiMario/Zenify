import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:zenify/models/server.dart';

class DatabaseService {
  late Future<Isar> db;

  DatabaseService() {
    db = openDB();
  }

  Future<Isar> openDB() async {
    if (Isar.instanceNames.isEmpty) {
      final dir = await getApplicationDocumentsDirectory();
      return await Isar.open(
        [ServerSchema],
        directory: dir.path,
        inspector: true,
      );
    }
    return Future.value(Isar.getInstance());
  }

  /// Get all servers
  Future<List<Server>> getServers() async {
    final isar = await db;
    return await isar.servers.where().findAll();
  }

  /// Add or Update a server
  Future<void> saveServer(Server server) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.servers.put(server);
    });
  }

  /// Delete a server
  Future<void> deleteServer(int id) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.servers.delete(id);
    });
  }

  /// Get currently active server
  Future<Server?> getActiveServer() async {
    final isar = await db;
    return await isar.servers.filter().isActiveEqualTo(true).findFirst();
  }

  /// Set a server as active (and deactivate others)
  Future<void> setActiveServer(int id) async {
    final isar = await db;
    final servers = await isar.servers.where().findAll();
    
    await isar.writeTxn(() async {
      for (var server in servers) {
        if (server.id == id) {
          server.isActive = true;
        } else {
          server.isActive = false;
        }
        await isar.servers.put(server);
      }
    });
  }
}
