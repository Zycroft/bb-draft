import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/encyclopedia.dart';
import '../../providers/encyclopedia_provider.dart';
import 'leaderboard_screen.dart';
import 'player_comparison_screen.dart';
import 'team_history_screen.dart';

class EncyclopediaDashboardScreen extends StatefulWidget {
  final String leagueId;
  final String leagueName;

  const EncyclopediaDashboardScreen({
    super.key,
    required this.leagueId,
    required this.leagueName,
  });

  @override
  State<EncyclopediaDashboardScreen> createState() =>
      _EncyclopediaDashboardScreenState();
}

class _EncyclopediaDashboardScreenState
    extends State<EncyclopediaDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final provider = context.read<EncyclopediaProvider>();
    await provider.loadSummary(widget.leagueId);
    await provider.loadLeaderboardCategories(widget.leagueId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        title: Text('${widget.leagueName} Encyclopedia'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Players'),
            Tab(text: 'Teams'),
            Tab(text: 'Search'),
          ],
        ),
      ),
      body: Consumer<EncyclopediaProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.summary == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.summary == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(provider.error!, style: TextStyle(color: Colors.red[700])),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _OverviewTab(leagueId: widget.leagueId, summary: provider.summary),
              _PlayersTab(leagueId: widget.leagueId, categories: provider.leaderboardCategories),
              _TeamsTab(leagueId: widget.leagueId),
              _SearchTab(leagueId: widget.leagueId, controller: _searchController),
            ],
          );
        },
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final String leagueId;
  final EncyclopediaSummary? summary;

  const _OverviewTab({required this.leagueId, required this.summary});

  @override
  Widget build(BuildContext context) {
    if (summary == null) {
      return const Center(child: Text('No data available'));
    }

    return RefreshIndicator(
      onRefresh: () => context.read<EncyclopediaProvider>().loadSummary(leagueId),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Overview Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(
                      label: 'Seasons',
                      value: '${summary!.totalSeasons}',
                      icon: Icons.calendar_today,
                    ),
                    _StatItem(
                      label: 'Players',
                      value: '${summary!.totalPlayers}',
                      icon: Icons.people,
                    ),
                    _StatItem(
                      label: 'Teams',
                      value: '${summary!.totalTeams}',
                      icon: Icons.groups,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Season Selector
            if (summary!.importedSeasons.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Imported Seasons',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: summary!.importedSeasons.map((year) {
                          return Chip(
                            label: Text('$year'),
                            backgroundColor: year == summary!.currentSeasonYear
                                ? Colors.green[100]
                                : null,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Batting Leaders
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _LeadersCard(
                    title: 'Batting Leaders',
                    leagueId: leagueId,
                    categories: [
                      _LeaderCategory('AVG', summary!.topBattingLeaders.avg),
                      _LeaderCategory('HR', summary!.topBattingLeaders.hr),
                      _LeaderCategory('RBI', summary!.topBattingLeaders.rbi),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _LeadersCard(
                    title: 'Pitching Leaders',
                    leagueId: leagueId,
                    categories: [
                      _LeaderCategory('ERA', summary!.topPitchingLeaders.era),
                      _LeaderCategory('W', summary!.topPitchingLeaders.wins),
                      _LeaderCategory('SO', summary!.topPitchingLeaders.so),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Team Standings
            if (summary!.teamStandings.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'All-Time Team Standings',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          TextButton(
                            onPressed: () {
                              // Navigate to full team standings
                            },
                            child: const Text('View All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...summary!.teamStandings.take(5).map((team) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: Colors.green[700],
                          child: Text(
                            '${team.rank}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(team.teamName),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${team.value.toInt()} W',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            if (team.championships != null)
                              Text(
                                '${team.championships} Champs',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.green[700], size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey[600]),
        ),
      ],
    );
  }
}

class _LeaderCategory {
  final String code;
  final List<LeaderboardEntry> entries;

  _LeaderCategory(this.code, this.entries);
}

class _LeadersCard extends StatelessWidget {
  final String title;
  final String leagueId;
  final List<_LeaderCategory> categories;

  const _LeadersCard({
    required this.title,
    required this.leagueId,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            ...categories.map((category) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      category.code,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.green[700],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LeaderboardScreen(
                              leagueId: leagueId,
                              statCode: category.code,
                            ),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                      ),
                      child: const Text('Top 10'),
                    ),
                  ],
                ),
                if (category.entries.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'No data',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  )
                else
                  ...category.entries.take(3).map((entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Text(
                          '${entry.rank}. ',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                        Expanded(
                          child: Text(
                            entry.playerName.split(' ').last,
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          _formatValue(entry.value, category.code),
                          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                        ),
                      ],
                    ),
                  )),
                const SizedBox(height: 8),
              ],
            )),
          ],
        ),
      ),
    );
  }

  String _formatValue(double value, String code) {
    if (['AVG', 'OBP', 'SLG', 'OPS', 'WPCT'].contains(code)) {
      return value.toStringAsFixed(3).replaceFirst('0.', '.');
    } else if (['ERA', 'WHIP', 'K9', 'BB9', 'KBB'].contains(code)) {
      return value.toStringAsFixed(2);
    } else if (code == 'IP') {
      return value.toStringAsFixed(1);
    }
    return value.toInt().toString();
  }
}

