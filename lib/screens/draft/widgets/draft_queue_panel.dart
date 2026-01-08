import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/player.dart';
import '../../../providers/player_provider.dart';

/// Panel for managing the user's draft queue - pre-ranked list of players.
class DraftQueuePanel extends StatelessWidget {
  final List<String> queue;
  final Function(int) onRemove;
  final Function(int, int) onReorder;
  final Function(String) onPickFromQueue;
  final bool isMyTurn;

  const DraftQueuePanel({
    super.key,
    required this.queue,
    required this.onRemove,
    required this.onReorder,
    required this.onPickFromQueue,
    required this.isMyTurn,
  });

  @override
  Widget build(BuildContext context) {
    if (queue.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Icon(Icons.queue, color: Colors.green[700]),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'My Draft Queue',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${queue.length} players queued',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (isMyTurn && queue.isNotEmpty)
                ElevatedButton(
                  onPressed: () => onPickFromQueue(queue.first),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Pick #1'),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Instructions
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.blue[50],
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700], size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Drag to reorder. Top player will be auto-picked if timer expires.',
                  style: TextStyle(color: Colors.blue[700], fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        // Queue list
        Expanded(
          child: Consumer<PlayerProvider>(
            builder: (context, provider, _) {
              return ReorderableListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: queue.length,
                onReorder: onReorder,
                itemBuilder: (context, index) {
                  final playerId = queue[index];
                  final player = _findPlayer(provider, playerId);

                  return _QueuedPlayerCard(
                    key: ValueKey(playerId),
                    index: index,
                    playerId: playerId,
                    player: player,
                    onRemove: () => onRemove(index),
                    onPick: isMyTurn ? () => onPickFromQueue(playerId) : null,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.queue,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Your Queue is Empty',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add players from the Pick tab to build your queue. Players will be auto-picked in order if you run out of time.',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                // This would switch to the Pick tab
                // Handled by parent widget
              },
              icon: const Icon(Icons.add),
              label: const Text('Browse Players'),
            ),
          ],
        ),
      ),
    );
  }

  Player? _findPlayer(PlayerProvider provider, String playerId) {
    // Search in batters
    final batter = provider.batters.cast<Player?>().firstWhere(
      (p) => p?.playerId == playerId,
      orElse: () => null,
    );
    if (batter != null) return batter;

    // Search in pitchers
    return provider.pitchers.cast<Player?>().firstWhere(
      (p) => p?.playerId == playerId,
      orElse: () => null,
    );
  }
}

class _QueuedPlayerCard extends StatelessWidget {
  final int index;
  final String playerId;
  final Player? player;
  final VoidCallback onRemove;
  final VoidCallback? onPick;

  const _QueuedPlayerCard({
    super.key,
    required this.index,
    required this.playerId,
    required this.player,
    required this.onRemove,
    this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Rank number
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: index == 0 ? Colors.green[100] : Colors.grey[200],
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: index == 0 ? Colors.green[800] : Colors.grey[700],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Drag handle
            const Icon(Icons.drag_handle, color: Colors.grey),
          ],
        ),
        title: Text(
          player?.fullName ?? 'Unknown Player',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: player != null
            ? Text('${player!.primaryPosition} - ${player!.mlbTeam}')
            : Text(playerId),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onPick != null && index == 0)
              TextButton(
                onPressed: onPick,
                child: Text(
                  'PICK',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              color: Colors.red[400],
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}

/// A compact widget showing queue summary for the draft room header.
class QueueSummaryChip extends StatelessWidget {
  final int queueLength;
  final VoidCallback onTap;

  const QueueSummaryChip({
    super.key,
    required this.queueLength,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: queueLength > 0 ? Colors.green[50] : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: queueLength > 0 ? Colors.green[300]! : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.queue,
              size: 16,
              color: queueLength > 0 ? Colors.green[700] : Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              '$queueLength',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: queueLength > 0 ? Colors.green[700] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
