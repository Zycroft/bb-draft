class ApiConfig {
  // Change this to your backend URL
  static const String baseUrl = 'http://localhost:3000';
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