class _PlayersTab extends StatelessWidget {
  final String leagueId;
  final LeaderboardCategories? categories;

  const _PlayersTab({required this.leagueId, required this.categories});

  @override
  Widget build(BuildContext context) {
    if (categories == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: const TabBar(
              labelColor: Colors.green,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.green,
              tabs: [
                Tab(text: 'Batting'),
                Tab(text: 'Pitching'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _StatCategoriesList(
                  leagueId: leagueId,
                  categories: categories!.batting,
                ),
                _StatCategoriesList(
                  leagueId: leagueId,
                  categories: categories!.pitching,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCategoriesList extends StatelessWidget {
  final String leagueId;
  final List<StatCategory> categories;

  const _StatCategoriesList({
    required this.leagueId,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(category.name),
            subtitle: Text(category.description),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (category.isRate)
                  Chip(
                    label: const Text('Rate'),
                    labelStyle: const TextStyle(fontSize: 10),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LeaderboardScreen(
                    leagueId: leagueId,
                    statCode: category.code,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _TeamsTab extends StatelessWidget {
  final String leagueId;

  const _TeamsTab({required this.leagueId});

  @override
  Widget build(BuildContext context) {
    return Consumer<EncyclopediaProvider>(
      builder: (context, provider, _) {
        if (provider.teamStats.isEmpty) {
          // Load team stats if not loaded
          WidgetsBinding.instance.addPostFrameCallback((_) {
            provider.loadAllTeamStats(leagueId);
          });
          return const Center(child: CircularProgressIndicator());
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.teamStats.length,
          itemBuilder: (context, index) {
            final team = provider.teamStats[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green[700],
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(team.teamName),
                subtitle: Text(
                  '${team.allTime.regularSeason.wins}-${team.allTime.regularSeason.losses} '
                  '(${(team.allTime.regularSeason.winningPercentage * 100).toStringAsFixed(1)}%)',
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (team.allTime.championships.wins > 0)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.emoji_events, color: Colors.amber[700], size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${team.allTime.championships.wins}',
                            style: TextStyle(color: Colors.amber[700], fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    Text(
                      'Dynasty: ${team.dynastyScore.toInt()}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TeamHistoryScreen(
                        leagueId: leagueId,
                        teamId: team.teamId,
                        teamName: team.teamName,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

class _SearchTab extends StatelessWidget {
  final String leagueId;
  final TextEditingController controller;

  const _SearchTab({required this.leagueId, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Search players or teams...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
              suffixIcon: controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        controller.clear();
                        context.read<EncyclopediaProvider>().clearSearch();
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              context.read<EncyclopediaProvider>().search(leagueId, value);
            },
          ),
        ),
        Expanded(
          child: Consumer<EncyclopediaProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final results = provider.searchResults;
              if (results == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Search for players or teams',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              if (results.players.isEmpty && results.teams.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No results found',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  if (results.players.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Players',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    ...results.players.map((player) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue[100],
                          child: Icon(Icons.person, color: Colors.blue[700]),
                        ),
                        title: Text(player.playerName),
                        subtitle: Text('${player.teamName} - ${player.seasonYear}'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PlayerComparisonScreen(
                                leagueId: leagueId,
                                playerId: player.playerId,
                                playerName: player.playerName,
                              ),
                            ),
                          );
                        },
                      ),
                    )),
                  ],
                  if (results.teams.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Teams',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    ...results.teams.map((team) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green[100],
                          child: Icon(Icons.groups, color: Colors.green[700]),
                        ),
                        title: Text(team.teamName),
                        subtitle: Text(
                          '${team.allTime.regularSeason.wins}-${team.allTime.regularSeason.losses}',
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TeamHistoryScreen(
                                leagueId: leagueId,
                                teamId: team.teamId,
                                teamName: team.teamName,
                              ),
                            ),
                          );
                        },
                      ),
                    )),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
