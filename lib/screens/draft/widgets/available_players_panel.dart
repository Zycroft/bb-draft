import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/draft.dart';
import '../../../models/player.dart';
import '../../../providers/player_provider.dart';

/// Panel showing available players for drafting with search and filter.
class AvailablePlayersPanel extends StatefulWidget {
  final Draft draft;
  final List<DraftPick> picks;
  final Function(Player) onPickPlayer;
  final Function(Player) onAddToQueue;
  final bool isMyTurn;

  const AvailablePlayersPanel({
    super.key,
    required this.draft,
    required this.picks,
    required this.onPickPlayer,
    required this.onAddToQueue,
    required this.isMyTurn,
  });

  @override
  State<AvailablePlayersPanel> createState() => _AvailablePlayersPanelState();
}

class _AvailablePlayersPanelState extends State<AvailablePlayersPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _selectedPosition = 'All';
  String _searchQuery = '';

  final List<String> _positions = [
    'All',
    'C',
    '1B',
    '2B',
    '3B',
    'SS',
    'OF',
    'SP',
    'RP',
    'DH'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Get set of already drafted player IDs
  Set<String> get _draftedPlayerIds =>
      widget.picks.map((p) => p.playerId).toSet();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search and filter bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // Search field
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search players...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
              const SizedBox(height: 8),
              // Position filter chips
              SizedBox(
                height: 36,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _positions.length,
                  itemBuilder: (context, index) {
                    final position = _positions[index];
                    final isSelected = _selectedPosition == position;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(position),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() => _selectedPosition = position);
                        },
                        selectedColor: Colors.green[100],
                        checkmarkColor: Colors.green[700],
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.green[700] : Colors.grey[700],
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        // Tabs
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.green[700],
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: Colors.green[700],
            tabs: const [
              Tab(text: 'Batters'),
              Tab(text: 'Pitchers'),
            ],
          ),
        ),
        // Player list
        Expanded(
          child: Consumer<PlayerProvider>(
            builder: (context, provider, _) {
              return TabBarView(
                controller: _tabController,
                children: [
                  _buildPlayerList(provider.batters, provider.isLoadingBatters),
                  _buildPlayerList(provider.pitchers, provider.isLoadingPitchers),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerList(List<Player> players, bool isLoading) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Filter out drafted players
    var availablePlayers = players
        .where((p) => !_draftedPlayerIds.contains(p.playerId))
        .toList();

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      availablePlayers = availablePlayers.where((p) {
        return p.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            p.mlbTeam.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply position filter
    if (_selectedPosition != 'All') {
      availablePlayers = availablePlayers
          .where((p) => p.primaryPosition == _selectedPosition)
          .toList();
    }

    if (availablePlayers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'No available players found',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: availablePlayers.length,
      itemBuilder: (context, index) {
        final player = availablePlayers[index];
        return _PlayerDraftCard(
          player: player,
          isMyTurn: widget.isMyTurn,
          onPick: () => widget.onPickPlayer(player),
          onAddToQueue: () => widget.onAddToQueue(player),
        );
      },
    );
  }
}

class _PlayerDraftCard extends StatelessWidget {
  final Player player;
  final bool isMyTurn;
  final VoidCallback onPick;
  final VoidCallback onAddToQueue;

  const _PlayerDraftCard({
    required this.player,
    required this.isMyTurn,
    required this.onPick,
    required this.onAddToQueue,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () => _showPlayerDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Position badge
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getPositionColor(player.primaryPosition),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  player.primaryPosition,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Player info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          player.mlbTeam,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                        if (player.jerseyNumber != null) ...[
                          Text(
                            ' #${player.jerseyNumber}',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Stats preview
              _buildStatsPreview(),
              const SizedBox(width: 8),
              // Action buttons
              Column(
                children: [
                  // Pick button
                  SizedBox(
                    width: 70,
                    height: 32,
                    child: ElevatedButton(
                      onPressed: isMyTurn ? onPick : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: const Text('PICK', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Queue button
                  SizedBox(
                    width: 70,
                    height: 28,
                    child: OutlinedButton(
                      onPressed: onAddToQueue,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        side: BorderSide(color: Colors.grey[400]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Icon(Icons.add, size: 16, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsPreview() {
    if (player.isPitcher && player.pitchingStats != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            player.pitchingStats!.era,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          Text(
            'ERA',
            style: TextStyle(color: Colors.grey[500], fontSize: 10),
          ),
        ],
      );
    } else if (player.battingStats != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            player.battingStats!.avg,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          Text(
            'AVG',
            style: TextStyle(color: Colors.grey[500], fontSize: 10),
          ),
        ],
      );
    }
    return const SizedBox(width: 40);
  }

  void _showPlayerDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => _PlayerDetailSheet(
          player: player,
          scrollController: scrollController,
          isMyTurn: isMyTurn,
          onPick: onPick,
          onAddToQueue: onAddToQueue,
        ),
      ),
    );
  }

  Color _getPositionColor(String position) {
    switch (position) {
      case 'SP':
      case 'RP':
      case 'P':
        return Colors.blue[600]!;
      case 'C':
        return Colors.purple[600]!;
      case '1B':
      case '2B':
      case '3B':
      case 'SS':
        return Colors.brown[600]!;
      case 'OF':
      case 'LF':
      case 'CF':
      case 'RF':
        return Colors.green[600]!;
      case 'DH':
        return Colors.orange[600]!;
      default:
        return Colors.grey[600]!;
    }
  }
}

class _PlayerDetailSheet extends StatelessWidget {
  final Player player;
  final ScrollController scrollController;
  final bool isMyTurn;
  final VoidCallback onPick;
  final VoidCallback onAddToQueue;

  const _PlayerDetailSheet({
    required this.player,
    required this.scrollController,
    required this.isMyTurn,
    required this.onPick,
    required this.onAddToQueue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: ListView(
        controller: scrollController,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Player header
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor:
                    player.isPitcher ? Colors.blue[700] : Colors.green[700],
                child: Text(
                  player.primaryPosition,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.fullName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${player.mlbTeam}${player.jerseyNumber != null ? ' #${player.jerseyNumber}' : ''}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isMyTurn
                      ? () {
                          Navigator.pop(context);
                          onPick();
                        }
                      : null,
                  icon: const Icon(Icons.check),
                  label: const Text('DRAFT NOW'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  onAddToQueue();
                },
                icon: const Icon(Icons.add),
                label: const Text('Queue'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Player info
          _buildInfoRow('Position', player.primaryPosition),
          _buildInfoRow('Bats/Throws', '${player.batSide}/${player.pitchHand}'),
          if (player.height != null) _buildInfoRow('Height', player.height!),
          if (player.weight != null)
            _buildInfoRow('Weight', '${player.weight} lbs'),
          const SizedBox(height: 24),
          const Text(
            'Statistics',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          // Stats
          if (player.isPitcher && player.pitchingStats != null)
            _buildPitchingStats(player.pitchingStats!)
          else if (player.battingStats != null)
            _buildBattingStats(player.battingStats!)
          else
            const Text(
              'No statistics available',
              style: TextStyle(color: Colors.grey),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
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

  Widget _buildBattingStats(BatterStats stats) {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      children: [
        _StatChip(label: 'AVG', value: stats.avg),
        _StatChip(label: 'HR', value: stats.homeRuns.toString()),
        _StatChip(label: 'RBI', value: stats.rbi.toString()),
        _StatChip(label: 'OBP', value: stats.obp),
        _StatChip(label: 'SLG', value: stats.slg),
        _StatChip(label: 'OPS', value: stats.ops),
        _StatChip(label: 'R', value: stats.runs.toString()),
        _StatChip(label: 'SB', value: stats.stolenBases.toString()),
      ],
    );
  }

  Widget _buildPitchingStats(PitcherStats stats) {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      children: [
        _StatChip(label: 'ERA', value: stats.era),
        _StatChip(label: 'W-L', value: '${stats.wins}-${stats.losses}'),
        _StatChip(label: 'K', value: stats.strikeouts.toString()),
        _StatChip(label: 'WHIP', value: stats.whip),
        _StatChip(label: 'IP', value: stats.inningsPitched),
        _StatChip(label: 'SV', value: stats.saves.toString()),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
