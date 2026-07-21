import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';

class _HttpRangeRequest {
  final int start;
  final int? end;

  int? get endEx => end == null ? null : end! + 1;

  _HttpRangeRequest(this.start, this.end);

  String get header =>
      'bytes=$start-${end != null ? (end! - 1).toString() : ""}';

  static _HttpRangeRequest? parse(List<String>? header) {
    if (header == null || header.isEmpty) return null;
    final match = RegExp(r'^bytes=(\d+)(-(\d+)?)?').firstMatch(header.first);
    if (match == null) return null;
    int? intGroup(int i) => match[i] != null ? int.parse(match[i]!) : null;
    return _HttpRangeRequest(intGroup(1)!, intGroup(3));
  }
}

class _HttpRangeResponse {
  final int start;
  final int end;
  final int? fullLength;

  _HttpRangeResponse(this.start, this.end, this.fullLength);

  int? get endEx => end + 1;
  int? get length => endEx == null ? null : endEx! - start;
  String get header => 'bytes $start-$end/${fullLength?.toString() ?? "*"}';
}

Future<HttpClientRequest> _getUrl(HttpClient client, Uri uri,
    {Map<String, String>? headers}) async {
  final request = await client.getUrl(uri);
  if (headers != null) {
    final host = request.headers.value(HttpHeaders.hostHeader);
    request.headers.clear();
    request.headers.set(HttpHeaders.contentLengthHeader, '0');
    headers.forEach((name, value) => request.headers.set(name, value));
    if (host != null) {
      request.headers.set(HttpHeaders.hostHeader, host);
    }
    if (client.userAgent != null) {
      request.headers.set(HttpHeaders.userAgentHeader, client.userAgent!);
    }
  }
  request.maxRedirects = 20;
  return request;
}

HttpClient _createHttpClient({String? userAgent}) {
  final client = HttpClient();
  if (userAgent != null) {
    client.userAgent = userAgent;
  }
  return client;
}

class _InProgressCacheResponse {
  final controller = ReplaySubject<List<int>>();
  final int? end;
  _InProgressCacheResponse({
    required this.end,
  });
}

class _StreamingByteRangeRequest {
  final int? start;
  final int? end;
  final _completer = Completer<StreamAudioResponse>();

  _StreamingByteRangeRequest(this.start, this.end);

  Future<StreamAudioResponse> get future => _completer.future;

  void complete(StreamAudioResponse response) {
    if (_completer.isCompleted) return;
    _completer.complete(response);
  }

  void fail(dynamic error, [StackTrace? stackTrace]) {
    if (_completer.isCompleted) return;
    _completer.completeError(error as Object, stackTrace);
  }
}

Future<Directory> _getCacheDir() async =>
    Directory(p.join((await getTemporaryDirectory()).path, 'just_audio_cache'));

class ZenifyCachingAudioSource extends StreamAudioSource {
  Future<HttpClientResponse>? _response;
  final Uri uri;
  final Map<String, String>? headers;
  final Future<File> cacheFile;
  int _progress = 0;
  final _requests = <_StreamingByteRangeRequest>[];
  final _downloadProgressSubject = BehaviorSubject<double>();
  bool _downloading = false;
  final String? _userAgent;

  ZenifyCachingAudioSource(
    this.uri, {
    this.headers,
    File? cacheFile,
    dynamic tag,
    String? userAgent,
  })  : cacheFile =
            cacheFile != null ? Future.value(cacheFile) : _getCacheFile(uri),
        _userAgent = userAgent,
        super(tag: tag) {
    _init();
  }

  Future<void> _init() async {
    final file = await cacheFile;
    _downloadProgressSubject.add((await file.exists()) ? 1.0 : 0.0);
  }

  Future<IndexedAudioSource> resolve() async {
    final file = await cacheFile;
    return await file.exists() ? AudioSource.uri(Uri.file(file.path)) : this;
  }

  Stream<double> get downloadProgressStream => _downloadProgressSubject.stream;

