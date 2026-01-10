/// Application configuration settings
class AppConfig {
  /// Enable/disable development status indicators at bottom of screen
  /// Set to true to show backend and database connectivity status
  /// Set to false to hide the status bar (recommended for production)
  static const bool showDevStatusIndicators = true;

  /// Status check interval in seconds
  static const int statusCheckIntervalSeconds = 30;

  /// Major.Minor.Patch version number (manually bumped for releases)
  static const String majorMinorPatch = '0.0.0';

  /// Full application version, set at build time via --dart-define
  /// Format: X.X.X-yyyymmdd-#### (e.g., 0.0.0-20260109-0001)
  /// Falls back to 'dev' if not set (local development)
  static const String appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: 'dev',
  );
}
