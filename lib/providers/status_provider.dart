import 'dart:async';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../config/app_config.dart';
import '../services/api_service.dart';

/// Connection status for backend services
enum ConnectionStatus {
  connected,
  disconnected,
  checking,
}

/// Provider for managing backend and database connectivity status
class StatusProvider extends ChangeNotifier {
  ConnectionStatus _backendStatus = ConnectionStatus.checking;
  ConnectionStatus _dbStatus = ConnectionStatus.checking;
  Timer? _refreshTimer;

  StatusProvider() {
    if (AppConfig.showDevStatusIndicators) {
      // Initial check
      checkAllStatus();

      // Set up auto-refresh timer
      _refreshTimer = Timer.periodic(
        Duration(seconds: AppConfig.statusCheckIntervalSeconds),
        (_) => checkAllStatus(),
      );
    }
  }

  /// Current backend connection status
  ConnectionStatus get backendStatus => _backendStatus;

  /// Current database connection status
  ConnectionStatus get dbStatus => _dbStatus;

  /// Check backend health endpoint
  Future<void> checkBackendStatus() async {
    _backendStatus = ConnectionStatus.checking;
    notifyListeners();

    final isReachable = await ApiService.isReachable(ApiConfig.healthUrl);
    _backendStatus =
        isReachable ? ConnectionStatus.connected : ConnectionStatus.disconnected;
    notifyListeners();
  }

  /// Check database health endpoint
  Future<void> checkDbStatus() async {
    _dbStatus = ConnectionStatus.checking;
    notifyListeners();

    final isReachable = await ApiService.isReachable(ApiConfig.healthDbUrl);
    _dbStatus =
        isReachable ? ConnectionStatus.connected : ConnectionStatus.disconnected;
    notifyListeners();
  }

  /// Check both backend and database status
  Future<void> checkAllStatus() async {
    // Set both to checking
    _backendStatus = ConnectionStatus.checking;
    _dbStatus = ConnectionStatus.checking;
    notifyListeners();

    // Check both endpoints in parallel
    final results = await Future.wait([
      ApiService.isReachable(ApiConfig.healthUrl),
      ApiService.isReachable(ApiConfig.healthDbUrl),
    ]);

    _backendStatus =
        results[0] ? ConnectionStatus.connected : ConnectionStatus.disconnected;
    _dbStatus =
        results[1] ? ConnectionStatus.connected : ConnectionStatus.disconnected;
    notifyListeners();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
