import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/encyclopedia.dart';
import '../../providers/encyclopedia_provider.dart';
import 'player_comparison_screen.dart';

class LeaderboardScreen extends StatefulWidget {
  final String leagueId;
  final String statCode;
  final String type;
  final int? season;

  const LeaderboardScreen({
    super.key,
    required this.leagueId,
    required this.statCode,
    this.type = 'seasonal',
    this.season,
  });

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  String _selectedType = 'seasonal';
  int? _selectedSeason;
  int _displayCount = 10;
  final TextEditingController _searchController = TextEditingController();
  LeaderboardEntry? _searchedPlayer;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.type;
    _selectedSeason = widget.season;
    _loadLeaderboard();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLeaderboard() async {
    await context.read<EncyclopediaProvider>().loadLeaderboard(
          widget.leagueId,
          widget.statCode,
          type: _selectedType,
          season: _selectedSeason,
          limit: _displayCount,
          search: _searchController.text.isNotEmpty ? _searchController.text : null,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        title: Text('${widget.statCode} Leaders'),
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Display count',
            onSelected: (count) {
              setState(() => _displayCount = count);
              _loadLeaderboard();
            },
            itemBuilder: (context) => [
              _buildCountOption(5, 'Top 5'),
              _buildCountOption(10, 'Top 10'),
              _buildCountOption(25, 'Top 25'),
              _buildCountOption(50, 'Top 50'),
              _buildCountOption(100, 'Top 100'),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Type selector
                Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'seasonal', label: Text('Season')),
                          ButtonSegment(value: 'career', label: Text('Career')),
                        ],
                        selected: {_selectedType},
                        onSelectionChanged: (selection) {
                          setState(() => _selectedType = selection.first);
                          _loadLeaderboard();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Search and season selector
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Find player...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onSubmitted: (_) => _loadLeaderboard(),
                      ),
                    ),
                    if (_selectedType == 'seasonal') ...[
                      const SizedBox(width: 12),
                      Consumer<EncyclopediaProvider>(
                        builder: (context, provider, _) {
                          final seasons = provider.summary?.importedSeasons ?? [];
                          return DropdownButton<int?>(
                            value: _selectedSeason,
                            hint: const Text('All'),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('All')),
                              ...seasons.map((year) => DropdownMenuItem(
                                value: year,
                                child: Text('$year'),
                              )),
                            ],
                            onChanged: (value) {
                              setState(() => _selectedSeason = value);
                              _loadLeaderboard();
                            },
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Leaderboard
          Expanded(
            child: Consumer<EncyclopediaProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final leaderboard = provider.currentLeaderboard;
                if (leaderboard == null) {
                  return const Center(child: Text('No data available'));
                }

                if (leaderboard.entries.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.leaderboard, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No leaders found',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _loadLeaderboard,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: leaderboard.entries.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        // Header
                        return _buildHeader(leaderboard);
                      }

                      final entry = leaderboard.entries[index - 1];
                      return _LeaderboardRow(
                        entry: entry,
                        statCode: widget.statCode,
                        isCareer: _selectedType == 'career',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PlayerComparisonScreen(
                                leagueId: widget.leagueId,
                                playerId: entry.playerId,
                                playerName: entry.playerName,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<int> _buildCountOption(int count, String label) {
    return PopupMenuItem(
      value: count,
      child: Row(
        children: [
          if (_displayCount == count)
            Icon(Icons.check, color: Colors.green[700], size: 20)
          else
            const SizedBox(width: 20),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildHeader(Leaderboard leaderboard) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.green[700],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              leaderboard.statCategory,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _selectedType == 'career'
                  ? 'Career Leaders'
                  : _selectedSeason != null
                      ? '$_selectedSeason Season Leaders'
                      : 'All-Time Season Leaders',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
            ),
            if (leaderboard.minimumQualifier != null) ...[
              const SizedBox(height: 8),
              Text(
                'Min: ${leaderboard.minimumQualifier!.minValue} '
                '${leaderboard.minimumQualifier!.statType}'
                '${leaderboard.minimumQualifier!.perGame ? '/G' : ''}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final LeaderboardEntry entry;
  final String statCode;
  final bool isCareer;
  final VoidCallback onTap;

  const _LeaderboardRow({
    required this.entry,
    required this.statCode,
    required this.isCareer,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isTopThree = entry.rank <= 3;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Rank
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isTopThree ? _getRankColor(entry.rank) : Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    '${entry.rank}',
                    style: TextStyle(
                      color: isTopThree ? Colors.white : Colors.grey[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
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
                      entry.playerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isCareer
                          ? '${entry.teams?.join(', ') ?? ''} - ${entry.seasons ?? 0} seasons'
                          : entry.teamName ?? '',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Trend indicator
              if (entry.trend != null) ...[
                _buildTrendIndicator(entry.trend!),
                const SizedBox(width: 8),
              ],

              // Value
              Text(
                _formatValue(entry.value),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),

              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber[700]!;
      case 2:
        return Colors.blueGrey[400]!;
      case 3:
        return Colors.brown[400]!;
      default:
        return Colors.grey[400]!;
    }
  }

  Widget _buildTrendIndicator(String trend) {
    switch (trend) {
      case 'up':
        return const Icon(Icons.arrow_upward, color: Colors.green, size: 16);
      case 'down':
        return const Icon(Icons.arrow_downward, color: Colors.red, size: 16);
      case 'new':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.blue[100],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            'NEW',
            style: TextStyle(fontSize: 8, color: Colors.blue[700], fontWeight: FontWeight.bold),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  String _formatValue(double value) {
    if (['AVG', 'OBP', 'SLG', 'OPS', 'WPCT'].contains(statCode)) {
      return value.toStringAsFixed(3).replaceFirst('0.', '.');
    } else if (['ERA', 'WHIP', 'K9', 'BB9', 'KBB'].contains(statCode)) {
      return value.toStringAsFixed(2);
    } else if (statCode == 'IP') {
      return value.toStringAsFixed(1);
    }
    return value.toInt().toString();
  }
}
