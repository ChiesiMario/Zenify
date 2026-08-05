import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:rxdart/rxdart.dart';
import 'package:zenify/services/path_service.dart';

class AudioCacheProxy {
  static final AudioCacheProxy _instance = AudioCacheProxy._internal();
  factory AudioCacheProxy() => _instance;
  AudioCacheProxy._internal();

  HttpServer? _server;
  int get port => _server?.port ?? 0;
  final Map<String, BehaviorSubject<double>> _downloadProgress = {};

  Future<void> start() async {
    if (_server != null) return;
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    print('AudioCacheProxy running on localhost:${_server!.port}');
    _server!.listen(_handleRequest);
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }

  Stream<double> getDownloadProgress(String id) {
    if (!_downloadProgress.containsKey(id)) {
      _downloadProgress[id] = BehaviorSubject<double>.seeded(0.0);
    }
    return _downloadProgress[id]!.stream;
  }

  Future<File> _getCacheFile(String url) async {
    final offlineDir = await PathService.getOfflineDir();
    final uri = Uri.parse(url);
    final hash = sha256.convert(utf8.encode(url)).toString();
    final ext = p.extension(uri.path).isEmpty ? '.mp3' : p.extension(uri.path);
    return File(p.join(offlineDir.path, 'remote', '$hash$ext'));
  }

  String getProxyUrl(String originalUrl, String id) {
    final encodedUrl = Uri.encodeComponent(originalUrl);
    return 'http://127.0.0.1:$port/stream?url=$encodedUrl&id=$id';
  }

  Future<void> _handleRequest(HttpRequest request) async {
    try {
      final url = request.uri.queryParameters['url'];
      final id = request.uri.queryParameters['id'] ?? 'unknown';

      if (url == null) {
        request.response.statusCode = HttpStatus.badRequest;
        await request.response.close();
        return;
      }

      final cacheFile = await _getCacheFile(url);
      final rangeHeader = request.headers.value(HttpHeaders.rangeHeader);
      
      // Parse Range
      int? start;
      int? end;
      if (rangeHeader != null) {
        final match = RegExp(r'bytes=(\d+)-(\d*)').firstMatch(rangeHeader);
        if (match != null) {
          start = int.parse(match.group(1)!);
          if (match.group(2)!.isNotEmpty) {
            end = int.parse(match.group(2)!);
          }
        }
      }

      // If fully cached, serve from cache
      if (await cacheFile.exists()) {
        final fileLength = await cacheFile.length();
        final effectiveStart = start ?? 0;
        final effectiveEnd = end ?? (fileLength - 1);
        final contentLength = effectiveEnd - effectiveStart + 1;

        request.response.statusCode = start != null ? HttpStatus.partialContent : HttpStatus.ok;
        request.response.headers.set(HttpHeaders.acceptRangesHeader, 'bytes');
        request.response.headers.set(HttpHeaders.contentLengthHeader, contentLength.toString());
        request.response.headers.set(HttpHeaders.contentTypeHeader, _getMimeType(cacheFile.path));
        
        if (start != null) {
          request.response.headers.set(
            HttpHeaders.contentRangeHeader, 
            'bytes $effectiveStart-$effectiveEnd/$fileLength'
          );
        }
        
        await request.response.addStream(cacheFile.openRead(effectiveStart, effectiveEnd + 1));
        await request.response.close();
        
        if (!_downloadProgress.containsKey(id)) {
           _downloadProgress[id] = BehaviorSubject<double>.seeded(1.0);
        } else if (_downloadProgress[id]!.value != 1.0) {
           _downloadProgress[id]!.add(1.0);
        }
        return;
      }

      // If not cached, we need to proxy the request.
      // For simplicity in a basic proxy without complex partial caching logic,
      // if it's a range request, we just proxy directly to upstream.
      // If it's a full request (start == null || start == 0), we can cache it while streaming.
      
      final client = HttpClient();
      final upstreamRequest = await client.getUrl(Uri.parse(url));
      
      if (rangeHeader != null) {
        upstreamRequest.headers.set(HttpHeaders.rangeHeader, rangeHeader);
      }
      
      final upstreamResponse = await upstreamRequest.close();
      request.response.statusCode = upstreamResponse.statusCode;
      
      upstreamResponse.headers.forEach((name, values) {
        for (var value in values) {
          request.response.headers.add(name, value);
        }
      });

      if ((start == null || start == 0) && upstreamResponse.statusCode == HttpStatus.ok) {
        // Cache while streaming
        final partialFile = File('${cacheFile.path}.part');
        await partialFile.parent.create(recursive: true);
        final sink = partialFile.openWrite();
        
        final contentLength = upstreamResponse.contentLength;
        int downloaded = 0;
        
        if (!_downloadProgress.containsKey(id)) {
          _downloadProgress[id] = BehaviorSubject<double>.seeded(0.0);
        }

        upstreamResponse.listen((data) {
          request.response.add(data);
          sink.add(data);
          downloaded += data.length;
          if (contentLength > 0) {
            _downloadProgress[id]!.add(downloaded / contentLength);
          }
        }, onDone: () async {
          await sink.close();
          try {
            await partialFile.rename(cacheFile.path);
          } catch (e) {
            if (Platform.isWindows) {
              try {
                await partialFile.copy(cacheFile.path);
                await partialFile.delete();
              } catch (_) {}
            }
          }
          await request.response.close();
          _downloadProgress[id]!.add(1.0);
          client.close();
        }, onError: (e) async {
          await sink.close();
          try { await partialFile.delete(); } catch (_) {}
          request.response.addError(e);
          await request.response.close();
          client.close();
        });
      } else {
        // Just proxy stream
        await request.response.addStream(upstreamResponse);
        await request.response.close();
        client.close();
      }
      
    } catch (e) {
      try {
        request.response.statusCode = HttpStatus.internalServerError;
        await request.response.close();
      } catch (_) {}
    }
  }

  String _getMimeType(String path) {
    if (path.endsWith('.mp3')) return 'audio/mpeg';
    if (path.endsWith('.flac')) return 'audio/flac';
    if (path.endsWith('.m4a')) return 'audio/mp4';
    if (path.endsWith('.ogg')) return 'audio/ogg';
    return 'audio/mpeg'; // Default
  }
}
