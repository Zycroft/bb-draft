import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/draft_provider.dart';
import '../../providers/player_provider.dart';
import '../../models/draft.dart';
import '../../models/player.dart';
import 'widgets/draft_grid.dart';
import 'widgets/available_players_panel.dart';
import 'widgets/draft_queue_panel.dart';
import 'widgets/draft_chat_panel.dart';
import 'widgets/on_the_clock_banner.dart';

class DraftRoomScreen extends StatefulWidget {
  final String draftId;
  final String teamId;
  final String leagueName;

  const DraftRoomScreen({
    super.key,
    required this.draftId,
    required this.teamId,
    required this.leagueName,
  });

  @override
  State<DraftRoomScreen> createState() => _DraftRoomScreenState();
}

class _DraftRoomScreenState extends State<DraftRoomScreen> {
  int _selectedIndex = 0;
  final List<String> _draftQueue = [];

  @override
  void initState() {
    super.initState();
    _connectToDraft();
  }

  Future<void> _connectToDraft() async {
    if (!mounted) return;
    final draftProvider = context.read<DraftProvider>();
    await draftProvider.loadDraft(widget.draftId);
    if (!mounted) return;
    await draftProvider.connectToDraft(widget.draftId, widget.teamId);

    // Load players for draft
    if (!mounted) return;
    final playerProvider = context.read<PlayerProvider>();
    playerProvider.loadBatters();
    playerProvider.loadPitchers();
  }

  @override
  void dispose() {
    context.read<DraftProvider>().disconnect();
    super.dispose();
  }

  void _onMakePick(Player player) {
    final draftProvider = context.read<DraftProvider>();
    if (draftProvider.isMyTurn) {
      draftProvider.makePick(player.playerId);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('It\'s not your turn to pick'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _addToQueue(Player player) {
    if (!_draftQueue.contains(player.playerId)) {
      setState(() {
        _draftQueue.add(player.playerId);
      });
      context.read<DraftProvider>().updateQueue(_draftQueue);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${player.fullName} added to queue'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _removeFromQueue(int index) {
    setState(() {
      _draftQueue.removeAt(index);
    });
    context.read<DraftProvider>().updateQueue(_draftQueue);
  }

  void _reorderQueue(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _draftQueue.removeAt(oldIndex);
      _draftQueue.insert(newIndex, item);
    });
    context.read<DraftProvider>().updateQueue(_draftQueue);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DraftProvider>(
      builder: (context, draftProvider, _) {
        if (draftProvider.isLoading) {
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.leagueName),
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (draftProvider.draft == null) {
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.leagueName),
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(draftProvider.error ?? 'Failed to load draft'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _connectToDraft,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final draft = draftProvider.draft!;

        return Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: _buildAppBar(draft, draftProvider),
          body: Column(
            children: [
              // On The Clock Banner
              OnTheClockBanner(
                draft: draft,
                timeRemaining: draftProvider.timeRemaining,
                isMyTurn: draftProvider.isMyTurn,
              ),

              // Main Content
              Expanded(
                child: _buildBody(draft, draftProvider),
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomNav(),
        );
      },
    );
  }

  AppBar _buildAppBar(Draft draft, DraftProvider provider) {
    return AppBar(
      backgroundColor: Colors.green[700],
      foregroundColor: Colors.white,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.leagueName, style: const TextStyle(fontSize: 16)),
          Text(
            'Round ${draft.currentRound}/${draft.totalRounds} | Pick ${draft.currentOverallPick}/${draft.totalPicks}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
          ),
        ],
      ),
      actions: [
        // Connection indicator
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Icon(
            provider.isConnected ? Icons.wifi : Icons.wifi_off,
            color: provider.isConnected ? Colors.greenAccent : Colors.red,
            size: 20,
          ),
        ),
        // Pause/Resume for commissioner
        if (draft.status == DraftStatus.inProgress)
          IconButton(
            icon: const Icon(Icons.pause),
            onPressed: () => provider.pauseDraft(draft.draftId),
            tooltip: 'Pause Draft',
          )
        else if (draft.status == DraftStatus.paused)
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: () => provider.resumeDraft(draft.draftId),
            tooltip: 'Resume Draft',
          ),
        // Settings
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            switch (value) {
              case 'settings':
                _showSettings();
                break;
              case 'leave':
                _confirmLeave();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'settings', child: Text('Settings')),
            const PopupMenuItem(value: 'leave', child: Text('Leave Draft')),
          ],
        ),
      ],
    );
  }

  Widget _buildBody(Draft draft, DraftProvider provider) {
    switch (_selectedIndex) {
      case 0:
        return DraftGrid(
          draft: draft,
          picks: provider.picks,
          currentTeamId: widget.teamId,
          onCellTap: _showPickDetails,
        );
      case 1:
        return AvailablePlayersPanel(
          draft: draft,
          picks: provider.picks,
          onPickPlayer: _onMakePick,
          onAddToQueue: _addToQueue,
          isMyTurn: provider.isMyTurn,
        );
      case 2:
        return DraftQueuePanel(
          queue: _draftQueue,
          onRemove: _removeFromQueue,
          onReorder: _reorderQueue,
          onPickFromQueue: (playerId) {
            context.read<DraftProvider>().makePick(playerId);
          },
          isMyTurn: provider.isMyTurn,
        );
      case 3:
        return DraftChatPanel(
          draftId: widget.draftId,
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) => setState(() => _selectedIndex = index),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.green[700],
      unselectedItemColor: Colors.grey[600],
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.grid_on),
          label: 'Grid',
        ),
        BottomNavigationBarItem(
          icon: Stack(
            children: [
              const Icon(Icons.person_search),
              if (context.watch<DraftProvider>().isMyTurn)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          label: 'Pick',
        ),
        BottomNavigationBarItem(
          icon: Badge(
            label: Text('${_draftQueue.length}'),
            isLabelVisible: _draftQueue.isNotEmpty,
            child: const Icon(Icons.queue),
          ),
          label: 'Queue',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.chat),
          label: 'Chat',
        ),
      ],
    );
  }

  void _showPickDetails(DraftPick pick) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.green[700],
                  child: Text(
                    pick.position,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pick.playerName,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${pick.mlbTeam} | ${pick.position}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Round', '${pick.round}'),
            _buildDetailRow('Pick', '${pick.pickInRound} (Overall: ${pick.overallPick})'),
            _buildDetailRow('Pick Time', '${pick.pickDuration}s'),
            if (pick.wasAutoPick)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Auto-Pick',
                  style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Draft Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Auto-Pick on Timeout'),
              subtitle: const Text('Automatically pick from your queue'),
              value: true,
              onChanged: (value) {},
            ),
            SwitchListTile(
              title: const Text('Sound Notifications'),
              subtitle: const Text('Play sound when it\'s your turn'),
              value: true,
              onChanged: (value) {},
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLeave() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Draft?'),
        content: const Text(
          'Are you sure you want to leave the draft room? Auto-pick will be enabled for your picks.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Leave', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
