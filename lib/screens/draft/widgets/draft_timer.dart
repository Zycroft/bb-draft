import 'package:flutter/material.dart';

/// Displays the draft timer with visual progress indicator.
class DraftTimer extends StatelessWidget {
  final int timeRemaining;
  final int totalTime;
  final bool isMyTurn;
  final bool isPaused;

  const DraftTimer({
    super.key,
    required this.timeRemaining,
    required this.totalTime,
    required this.isMyTurn,
    this.isPaused = false,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalTime > 0 ? timeRemaining / totalTime : 0.0;
    final isLowTime = timeRemaining <= 15;
    final isCritical = timeRemaining <= 5;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Timer icon
          Icon(
            isPaused ? Icons.pause : Icons.timer,
            color: _getTimerColor(isLowTime, isCritical),
            size: 24,
          ),
          const SizedBox(width: 12),

          // Progress bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Time text
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isPaused ? 'PAUSED' : _formatTime(timeRemaining),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _getTimerColor(isLowTime, isCritical),
                      ),
                    ),
                    if (isMyTurn)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'YOUR TURN',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[800],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getTimerColor(isLowTime, isCritical),
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Color _getTimerColor(bool isLowTime, bool isCritical) {
    if (isCritical) return Colors.red;
    if (isLowTime) return Colors.orange;
    return Colors.green[700]!;
  }
}

/// A compact timer widget for the app bar.
class CompactTimer extends StatelessWidget {
  final int timeRemaining;
  final int totalTime;

  const CompactTimer({
    super.key,
    required this.timeRemaining,
    required this.totalTime,
  });

  @override
  Widget build(BuildContext context) {
    final isLowTime = timeRemaining <= 15;
    final isCritical = timeRemaining <= 5;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getBackgroundColor(isLowTime, isCritical),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            _formatTime(timeRemaining),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Color _getBackgroundColor(bool isLowTime, bool isCritical) {
    if (isCritical) return Colors.red;
    if (isLowTime) return Colors.orange;
    return Colors.green[700]!;
  }
}
