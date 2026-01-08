import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/encyclopedia.dart';
import '../../providers/encyclopedia_provider.dart';

class TeamHistoryScreen extends StatefulWidget {
  final String leagueId;
  final String teamId;
  final String teamName;

  const TeamHistoryScreen({
    super.key,
    required this.leagueId,
    required this.teamId,
    required this.teamName,
  });

  @override
  State<TeamHistoryScreen> createState() => _TeamHistoryScreenState();
}

class _TeamHistoryScreenState extends State<TeamHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    context.read<EncyclopediaProvider>().clearTeamData();
    super.dispose();
  }

  Future<void> _loadData() async {
    await context.read<EncyclopediaProvider>().loadTeamStats(
          widget.leagueId,
          widget.teamId,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        title: Text(widget.teamName),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Seasons'),
          ],
        ),
      ),
      body: Consumer<EncyclopediaProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.selectedTeam == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final team = provider.selectedTeam;
          if (team == null) {
            return const Center(child: Text('Team not found'));
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _OverviewTab(team: team),
              _SeasonsTab(team: team),
            ],
          );
        },
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final TeamHistoricalStats team;

  const _OverviewTab({required this.team});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Team Header Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.green[100],
                    child: Icon(Icons.groups, size: 48, color: Colors.green[700]),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    team.teamName,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _DynastyBadge(score: team.dynastyScore),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // All-Time Record
          const Text(
            'All-Time Record',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _RecordRow(
                    label: 'Regular Season',
                    wins: team.allTime.regularSeason.wins,
                    losses: team.allTime.regularSeason.losses,
                    pct: team.allTime.regularSeason.winningPercentage,
                  ),
                  const Divider(),
                  _RecordRow(
                    label: 'Postseason',
                    wins: team.allTime.postseason.wins,
                    losses: team.allTime.postseason.losses,
                    pct: team.allTime.postseason.winningPercentage,
                    appearances: team.allTime.postseason.appearances,
                  ),
                  const Divider(),
                  _RecordRow(
                    label: 'Championships',
                    wins: team.allTime.championships.wins,
                    losses: team.allTime.championships.losses,
                    pct: team.allTime.championships.winningPercentage,
                    appearances: team.allTime.championships.appearances,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Championships
          if (team.allTime.championships.years.isNotEmpty) ...[
            const Text(
              'Championships',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.emoji_events, color: Colors.amber[700], size: 32),
                        const SizedBox(width: 12),
                        Text(
                          '${team.allTime.championships.wins} Championships',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: team.allTime.championships.years.map((year) {
                        return Chip(
                          avatar: Icon(Icons.emoji_events, color: Colors.amber[700], size: 16),
                          label: Text('$year'),
                          backgroundColor: Colors.amber[50],
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Scoring Stats
          const Text(
            'Scoring Statistics',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _StatRow(
                    label: 'Total Points For',
                    value: team.allTime.regularSeason.pointsFor.toStringAsFixed(1),
                  ),
                  _StatRow(
                    label: 'Total Points Against',
                    value: team.allTime.regularSeason.pointsAgainst.toStringAsFixed(1),
                  ),
                  _StatRow(
                    label: 'Point Differential',
                    value: _formatDifferential(team.allTime.regularSeason.pointDifferential),
                    valueColor: team.allTime.regularSeason.pointDifferential >= 0
                        ? Colors.green
                        : Colors.red,
                  ),
                  _StatRow(
                    label: 'Avg Points/Season',
                    value: team.seasons.isNotEmpty
                        ? (team.allTime.regularSeason.pointsFor / team.seasons.length)
                            .toStringAsFixed(1)
                        : '0',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDifferential(double diff) {
    if (diff >= 0) return '+${diff.toStringAsFixed(1)}';
    return diff.toStringAsFixed(1);
  }
}

class _DynastyBadge extends StatelessWidget {
  final double score;

  const _DynastyBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    String tier;

    if (score >= 50) {
      badgeColor = Colors.amber[700]!;
      tier = 'Dynasty';
    } else if (score >= 30) {
      badgeColor = Colors.purple[600]!;
      tier = 'Elite';
    } else if (score >= 15) {
      badgeColor = Colors.blue[600]!;
      tier = 'Contender';
    } else {
      badgeColor = Colors.grey[600]!;
      tier = 'Rebuilding';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.stars, color: badgeColor, size: 20),
          const SizedBox(width: 8),
          Text(
            tier,
            style: TextStyle(
              color: badgeColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${score.toInt()}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordRow extends StatelessWidget {
  final String label;
  final int wins;
  final int losses;
  final double pct;
  final int? appearances;

  const _RecordRow({
    required this.label,
    required this.wins,
    required this.losses,
    required this.pct,
    this.appearances,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(
              '$wins-$losses',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              '(${(pct * 100).toStringAsFixed(1)}%)',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          if (appearances != null)
            Text(
              '$appearances app.',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _StatRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _SeasonsTab extends StatelessWidget {
  final TeamHistoricalStats team;

  const _SeasonsTab({required this.team});

  @override
  Widget build(BuildContext context) {
    if (team.seasons.isEmpty) {
      return const Center(child: Text('No season data available'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: team.seasons.length,
      itemBuilder: (context, index) {
        final season = team.seasons[index];
        return _SeasonCard(season: season);
      },
    );
  }
}

class _SeasonCard extends StatelessWidget {
  final TeamSeasonRecord season;

  const _SeasonCard({required this.season});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '${season.year}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (season.champion)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber[100],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.emoji_events, color: Colors.amber[700], size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Champion',
                          style: TextStyle(
                            color: Colors.amber[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _SeasonStat(
                  label: 'Record',
                  value: '${season.wins}-${season.losses}',
                ),
                _SeasonStat(
                  label: 'Win %',
                  value: '${(season.winningPercentage * 100).toStringAsFixed(1)}%',
                ),
                _SeasonStat(
                  label: 'Finish',
                  value: _formatFinish(season.standingsPosition),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _SeasonStat(
                  label: 'Points For',
                  value: season.pointsFor.toStringAsFixed(1),
                ),
                _SeasonStat(
                  label: 'Points Against',
                  value: season.pointsAgainst.toStringAsFixed(1),
                ),
                _SeasonStat(
                  label: 'Diff',
                  value: _formatDiff(season.pointsFor - season.pointsAgainst),
                  valueColor: season.pointsFor >= season.pointsAgainst
                      ? Colors.green
                      : Colors.red,
                ),
              ],
            ),
            if (season.playoffResult != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sports_baseball, color: Colors.blue[700], size: 16),
                    const SizedBox(width: 8),
                    Text(
                      season.playoffResult!,
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatFinish(int position) {
    if (position == 1) return '1st';
    if (position == 2) return '2nd';
    if (position == 3) return '3rd';
    return '${position}th';
  }

  String _formatDiff(double diff) {
    if (diff >= 0) return '+${diff.toStringAsFixed(1)}';
    return diff.toStringAsFixed(1);
  }
}

class _SeasonStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SeasonStat({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[600], fontSize: 11),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
