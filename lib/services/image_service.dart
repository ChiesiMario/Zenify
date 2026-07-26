import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:zenify/services/path_service.dart';
import 'package:path/path.dart' as p;

class ImageService {
  static final ImageService _instance = ImageService._internal();
  factory ImageService() => _instance;
  ImageService._internal();

  String? _coversDirPath;
  final Map<String, Future<bool>> _activeDownloads = {};
  final Set<String> _cachedFileNames = {};

  Future<void> init() async {
    if (_coversDirPath == null) {
      await PathService.ensureInitialized();
      final dir = await PathService.getSupportDir();
      final coversDir = Directory(p.join(dir.path, 'covers'));
      if (!await coversDir.exists()) {
        await coversDir.create(recursive: true);
      }
      _coversDirPath = coversDir.path;
      await _scanExistingFiles();
    }
  }

  Future<void> _scanExistingFiles() async {
    try {
      final dir = Directory(_coversDirPath!);
      if (await dir.exists()) {
        // recursively scan since they are now in subfolders
        await for (var entity in dir.list(recursive: true)) {
          if (entity is File) {
            final segments = p.split(entity.path);
            if (segments.length >= 2) {
              final serverIdStr = segments[segments.length - 2];
              final filename = segments.last;
              _cachedFileNames.add('${serverIdStr}_$filename');
            }
          }
        }
      }
    } catch (_) {}
  }

  Future<String> getCoverPath(String id, int serverId, {bool isThumb = false}) async {
    await init();
    return getCoverPathSync(id, serverId, isThumb: isThumb);
  }

  String getCoverPathSync(String id, int serverId, {bool isThumb = false}) {
    if (_coversDirPath == null) {
      throw Exception("ImageService not initialized");
    }
    final suffix = isThumb ? '_thumb' : '_full';
    final serverDir = Directory(p.join(_coversDirPath!, serverId.toString()));
    if (!serverDir.existsSync()) {
      serverDir.createSync(recursive: true);
    }
    return p.join(serverDir.path, '$id$suffix.jpg');
  }

  Future<bool> isCoverCached(String id, int serverId, {bool isThumb = false}) async {
    return isCoverCachedSync(id, serverId, isThumb: isThumb);
  }

  bool isCoverCachedSync(String id, int serverId, {bool isThumb = false}) {
    if (_coversDirPath == null) return false;
    final suffix = isThumb ? '_thumb' : '_full';
    final cacheKey = '${serverId}_$id$suffix.jpg';
    return _cachedFileNames.contains(cacheKey);
  }

  /// 下載圖片並儲存至本地，最多重試 3 次，防止重複下載
  Future<bool> downloadImage(String url, String id, int serverId, {bool isThumb = false}) async {
    final suffix = isThumb ? '_thumb' : '_full';
    final cacheKey = '${serverId}_$id$suffix';
    
    if (_activeDownloads.containsKey(cacheKey)) {
      return _activeDownloads[cacheKey]!;
    }

    final downloadFuture = _performDownload(url, id, serverId, isThumb);
    _activeDownloads[cacheKey] = downloadFuture;

    try {
      return await downloadFuture;
    } finally {
      _activeDownloads.remove(cacheKey);
    }
  }

  Future<bool> _performDownload(String url, String id, int serverId, bool isThumb) async {
    final path = await getCoverPath(id, serverId, isThumb: isThumb);
    final file = File(path);

    if (await file.exists()) {
      return true; // 已存在則不需下載
    }

    int retryCount = 0;
    while (retryCount < 3) {
      try {
        final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
        if (response.statusCode == 200) {
          await file.writeAsBytes(response.bodyBytes);
          _cachedFileNames.add('${serverId}_${file.uri.pathSegments.last}');
          return true;
        }
      } catch (e) {
        // 忽略錯誤，進行下一次重試
      }
      retryCount++;
      if (retryCount < 3) {
        await Future.delayed(Duration(seconds: retryCount)); // 指數退避重試
      }
    }
    return false;
  }

  /// 取得本地已經下載的封面實體檔案數量 (可指定特定伺服器)
  Future<int> getDownloadedCoverCount(int serverId) async {
    await init();
    final dir = Directory(_coversDirPath!);
    final serverDir = Directory(p.join(_coversDirPath!, serverId.toString()));
    if (!await serverDir.exists()) return 0;
    
    int count = 0;
    await for (var entity in serverDir.list()) {
      if (entity is File && entity.uri.pathSegments.last.endsWith('.jpg')) {
        count++;
      }
    }
    return count;
  }
}