  Future<void> clearCache() async {
    if (_downloading) {
      throw Exception("Cannot clear cache while download is in progress");
    }
    _response = null;
    final file = await this.cacheFile;
    if (await file.exists()) {
      await file.delete();
    }
    final mimeFile = await _mimeFile;
    if (await mimeFile.exists()) {
      await mimeFile.delete();
    }
    _progress = 0;
    _downloadProgressSubject.add(0.0);
  }

  static Future<File> _getCacheFile(final Uri uri) async => File(p.joinAll([
        (await _getCacheDir()).path,
        'remote',
        sha256.convert(utf8.encode(uri.toString())).toString() +
            p.extension(uri.path),
      ]));

  Future<File> get _partialCacheFile async =>
      File('${(await cacheFile).path}.part');

  Future<File> get _mimeFile async => File('${(await cacheFile).path}.mime');

  Future<String> _readCachedMimeType() async {
    final file = await _mimeFile;
    if (file.existsSync()) {
      return (await _mimeFile).readAsString();
    } else {
      return 'audio/mpeg';
    }
  }

  Future<HttpClientResponse> _fetch() async {
    _downloading = true;
    final cacheFile = await this.cacheFile;
    final partialCacheFile = await _partialCacheFile;

    File getEffectiveCacheFile() =>
        partialCacheFile.existsSync() ? partialCacheFile : cacheFile;

    final httpClient = _createHttpClient(userAgent: _userAgent);
    final httpRequest = await _getUrl(httpClient, uri, headers: headers);
    final response = await httpRequest.close();
    if (response.statusCode != 200) {
      httpClient.close();
      throw Exception('HTTP Status Error: ${response.statusCode}');
    }
    (await _partialCacheFile).createSync(recursive: true);
    final sink = (await _partialCacheFile).openWrite();
    final sourceLength =
        response.contentLength == -1 ? null : response.contentLength;
    final mimeType = response.headers.contentType.toString();
    final acceptRanges = response.headers.value(HttpHeaders.acceptRangesHeader);
    final originSupportsRangeRequests =
        acceptRanges != null && acceptRanges != 'none';
    final mimeFile = await _mimeFile;
    await mimeFile.writeAsString(mimeType);
    final inProgressResponses = <_InProgressCacheResponse>[];
    late StreamSubscription<List<int>> subscription;
    var percentProgress = 0;
    void updateProgress(int newPercentProgress) {
      if (newPercentProgress != percentProgress) {
        percentProgress = newPercentProgress;
        _downloadProgressSubject.add(percentProgress / 100);
      }
    }

    _progress = 0;
    subscription = response.listen((data) async {
      _progress += data.length;
      final newPercentProgress = (sourceLength == null)
          ? 0
          : (sourceLength == 0)
              ? 100
              : (100 * _progress ~/ sourceLength);
      updateProgress(newPercentProgress);
      sink.add(data);
      final readyRequests = _requests
          .where((request) =>
              !originSupportsRangeRequests ||
              request.start == null ||
              (request.start!) < _progress)
          .toList();
      final notReadyRequests = _requests
          .where((request) =>
              originSupportsRangeRequests &&
              request.start != null &&
              (request.start!) >= _progress)
          .toList();
      for (var cacheResponse in inProgressResponses) {
        final end = cacheResponse.end;
        if (end != null && _progress >= end) {
          final subEnd =
              min(data.length, max(0, data.length - (_progress - end)));
          cacheResponse.controller.add(data.sublist(0, subEnd));
          cacheResponse.controller.close();
        } else {
          cacheResponse.controller.add(data);
        }
      }
      inProgressResponses.removeWhere((element) => element.controller.isClosed);
      if (_requests.isEmpty) return;
      subscription.pause();
      await sink.flush();
      for (var request in readyRequests) {
        _requests.remove(request);
        int? start, end;
        if (originSupportsRangeRequests) {
          start = request.start;
          end = request.end;
        }
        final effectiveStart = start ?? 0;
        final effectiveEnd = end ?? sourceLength;
        Stream<List<int>> responseStream;
        if (effectiveEnd != null && effectiveEnd <= _progress) {
          responseStream =
              getEffectiveCacheFile().openRead(effectiveStart, effectiveEnd);
        } else {
          final cacheResponse = _InProgressCacheResponse(end: effectiveEnd);
          inProgressResponses.add(cacheResponse);
          responseStream = Rx.concatEager([
            getEffectiveCacheFile().openRead(effectiveStart, _progress),
            cacheResponse.controller.stream,
          ]);
        }
        request.complete(StreamAudioResponse(
          rangeRequestsSupported: originSupportsRangeRequests,
          sourceLength: start != null ? sourceLength : null,
          contentLength:
              effectiveEnd != null ? effectiveEnd - effectiveStart : null,
          offset: start,
          contentType: mimeType,
          stream: responseStream.asBroadcastStream(),
        ));
      }
      subscription.resume();
      for (var request in notReadyRequests) {
        _requests.remove(request);
        final start = request.start!;
        final end = request.end ?? sourceLength;
        final httpClient = _createHttpClient(userAgent: _userAgent);

        final rangeRequest = _HttpRangeRequest(start, end);
        _getUrl(httpClient, uri, headers: {
          if (headers != null) ...headers!,
          HttpHeaders.rangeHeader: rangeRequest.header,
        }).then((httpRequest) async {
          final response = await httpRequest.close();
          if (response.statusCode != 206) {
            httpClient.close();
            throw Exception('HTTP Status Error: ${response.statusCode}');
          }
          request.complete(StreamAudioResponse(
            rangeRequestsSupported: originSupportsRangeRequests,
            sourceLength: sourceLength,
            contentLength: end != null ? end - start : null,
            offset: start,
            contentType: mimeType,
            stream: response.asBroadcastStream(),
          ));
        }, onError: (dynamic e, StackTrace? stackTrace) {
          request.fail(e, stackTrace);
        }).onError((Object e, StackTrace st) {
          request.fail(e, st);
        });
      }
    }, onDone: () async {
      if (sourceLength == null) {
        updateProgress(100);
      }
      for (var cacheResponse in inProgressResponses) {
        if (!cacheResponse.controller.isClosed) {
          cacheResponse.controller.close();
        }
      }
      await sink.flush();
      await sink.close(); // Close sink properly before rename
      
      try {
        (await _partialCacheFile).renameSync(cacheFile.path);
      } catch (e) {
        if (Platform.isWindows) {
           try {
              (await _partialCacheFile).copySync(cacheFile.path);
              // Ignore deletion failure since Windows locks read files
              try {
                (await _partialCacheFile).deleteSync();
              } catch (_) {}
           } catch (fallbackError) {
              print('ZenifyCachingAudioSource fallback rename failed: $fallbackError');
           }
        } else {
           print('ZenifyCachingAudioSource rename failed: $e');
        }
      }

      await subscription.cancel();
      httpClient.close();
      _downloading = false;
    }, onError: (Object e, StackTrace stackTrace) async {
      try { (await _partialCacheFile).deleteSync(); } catch (_) {}
      httpClient.close();
      for (final req in _requests) {
        req.fail(e, stackTrace);
      }
      _requests.clear();
      for (final res in inProgressResponses) {
        res.controller.addError(e, stackTrace);
        res.controller.close();
      }
      _downloading = false;
    }, cancelOnError: true);
    return response;
  }

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final cacheFile = await this.cacheFile;
    if (cacheFile.existsSync()) {
      final sourceLength = cacheFile.lengthSync();
      return StreamAudioResponse(
        rangeRequestsSupported: true,
        sourceLength: start != null ? sourceLength : null,
        contentLength: (end ?? sourceLength) - (start ?? 0),
        offset: start,
        contentType: await _readCachedMimeType(),
        stream: cacheFile.openRead(start, end).asBroadcastStream(),
      );
    }
    final byteRangeRequest = _StreamingByteRangeRequest(start, end);
    _requests.add(byteRangeRequest);
    _response ??=
        _fetch().catchError((dynamic error, StackTrace? stackTrace) async {
      _response = null;
      for (final req in _requests) {
        req.fail(error, stackTrace);
      }
      return Future<HttpClientResponse>.error(error as Object, stackTrace);
    });
    return byteRangeRequest.future.then((response) {
      response.stream.listen((event) {}, onError: (Object e, StackTrace st) {
        _response = null;
        for (final req in _requests) {
          req.fail(e, st);
        }
      });
      return response;
    });
  }
}
