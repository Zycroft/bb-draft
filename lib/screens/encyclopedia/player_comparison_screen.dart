import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/encyclopedia.dart';
import '../../providers/encyclopedia_provider.dart';

class PlayerComparisonScreen extends StatefulWidget {
  final String leagueId;
  final String playerId;
  final String playerName;

  const PlayerComparisonScreen({
    super.key,
    required this.leagueId,
    required this.playerId,
    required this.playerName,
  });

  @override
  State<PlayerComparisonScreen> createState() => _PlayerComparisonScreenState();
}

class _PlayerComparisonScreenState extends State<PlayerComparisonScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _comparisonType = 'single_season';
  int? _selectedSeason;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    context.read<EncyclopediaProvider>().clearPlayerData();
    super.dispose();
  }

  Future<void> _loadData() async {
    final provider = context.read<EncyclopediaProvider>();
    await Future.wait([
      provider.loadPlayerCareerStats(widget.leagueId, widget.playerId),
      provider.loadPlayerSeasons(widget.leagueId, widget.playerId),
      provider.loadPlayerComparison(
        widget.leagueId,
        widget.playerId,
        season: _selectedSeason,
        type: _comparisonType,
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        title: Text(widget.playerName),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Career'),
            Tab(text: 'Seasons'),
            Tab(text: 'Compare'),
          ],
        ),
      ),
      body: Consumer<EncyclopediaProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.playerCareerStats == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _CareerTab(stats: provider.playerCareerStats),
              _SeasonsTab(seasons: provider.playerSeasons),
              _CompareTab(
                leagueId: widget.leagueId,
                playerId: widget.playerId,
                comparison: provider.playerComparison,
                selectedType: _comparisonType,
                selectedSeason: _selectedSeason,
                availableSeasons: provider.playerSeasons.map((s) => s.seasonYear).toList(),
                onTypeChanged: (type) {
                  setState(() => _comparisonType = type);
                  provider.loadPlayerComparison(
                    widget.leagueId,
                    widget.playerId,
                    season: _selectedSeason,
                    type: type,
                  );
                },
                onSeasonChanged: (season) {
                  setState(() => _selectedSeason = season);
                  provider.loadPlayerComparison(
                    widget.leagueId,
                    widget.playerId,
                    season: season,
                    type: _comparisonType,
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CareerTab extends StatelessWidget {
  final PlayerCareerStats? stats;

  const _CareerTab({required this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats == null) {
      return const Center(child: Text('No career stats available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overview Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.green[100],
                        child: Icon(Icons.person, size: 36, color: Colors.green[700]),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stats!.playerName,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${stats!.seasonsPlayed} Seasons',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            Text(
                              stats!.teams.join(', '),
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      if (stats!.isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Active',
                            style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Batting Stats
          if (stats!.batting != null) ...[
            const Text(
              'Batting Statistics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _StatGrid(
                      stats: [
                        _StatGridItem('G', stats!.batting!.gamesPlayed.toString()),
                        _StatGridItem('AB', stats!.batting!.atBats.toString()),
                        _StatGridItem('H', stats!.batting!.hits.toString()),
                        _StatGridItem('AVG', stats!.batting!.avg.toStringAsFixed(3)),
                        _StatGridItem('HR', stats!.batting!.homeRuns.toString()),
                        _StatGridItem('RBI', stats!.batting!.rbi.toString()),
                        _StatGridItem('R', stats!.batting!.runs.toString()),
                        _StatGridItem('SB', stats!.batting!.stolenBases.toString()),
                        _StatGridItem('OBP', stats!.batting!.obp.toStringAsFixed(3)),
                        _StatGridItem('SLG', stats!.batting!.slg.toStringAsFixed(3)),
                        _StatGridItem('OPS', stats!.batting!.ops.toStringAsFixed(3)),
                        _StatGridItem('2B', stats!.batting!.doubles.toString()),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Pitching Stats
          if (stats!.pitching != null) ...[
            const Text(
              'Pitching Statistics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _StatGrid(
                  stats: [
                    _StatGridItem('W', stats!.pitching!.wins.toString()),
                    _StatGridItem('L', stats!.pitching!.losses.toString()),
                    _StatGridItem('ERA', stats!.pitching!.era.toStringAsFixed(2)),
                    _StatGridItem('G', stats!.pitching!.games.toString()),
                    _StatGridItem('GS', stats!.pitching!.gamesStarted.toString()),
                    _StatGridItem('SV', stats!.pitching!.saves.toString()),
                    _StatGridItem('IP', stats!.pitching!.inningsPitched.toStringAsFixed(1)),
                    _StatGridItem('SO', stats!.pitching!.strikeouts.toString()),
                    _StatGridItem('WHIP', stats!.pitching!.whip.toStringAsFixed(2)),
                    _StatGridItem('K/9', stats!.pitching!.k9.toStringAsFixed(2)),
                    _StatGridItem('BB/9', stats!.pitching!.bb9.toStringAsFixed(2)),
                    _StatGridItem('K/BB', stats!.pitching!.kbb.toStringAsFixed(2)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Season Bests
          if (stats!.seasonBests.isNotEmpty) ...[
            const Text(
              'Season Bests',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: stats!.seasonBests.entries.map((entry) {
                  return ListTile(
                    title: Text(entry.key),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatBestValue(entry.key, entry.value.value),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${entry.value.year})',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatBestValue(String code, double value) {
    if (['AVG', 'OBP', 'SLG', 'OPS'].contains(code)) {
      return value.toStringAsFixed(3);
    } else if (['ERA', 'WHIP'].contains(code)) {
      return value.toStringAsFixed(2);
    }
    return value.toInt().toString();
  }
}

class _StatGridItem {
  final String label;
  final String value;

  _StatGridItem(this.label, this.value);
}

class _StatGrid extends StatelessWidget {
  final List<_StatGridItem> stats;

  const _StatGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1.5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                stat.value,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                stat.label,
                style: TextStyle(color: Colors.grey[600], fontSize: 11),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SeasonsTab extends StatelessWidget {
  final List<PlayerSeasonStats> seasons;

  const _SeasonsTab({required this.seasons});

  @override
  Widget build(BuildContext context) {
    if (seasons.isEmpty) {
      return const Center(child: Text('No season data available'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: seasons.length,
      itemBuilder: (context, index) {
        final season = seasons[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            title: Text(
              '${season.seasonYear}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(season.teamName),
            children: [
              if (season.batting != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Batting',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      _StatGrid(
                        stats: [
                          _StatGridItem('G', season.batting!.gamesPlayed.toString()),
                          _StatGridItem('AVG', season.batting!.avg.toStringAsFixed(3)),
                          _StatGridItem('HR', season.batting!.homeRuns.toString()),
                          _StatGridItem('RBI', season.batting!.rbi.toString()),
                          _StatGridItem('R', season.batting!.runs.toString()),
                          _StatGridItem('SB', season.batting!.stolenBases.toString()),
                          _StatGridItem('OBP', season.batting!.obp.toStringAsFixed(3)),
                          _StatGridItem('OPS', season.batting!.ops.toStringAsFixed(3)),
                        ],
                      ),
                    ],
                  ),
                ),
              if (season.pitching != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pitching',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      _StatGrid(
                        stats: [
                          _StatGridItem('W', season.pitching!.wins.toString()),
                          _StatGridItem('L', season.pitching!.losses.toString()),
                          _StatGridItem('ERA', season.pitching!.era.toStringAsFixed(2)),
                          _StatGridItem('SV', season.pitching!.saves.toString()),
                          _StatGridItem('IP', season.pitching!.inningsPitched.toStringAsFixed(1)),
                          _StatGridItem('SO', season.pitching!.strikeouts.toString()),
                          _StatGridItem('WHIP', season.pitching!.whip.toStringAsFixed(2)),
                          _StatGridItem('K/9', season.pitching!.k9.toStringAsFixed(2)),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CompareTab extends StatelessWidget {
  final String leagueId;
  final String playerId;
  final PlayerComparison? comparison;
  final String selectedType;
  final int? selectedSeason;
  final List<int> availableSeasons;
  final Function(String) onTypeChanged;
  final Function(int?) onSeasonChanged;

  const _CompareTab({
    required this.leagueId,
    required this.playerId,
    required this.comparison,
    required this.selectedType,
    required this.selectedSeason,
    required this.availableSeasons,
    required this.onTypeChanged,
    required this.onSeasonChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Comparison Type Selector
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Compare MLB vs League Stats',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'single_season', label: Text('Season')),
                            ButtonSegment(value: 'career', label: Text('Career')),
                          ],
                          selected: {selectedType},
                          onSelectionChanged: (selection) => onTypeChanged(selection.first),
                        ),
                      ),
                    ],
                  ),
                  if (selectedType == 'single_season' && availableSeasons.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int?>(
                      value: selectedSeason ?? availableSeasons.first,
                      decoration: const InputDecoration(
                        labelText: 'Season',
                        border: OutlineInputBorder(),
                      ),
                      items: availableSeasons.map((year) {
                        return DropdownMenuItem(value: year, child: Text('$year'));
                      }).toList(),
                      onChanged: onSeasonChanged,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (comparison == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('Select options to compare'),
              ),
            )
          else ...[
            // Match Score Card
            Card(
              color: _getMatchScoreColor(comparison!.matchScore),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Text(
                        comparison!.consistencyRating,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _getMatchScoreColor(comparison!.matchScore),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Match Score',
                            style: TextStyle(color: Colors.white70),
                          ),
                          Text(
                            '${comparison!.matchScore.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Comparison Table Header
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Expanded(flex: 2, child: Text('Stat', style: TextStyle(fontWeight: FontWeight.bold))),
                    Expanded(child: Text('MLB', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[700]))),
                    Expanded(child: Text('League', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[700]))),
                    const Expanded(child: Text('Diff', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
            ),

            // Batting Comparison
            if (comparison!.batting != null) ...[
              const SizedBox(height: 8),
              const Text('Batting', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              _buildComparisonCard([
                if (comparison!.batting!.avg != null)
                  _ComparisonRow('AVG', comparison!.batting!.avg!, isRate: true),
                if (comparison!.batting!.hr != null)
                  _ComparisonRow('HR', comparison!.batting!.hr!),
                if (comparison!.batting!.rbi != null)
                  _ComparisonRow('RBI', comparison!.batting!.rbi!),
                if (comparison!.batting!.runs != null)
                  _ComparisonRow('R', comparison!.batting!.runs!),
                if (comparison!.batting!.sb != null)
                  _ComparisonRow('SB', comparison!.batting!.sb!),
                if (comparison!.batting!.hits != null)
                  _ComparisonRow('H', comparison!.batting!.hits!),
                if (comparison!.batting!.walks != null)
                  _ComparisonRow('BB', comparison!.batting!.walks!),
                if (comparison!.batting!.ops != null)
                  _ComparisonRow('OPS', comparison!.batting!.ops!, isRate: true),
              ]),
            ],

            // Pitching Comparison
            if (comparison!.pitching != null) ...[
              const SizedBox(height: 16),
              const Text('Pitching', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              _buildComparisonCard([
                if (comparison!.pitching!.era != null)
                  _ComparisonRow('ERA', comparison!.pitching!.era!, isRate: true, lowerIsBetter: true),
                if (comparison!.pitching!.wins != null)
                  _ComparisonRow('W', comparison!.pitching!.wins!),
                if (comparison!.pitching!.strikeouts != null)
                  _ComparisonRow('SO', comparison!.pitching!.strikeouts!),
                if (comparison!.pitching!.saves != null)
                  _ComparisonRow('SV', comparison!.pitching!.saves!),
                if (comparison!.pitching!.whip != null)
                  _ComparisonRow('WHIP', comparison!.pitching!.whip!, isRate: true, lowerIsBetter: true),
                if (comparison!.pitching!.ip != null)
                  _ComparisonRow('IP', comparison!.pitching!.ip!, isRate: true),
              ]),
            ],
          ],
        ],
      ),
    );
  }

  Color _getMatchScoreColor(double score) {
    if (score >= 90) return Colors.green[700]!;
    if (score >= 80) return Colors.lightGreen[700]!;
    if (score >= 70) return Colors.amber[700]!;
    if (score >= 60) return Colors.orange[700]!;
    return Colors.red[700]!;
  }

  Widget _buildComparisonCard(List<_ComparisonRow> rows) {
    return Card(
      child: Column(
        children: rows.map((row) => row.build()).toList(),
      ),
    );
  }
}

class _ComparisonRow {
  final String label;
  final StatComparison comparison;
  final bool isRate;
  final bool lowerIsBetter;

  _ComparisonRow(
    this.label,
    this.comparison, {
    this.isRate = false,
    this.lowerIsBetter = false,
  });

  Widget build() {
    final diff = comparison.difference;
    final isBetter = lowerIsBetter ? diff < 0 : diff > 0;
    final diffColor = diff == 0 ? Colors.grey : (isBetter ? Colors.green : Colors.red);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(
              _formatValue(comparison.mlb),
              style: TextStyle(color: Colors.blue[700]),
            ),
          ),
          Expanded(
            child: Text(
              _formatValue(comparison.league),
              style: TextStyle(color: Colors.green[700]),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                if (diff != 0)
                  Icon(
                    diff > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 12,
                    color: diffColor,
                  ),
                Text(
                  _formatDiff(diff),
                  style: TextStyle(color: diffColor, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatValue(double value) {
    if (isRate) {
      if (label == 'IP') return value.toStringAsFixed(1);
      return value.toStringAsFixed(label == 'ERA' || label == 'WHIP' ? 2 : 3);
    }
    return value.toInt().toString();
  }

  String _formatDiff(double diff) {
    if (diff == 0) return '0';
    final prefix = diff > 0 ? '+' : '';
    if (isRate) {
      if (label == 'IP') return '$prefix${diff.toStringAsFixed(1)}';
      return '$prefix${diff.toStringAsFixed(label == 'ERA' || label == 'WHIP' ? 2 : 3)}';
    }
    return '$prefix${diff.toInt()}';
  }
}
