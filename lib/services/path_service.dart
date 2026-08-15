import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;

class PathService {
  static const String customDownloadRootKey = 'custom_download_root_path';
  static bool _hasMigrated = false;

  /// Ensure we migrate old files from Documents to AppData before anything else runs.
  static Future<void> ensureInitialized() async {
    if (_hasMigrated) return;
    await _migrateDocumentsToSupportDir();
    // Ensure Offline folder exists even if empty
    await getOfflineDir();
    _hasMigrated = true;
  }

  /// Gets the core Application Support directory (AppData)
  static Future<Directory> getSupportDir() async {
    return await getApplicationSupportDirectory();
  }

  /// Gets the user's defined root for downloads & cache.
  /// Defaults to system's Downloads directory.
  static Future<String> getRootDownloadPath() async {
    final prefs = await SharedPreferences.getInstance();
    final customPath = prefs.getString(customDownloadRootKey);
    if (customPath != null && customPath.isNotEmpty) {
      return customPath;
    }
    final systemDownloads = await getDownloadsDirectory();
    if (systemDownloads != null) {
      return systemDownloads.path;
    }
    // Fallback if getDownloadsDirectory is unsupported on this OS
    final docDir = await getApplicationDocumentsDirectory();
    return docDir.path;
  }

  /// Sets a new root download path and migrates existing files to the new location.
  static Future<void> setRootDownloadPath(String newRoot, {void Function(int current, int total)? onProgress}) async {
    final currentRoot = await getRootDownloadPath();
    if (currentRoot == newRoot) return;

    final oldOfflineDir = Directory(p.join(currentRoot, 'Zenify', 'Offline'));
    final newOfflineDir = Directory(p.join(newRoot, 'Zenify', 'Offline'));

    if (!await newOfflineDir.exists()) await newOfflineDir.create(recursive: true);

    if (await oldOfflineDir.exists()) {
      int totalFiles = 0;
      final allEntities = oldOfflineDir.listSync(recursive: true);
      for (var e in allEntities) {
        if (e is File) totalFiles++;
      }
      
      final progressRef = [0, totalFiles];
      if (onProgress != null && totalFiles > 0) {
        onProgress(0, totalFiles);
      }

      await _moveDirectory(oldOfflineDir, newOfflineDir, progressRef: progressRef, onProgress: onProgress);
    }

    // Attempt to remove old Zenify folder if empty
    final oldZenifyDir = Directory(p.join(currentRoot, 'Zenify'));
    if (await oldZenifyDir.exists()) {
      try {
        await oldZenifyDir.delete();
      } catch (_) {}
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(customDownloadRootKey, newRoot);
  }

  /// Gets the path for offline and cache files
  static Future<Directory> getOfflineDir() async {
    final root = await getRootDownloadPath();
    final dir = Directory(p.join(root, 'Zenify', 'Offline'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Move contents from one directory to another
  static Future<void> _moveDirectory(Directory source, Directory destination, {
    List<int>? progressRef, 
    void Function(int, int)? onProgress
  }) async {
    final entities = source.listSync(recursive: false);
    for (var entity in entities) {
      final newPath = p.join(destination.path, p.basename(entity.path));
      if (entity is File) {
        try {
          await entity.rename(newPath);
        } catch (e) {
          // If rename fails (cross-device link), use copy and delete
          await entity.copy(newPath);
          await entity.delete();
        }
        if (progressRef != null && progressRef.length == 2) {
          progressRef[0]++;
          if (onProgress != null) onProgress(progressRef[0], progressRef[1]);
        }
      } else if (entity is Directory) {
        final newDir = Directory(newPath);
        if (!await newDir.exists()) await newDir.create(recursive: true);
        await _moveDirectory(entity, newDir, progressRef: progressRef, onProgress: onProgress);
      }
    }
    try {
      await source.delete();
    } catch (_) {}
  }

  /// Internal migration from Documents to AppData
  static Future<void> _migrateDocumentsToSupportDir() async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final supportDir = await getApplicationSupportDirectory();

      final oldIsarFile = File(p.join(docDir.path, 'default.isar'));
      final oldIsarLockFile = File(p.join(docDir.path, 'default.isar.lock'));
      final oldCoversDir = Directory(p.join(docDir.path, 'covers'));

      final newIsarFile = File(p.join(supportDir.path, 'default.isar'));
      final newIsarLockFile = File(p.join(supportDir.path, 'default.isar.lock'));
      final newCoversDir = Directory(p.join(supportDir.path, 'covers'));

      if (await oldIsarFile.exists() && !await newIsarFile.exists()) {
        try {
          await oldIsarFile.rename(newIsarFile.path);
        } catch (_) {
          await oldIsarFile.copy(newIsarFile.path);
          await oldIsarFile.delete();
        }
      }

      if (await oldIsarLockFile.exists() && !await newIsarLockFile.exists()) {
        try {
          await oldIsarLockFile.rename(newIsarLockFile.path);
        } catch (_) {
          await oldIsarLockFile.copy(newIsarLockFile.path);
          await oldIsarLockFile.delete();
        }
      }

      if (await oldCoversDir.exists() && !await newCoversDir.exists()) {
        await _moveDirectory(oldCoversDir, newCoversDir);
      }

      // Also migrate the old zenify_downloads to Zenify/Downloads
      final oldDownloadsDir = Directory(p.join(docDir.path, 'zenify_downloads'));
      if (await oldDownloadsDir.exists()) {
        final root = await getRootDownloadPath();
        final newRootDownloadsDir = Directory(p.join(root, 'Zenify', 'Downloads'));
        if (!await newRootDownloadsDir.exists()) await newRootDownloadsDir.create(recursive: true);
        await _moveDirectory(oldDownloadsDir, newRootDownloadsDir);
      }

      // Migrate old just_audio_cache if exists in temp
      final tempDir = await getTemporaryDirectory();
      final oldAudioCacheDir = Directory(p.join(tempDir.path, 'just_audio_cache'));
      if (await oldAudioCacheDir.exists()) {
        final root = await getRootDownloadPath();
        final newRootCacheDir = Directory(p.join(root, 'Zenify', 'Cache'));
        if (!await newRootCacheDir.exists()) await newRootCacheDir.create(recursive: true);
        await _moveDirectory(oldAudioCacheDir, newRootCacheDir);
      }
    } catch (e) {
      debugPrint('Migration error: $e');
    }
  }
}
