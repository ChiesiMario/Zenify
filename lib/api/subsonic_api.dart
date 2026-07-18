import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:zenify/models/server.dart';

class SubsonicApi {
  final Server server;
  static const String clientName = 'Zenify';
  static const String apiVersion = '1.16.1';

  SubsonicApi(this.server);

  /// Generates the query parameters for auth
  Map<String, String> getAuthParams() {
    final salt = DateTime.now().millisecondsSinceEpoch.toString();
    final token = md5.convert(utf8.encode(server.password + salt)).toString();

    return {
      'u': server.username,
      't': token,
      's': salt,
      'v': apiVersion,
      'c': clientName,
      'f': 'json',
    };
  }

  /// Helper to build URI
  Uri _buildUri(String endpoint, [Map<String, String>? extraParams]) {
    String baseUrl = server.url;
    if (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }
    
    final uri = Uri.parse('$baseUrl/rest/$endpoint');
    final queryParams = getAuthParams();
    if (extraParams != null) {
      queryParams.addAll(extraParams);
    }
    
    // uri.replace(queryParameters: queryParams) works well for merging
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
  Future<List<dynamic>> getAlbumList({String type = 'newest', int size = 20}) async {
    try {
      final uri = _buildUri('getAlbumList2', {
        'type': type,
        'size': size.toString(),
      });
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final responseData = json['subsonic-response'];
        if (responseData['status'] == 'ok') {
          return responseData['albumList2']?['album'] ?? [];
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Get Stream URL for a song
  String getStreamUrl(String id) {
    return _buildUri('stream', {'id': id}).toString();
  }
}
