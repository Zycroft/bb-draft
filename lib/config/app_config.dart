/// Application configuration settings
class AppConfig {
  /// Enable/disable development status indicators at bottom of screen
  /// Set to true to show backend and database connectivity status
  /// Set to false to hide the status bar (recommended for production)
  static const bool showDevStatusIndicators = true;

  /// Status check interval in seconds
  static const int statusCheckIntervalSeconds = 30;
}
