import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service for making HTTP requests to the API
class ApiService {
  static const Duration _timeout = Duration(seconds: 5);

  /// Perform a GET request with timeout handling
  static Future<Map<String, dynamic>?> get(String url) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(_timeout);

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }

      return null;
    } on TimeoutException {
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Check if an endpoint is reachable (returns status 200)
  static Future<bool> isReachable(String url) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(_timeout);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
