import 'package:flutter/material.dart';
import '../providers/status_provider.dart';

/// A single status indicator showing connection status with an icon
class StatusIndicator extends StatelessWidget {
  final String label;
  final IconData icon;
  final ConnectionStatus status;

  const StatusIndicator({
    super.key,
    required this.label,
    required this.icon,
    required this.status,
  });

  Color get _color {
    switch (status) {
      case ConnectionStatus.connected:
        return const Color(0xFF4CAF50); // Green
      case ConnectionStatus.disconnected:
        return const Color(0xFFF44336); // Red
      case ConnectionStatus.checking:
        return const Color(0xFF9E9E9E); // Grey
    }
  }

  String get _statusText {
    switch (status) {
      case ConnectionStatus.connected:
        return '$label: Connected';
      case ConnectionStatus.disconnected:
        return '$label: Disconnected';
      case ConnectionStatus.checking:
        return '$label: Checking...';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: _color,
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          _statusText,
          style: TextStyle(
            color: _color,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
