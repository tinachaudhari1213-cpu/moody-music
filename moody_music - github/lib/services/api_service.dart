
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://10.181.191.135:5000';
  static const Duration timeout = Duration(seconds: 15);

  static Future<http.Response> _get(String url) async {
    return http
        .get(Uri.parse(url))
        .timeout(timeout);
  }

  static Future<http.Response> _post(
    String url,
    Map<String, dynamic> body,
  ) async {
    return http
        .post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(timeout);
  }

static dynamic _decode(http.Response response) {
  print('API STATUS: ${response.statusCode}');
  print('API RESPONSE: ${response.body}');

  try {
    return jsonDecode(response.body);
  } on FormatException {
    throw Exception(
      'Invalid server response '
      '(${response.statusCode}): ${response.body}',
    );
  }
}

  static String _message(dynamic data, String fallback) {
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    return fallback;
  }

  // GET SONGS
  static Future<List<dynamic>> getSongs() async {
    final response = await _get('$baseUrl/songs');
    final data = _decode(response);

    if (response.statusCode == 200 && data is List) {
      return data;
    }
    throw Exception(_message(data, 'Failed to load songs'));
  }

  // REGISTER
  static Future<Map<String, dynamic>> registerUser({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _post('$baseUrl/register', {
      'name': name,
      'email': email,
      'password': password,
    });
    final data = _decode(response);

    if ((response.statusCode == 200 ||
            response.statusCode == 201) &&
        data is Map<String, dynamic>) {
      return data;
    }
    throw Exception(_message(data, 'Registration failed'));
  }

  // LOGIN
  static Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    final response = await _post('$baseUrl/login', {
      'email': email,
      'password': password,
    });
    final data = _decode(response);

    if (response.statusCode == 200 &&
        data is Map<String, dynamic>) {
      return data;
    }
    throw Exception(_message(data, 'Login failed'));
  }

  // ADD FAVORITE
  static Future<Map<String, dynamic>> addFavorite(
    int userId,
    int songId,
  ) async {
    final response = await _post('$baseUrl/favorites', {
      'user_id': userId,
      'song_id': songId,
    });
    final data = _decode(response);

    if ((response.statusCode == 200 ||
            response.statusCode == 201) &&
        data is Map<String, dynamic>) {
      return data;
    }
    throw Exception(_message(data, 'Failed to add favorite'));
  }

  // GET FAVORITES
  static Future<List<dynamic>> getFavorites(int userId) async {
    final response = await _get('$baseUrl/favorites/$userId');
    final data = _decode(response);

    if (response.statusCode == 200 && data is List) {
      return data;
    }
    throw Exception(_message(data, 'Failed to load favorites'));
  }

  // REMOVE FAVORITE
  static Future<Map<String, dynamic>> removeFavorite(
    int userId,
    int songId,
  ) async {
    final response = await http
        .delete(Uri.parse('$baseUrl/favorites/$userId/$songId'))
        .timeout(timeout);
    final data = _decode(response);

    if (response.statusCode == 200 &&
        data is Map<String, dynamic>) {
      return data;
    }
    throw Exception(_message(data, 'Failed to remove favorite'));
  }

  // ADD HISTORY
  static Future<Map<String, dynamic>> addHistory(
    int userId,
    int songId,
  ) async {
    final response = await _post('$baseUrl/history', {
      'user_id': userId,
      'song_id': songId,
    });
    final data = _decode(response);

    if ((response.statusCode == 200 ||
            response.statusCode == 201) &&
        data is Map<String, dynamic>) {
      return data;
    }
    throw Exception(_message(data, 'Failed to save history'));
  }

  // GET HISTORY
  static Future<List<dynamic>> getHistory(int userId) async {
    final response = await _get('$baseUrl/history/$userId');
    final data = _decode(response);

    if (response.statusCode == 200 && data is List) {
      return data;
    }
    throw Exception(_message(data, 'Failed to load history'));
  }

  // MOOD PREDICTION
  static Future<Map<String, dynamic>> predictMood(
    String text,
  ) async {
    final response = await _post('$baseUrl/predict-mood', {
      'text': text,
    });
    final data = _decode(response);

    if (response.statusCode == 200 &&
        data is Map<String, dynamic>) {
      return data;
    }
    throw Exception(_message(data, 'Mood prediction failed'));
  }

  // YOUTUBE SEARCH
  static Future<List<dynamic>> searchYouTube(String query) async {
    final response = await _get(
      '$baseUrl/youtube-search?q=${Uri.encodeQueryComponent(query)}',
    );
    final data = _decode(response);

    if (response.statusCode == 200 &&
        data is Map &&
        data['success'] == true &&
        data['results'] is List) {
      return List<dynamic>.from(data['results']);
    }
    throw Exception(_message(data, 'YouTube search failed'));
  }
}
