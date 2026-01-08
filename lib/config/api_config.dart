import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) {
      final uri = Uri.base;
      if (uri.host.contains('zycroft.duckdns.org')) {
        // Production - API proxied through nginx at /bb-draft-api
        return 'https://zycroft.duckdns.org/bb-draft-api';
      }
    }
    // Development fallback
    return 'http://localhost:3000';
  }

  static const String apiPath = '/api';

  static String get apiUrl => '$baseUrl$apiPath';

  // Endpoints
  static String get usersUrl => '$apiUrl/users';
  static String get playersUrl => '$apiUrl/players';
  static String get leaguesUrl => '$apiUrl/leagues';
  static String get teamsUrl => '$apiUrl/teams';
  static String get draftsUrl => '$apiUrl/drafts';

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
