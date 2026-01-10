import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../providers/status_provider.dart';
import 'status_indicator.dart';

/// Status bar showing backend and database connectivity
class StatusBar extends StatelessWidget {
  const StatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<StatusProvider>(
      builder: (context, statusProvider, child) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            border: Border(
              top: BorderSide(
                color: Color(0xFF333333),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // Empty spacer to balance the version on the right
              const Expanded(child: SizedBox()),
              // Centered status indicators
              StatusIndicator(
                label: 'Backend',
                icon: Icons.cloud,
                status: statusProvider.backendStatus,
              ),
              const SizedBox(width: 24),
              StatusIndicator(
                label: 'Database',
                icon: Icons.storage,
                status: statusProvider.dbStatus,
              ),
              // Version number on the right
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    AppConfig.appVersion,
                    style: const TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
