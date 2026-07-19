import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:zenify/models/server.dart';

class SubsonicApi {
  final Server server;
  static const String clientName = 'Zenify';
  static const String apiVersion = '1.16.1';

  late final String _salt;
  late final String _token;

  SubsonicApi(this.server) {
    _salt = DateTime.now().millisecondsSinceEpoch.toString();
    _token = md5.convert(utf8.encode(server.password + _salt)).toString();
  }

  /// Generates the query parameters for auth
  Map<String, String> getAuthParams() {
    return {
      'u': server.username,
      't': _token,
      's': _salt,
      'v': apiVersion,
      'c': clientName,
      'f': 'json',
    };
  }

  /// Helper to build URI
  Uri _buildUri(String endpoint, [Map<String, String>? extraParams]) {
    String baseUrl = server.url.trim();
    try {
      Uri baseUri = Uri.parse(baseUrl);
      String cleanUrl = baseUri.origin + baseUri.path;
      while (cleanUrl.endsWith('/')) {
        cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
      }
      if (cleanUrl.toLowerCase().endsWith('/app')) {
        cleanUrl = cleanUrl.substring(0, cleanUrl.length - 4);
      }
      if (cleanUrl.toLowerCase().endsWith('/rest')) {
        cleanUrl = cleanUrl.substring(0, cleanUrl.length - 5);
      }
      while (cleanUrl.endsWith('/')) {
        cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
      }
      baseUrl = cleanUrl;
    } catch (_) {
      // If parsing fails, fall back to simple trim
    }
    
    // Only use .view for JSON endpoints, binary endpoints shouldn't need it
    String suffix = (endpoint == 'stream' || endpoint == 'getCoverArt') ? '' : '.view';
    final uri = Uri.parse('$baseUrl/rest/$endpoint$suffix');
    final queryParams = getAuthParams();
    if (extraParams != null) {
      queryParams.addAll(extraParams);
    }
    
    return uri.replace(queryParameters: queryParams);
  }

  /// Ping the server to check connectivity
  Future<bool> ping() async {
    try {
      final uri = _buildUri('ping');
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['subsonic-response']?['status'] == 'ok';
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get Album List
  Future<List<dynamic>> getAlbumList({String type = 'newest', int size = 20, int offset = 0}) async {
    try {
      final uri = _buildUri('getAlbumList2', {
        'type': type,
        'size': size.toString(),
        'offset': offset.toString(),
      });
      final response = await http.get(uri);
      
      // -- DEBUG LOGGING --
      try {
        final debugFile = File('C:\\Users\\Noah\\Desktop\\Zenify_Debug.txt');
        await debugFile.writeAsString('--- getAlbumList ---\nURL: ${uri.toString()}\n${response.statusCode}\n${response.body}\n\n', mode: FileMode.append);
      } catch (e) {
        print('Debug write failed: $e');
      }
      // -- END DEBUG LOGGING --

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final responseData = json['subsonic-response'];
        if (responseData['status'] == 'ok') {
          // Check for albumList2 first, then fallback to albumList
          final listContainer = responseData['albumList2'] ?? responseData['albumList'];
          if (listContainer != null) {
            final albumData = listContainer['album'];
            if (albumData is List) {
              return albumData;
            } else if (albumData != null) {
              return [albumData]; // Handle single object case
            }
          }
          return [];
        } else {
          print('Subsonic API Error: ${responseData['error']}');
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Get Artists
  Future<List<dynamic>> getArtists() async {
    try {
      final uri = _buildUri('getArtists');
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final responseData = json['subsonic-response'];
        if (responseData['status'] == 'ok') {
          final artistsNode = responseData['artists'] ?? responseData['artists2'];
          if (artistsNode == null) return [];

          var indexes = artistsNode['index'];
          if (indexes == null) return [];
          if (indexes is! List) indexes = [indexes];

          List<dynamic> allArtists = [];
          for (var indexObj in indexes) {
            var artistList = indexObj['artist'];
            if (artistList != null) {
              if (artistList is! List) artistList = [artistList];
              allArtists.addAll(artistList);
            }
          }
          return allArtists;
        } else {
          print('Subsonic API Error: ${responseData['error']}');
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
      }
      return [];
    } catch (e) {
      print('Exception in getArtists: $e');
      return [];
    }
  }

  /// Get Starred items
  Future<Map<String, List<dynamic>>> getStarred() async {
    try {
      final uri = _buildUri('getStarred2');
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final responseData = json['subsonic-response'];
        if (responseData['status'] == 'ok') {
          final starred = responseData['starred2'] ?? responseData['starred'] ?? {};
          
          List<dynamic> _ensureList(dynamic data) {
            if (data == null) return [];
            if (data is List) return data;
            return [data];
          }

          return {
            'artists': _ensureList(starred['artist']),
            'albums': _ensureList(starred['album']),
            'songs': _ensureList(starred['song']),
          };
        } else {
          print('Subsonic API Error: ${responseData['error']}');
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
      }
      return {'artists': [], 'albums': [], 'songs': []};
    } catch (e) {
      print('Exception in getStarred: $e');
      return {'artists': [], 'albums': [], 'songs': []};
    }
  }

  /// Get Album Details (with songs)
  Future<Map<String, dynamic>?> getAlbum(String id) async {
    try {
      final uri = _buildUri('getAlbum', {'id': id});
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final responseData = json['subsonic-response'];
        if (responseData['status'] == 'ok') {
          return responseData['album'];
        } else {
          print('Subsonic API Error: ${responseData['error']}');
        }
      }
      return null;
    } catch (e) {
      print('Exception in getAlbum: $e');
      return null;
    }
  }

  /// Get Stream URL for a song
  String getStreamUrl(String id) {
    return _buildUri('stream', {'id': id}).toString();
  }

  /// Get Cover Art URL
  String getCoverArtUrl(String id, {int? size}) {
    final params = {'id': id};
    if (size != null) {
      params['size'] = size.toString();
    }
    return _buildUri('getCoverArt', params).toString();
  }
}
