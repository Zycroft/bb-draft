import 'package:flutter/foundation.dart' show kIsWeb;

/// API configuration for connecting to the backend
class ApiConfig {
  /// Get the base URL for API calls
  static String get baseUrl {
    if (kIsWeb) {
      final uri = Uri.base;

      // Production environment
      if (uri.host.contains('zycroft.duckdns.org')) {
        return 'https://zycroft.duckdns.org/bb-draft-api';
      }

      // Local development - use production API
      if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
        return 'https://zycroft.duckdns.org/bb-draft-api';
      }
    }

    // Default fallback
    return 'http://localhost:3000';
  }

  /// Health check endpoint
  static String get healthUrl => '$baseUrl/health';

  /// Database health check endpoint
  static String get healthDbUrl => '$baseUrl/health/db';
}
