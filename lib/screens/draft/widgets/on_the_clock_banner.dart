import 'package:flutter/material.dart';
import '../../../models/draft.dart';

/// Banner showing who is on the clock and the timer.
class OnTheClockBanner extends StatelessWidget {
  final Draft draft;
  final int timeRemaining;
  final bool isMyTurn;

  const OnTheClockBanner({
    super.key,
    required this.draft,
    required this.timeRemaining,
    required this.isMyTurn,
  });

  @override
  Widget build(BuildContext context) {
    if (draft.status == DraftStatus.completed) {
      return _buildCompletedBanner();
    }

    if (draft.status == DraftStatus.paused) {
      return _buildPausedBanner();
    }

    if (draft.status == DraftStatus.scheduled) {
      return _buildScheduledBanner();
    }

    return Container(
      decoration: BoxDecoration(
        color: isMyTurn ? Colors.green[50] : Colors.amber[50],
        border: Border(
          bottom: BorderSide(
            color: isMyTurn ? Colors.green[200]! : Colors.amber[200]!,
            width: 2,
          ),
        ),
      ),
      child: Column(
        children: [
          // On the clock info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Team indicator
                CircleAvatar(
                  radius: 24,
                  backgroundColor: isMyTurn ? Colors.green[700] : Colors.amber[700],
                  child: Icon(
                    isMyTurn ? Icons.person : Icons.hourglass_top,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),

                // Team and pick info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isMyTurn ? 'YOUR TURN TO PICK!' : 'ON THE CLOCK',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isMyTurn ? Colors.green[800] : Colors.amber[800],
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isMyTurn
                            ? 'Make your selection below'
                            : 'Team ${draft.onTheClock?.teamId ?? 'Unknown'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),

                // Timer
                _TimerDisplay(
                  timeRemaining: timeRemaining,
                  totalTime: draft.pickTimer,
                  isMyTurn: isMyTurn,
                ),
              ],
            ),
          ),

          // Progress indicator
          LinearProgressIndicator(
            value: draft.pickTimer > 0
                ? timeRemaining / draft.pickTimer
                : 0,
            backgroundColor: Colors.transparent,
            valueColor: AlwaysStoppedAnimation<Color>(
              _getProgressColor(timeRemaining),
            ),
            minHeight: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        border: Border(
          bottom: BorderSide(color: Colors.green[200]!, width: 2),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green[700], size: 32),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DRAFT COMPLETED',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                Text(
                  'All picks have been made',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPausedBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        border: Border(
          bottom: BorderSide(color: Colors.orange[200]!, width: 2),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.pause_circle, color: Colors.orange[700], size: 32),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DRAFT PAUSED',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                Text(
                  'Waiting for commissioner to resume',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduledBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(
          bottom: BorderSide(color: Colors.blue[200]!, width: 2),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule, color: Colors.blue[700], size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DRAFT SCHEDULED',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                Text(
                  draft.scheduledStart != null
                      ? 'Starting at ${_formatDateTime(draft.scheduledStart!)}'
                      : 'Waiting for commissioner to start',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      return '${dt.month}/${dt.day} at ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoString;
    }
  }

  Color _getProgressColor(int timeRemaining) {
    if (timeRemaining <= 5) return Colors.red;
    if (timeRemaining <= 15) return Colors.orange;
    return Colors.green[700]!;
  }
}

class _TimerDisplay extends StatelessWidget {
  final int timeRemaining;
  final int totalTime;
  final bool isMyTurn;

  const _TimerDisplay({
    required this.timeRemaining,
    required this.totalTime,
    required this.isMyTurn,
  });

  @override
  Widget build(BuildContext context) {
    final isLowTime = timeRemaining <= 15;
    final isCritical = timeRemaining <= 5;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _getBackgroundColor(isLowTime, isCritical),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            _formatTime(timeRemaining),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (isMyTurn)
            const Text(
              'PICK NOW',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
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
    if (isMyTurn) return Colors.green[700]!;
    return Colors.amber[700]!;
  }
}
