import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:zenify/models/album.dart';
import 'package:zenify/models/artist.dart';
import 'package:zenify/models/server.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open(
    [ServerSchema, AlbumSchema, ArtistSchema],
    directory: dir.path,
    inspector: true,
  );

  final albums = await isar.albums.where().findAll();
  
  Map<String, int> nameCounts = {};
  for (var album in albums) {
    final name = album.name ?? 'Unknown';
    nameCounts[name] = (nameCounts[name] ?? 0) + 1;
  }
  
  print('Total albums in DB: ${albums.length}');
  
  print('Albums with duplicates names:');
  for (var entry in nameCounts.entries) {
    if (entry.value > 1) {
      print('  ${entry.key}: ${entry.value}');
    }
  }

  // check if there are duplicate albumIds
  Map<String, int> idCounts = {};
  for (var album in albums) {
    final id = album.albumId ?? 'Unknown';
    idCounts[id] = (idCounts[id] ?? 0) + 1;
  }
  
  print('Albums with duplicates IDs:');
  for (var entry in idCounts.entries) {
    if (entry.value > 1) {
      print('  ${entry.key}: ${entry.value}');
    }
  }

  exit(0);
}
