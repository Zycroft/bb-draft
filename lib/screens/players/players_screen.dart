import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/player_provider.dart';
import '../../models/player.dart';

class PlayersScreen extends StatefulWidget {
  final String? leagueId; // Optional - if provided, shows eligibility controls

  const PlayersScreen({super.key, this.leagueId});

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  // Filters
  String? _selectedTeam;
  String? _selectedPosition;
  String _sortBy = 'name';
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PlayerProvider>();
      provider.loadBatters();
      provider.loadPitchers();
      // Load eligibilities if we have a league context
      if (widget.leagueId != null) {
        provider.loadEligibilities(widget.leagueId!);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Player> _filterAndSort(List<Player> players) {
    var filtered = players.where((p) {
      if (_selectedTeam != null && p.mlbTeam != _selectedTeam) return false;
      if (_selectedPosition != null && p.primaryPosition != _selectedPosition) return false;
      return true;
    }).toList();

    filtered.sort((a, b) {
      int compare;
      switch (_sortBy) {
        case 'name':
          compare = a.lastName.compareTo(b.lastName);
          break;
        case 'team':
          compare = a.mlbTeam.compareTo(b.mlbTeam);
          break;
        case 'position':
          compare = a.primaryPosition.compareTo(b.primaryPosition);
          break;
        case 'avg':
          final aAvg = double.tryParse(a.battingStats?.avg.replaceAll('.', '0.') ?? '0') ?? 0;
          final bAvg = double.tryParse(b.battingStats?.avg.replaceAll('.', '0.') ?? '0') ?? 0;
          compare = bAvg.compareTo(aAvg);
          break;
        case 'hr':
          compare = (b.battingStats?.homeRuns ?? 0).compareTo(a.battingStats?.homeRuns ?? 0);
          break;
        case 'era':
          final aEra = double.tryParse(a.pitchingStats?.era ?? '99') ?? 99;
          final bEra = double.tryParse(b.pitchingStats?.era ?? '99') ?? 99;
          compare = aEra.compareTo(bEra);
          break;
        case 'wins':
          compare = (b.pitchingStats?.wins ?? 0).compareTo(a.pitchingStats?.wins ?? 0);
          break;
        default:
          compare = 0;
      }
      return _sortAscending ? compare : -compare;
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        title: const Text('Players'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterSheet,
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _showSortSheet,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Batters'),
            Tab(text: 'Pitchers'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search players...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context.read<PlayerProvider>().clearSearch();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: (value) {
                context.read<PlayerProvider>().searchPlayers(value);
              },
            ),
          ),

          // Active filters chip bar
          if (_selectedTeam != null || _selectedPosition != null)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
              child: Row(
                children: [
                  if (_selectedTeam != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        label: Text(_selectedTeam!),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () => setState(() => _selectedTeam = null),
                      ),
                    ),
                  if (_selectedPosition != null)
                    Chip(
                      label: Text(_selectedPosition!),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => setState(() => _selectedPosition = null),
                    ),
                ],
              ),
            ),

          // Tab content
          Expanded(
            child: Consumer<PlayerProvider>(
              builder: (context, provider, _) {
                // Show search results if searching
                if (provider.searchQuery.isNotEmpty) {
                  return _buildPlayerList(
                    _filterAndSort(provider.searchResults),
                    provider.isSearching,
                    'No players found',
                  );
                }

                return TabBarView(
                  controller: _tabController,
                  children: [
                    // Batters tab
                    _buildPlayerList(
                      _filterAndSort(provider.batters),
                      provider.isLoadingBatters,
                      'No batters found',
                    ),
                    // Pitchers tab
                    _buildPlayerList(
                      _filterAndSort(provider.pitchers),
                      provider.isLoadingPitchers,
                      'No pitchers found',
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerList(List<Player> players, bool isLoading, String emptyMessage) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (players.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_baseball, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(emptyMessage, style: TextStyle(color: Colors.grey[600], fontSize: 16)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        final provider = context.read<PlayerProvider>();
        await provider.loadBatters();
        await provider.loadPitchers();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: players.length,
        itemBuilder: (context, index) {
          final player = players[index];
          return _PlayerCard(
            player: player,
            leagueId: widget.leagueId,
          );
        },
      ),
    );
  }

  void _showFilterSheet() {
    final provider = context.read<PlayerProvider>();
    final allPlayers = [...provider.batters, ...provider.pitchers];
    final teams = allPlayers.map((p) => p.mlbTeam).toSet().toList()..sort();
    final positions = allPlayers.map((p) => p.primaryPosition).toSet().toList()..sort();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filter Players', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('Team', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: const Text('All'),
                      selected: _selectedTeam == null,
                      onSelected: (_) {
                        setState(() => _selectedTeam = null);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  ...teams.map((team) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(team),
                      selected: _selectedTeam == team,
                      onSelected: (_) {
                        setState(() => _selectedTeam = team);
                        Navigator.pop(context);
                      },
                    ),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Position', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: _selectedPosition == null,
                  onSelected: (_) {
                    setState(() => _selectedPosition = null);
                    Navigator.pop(context);
                  },
                ),
                ...positions.map((pos) => ChoiceChip(
                  label: Text(pos),
                  selected: _selectedPosition == pos,
                  onSelected: (_) {
                    setState(() => _selectedPosition = pos);
                    Navigator.pop(context);
                  },
                )),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showSortSheet() {
    final isBatterTab = _tabController.index == 0;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sort By', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...[
              ('name', 'Name'),
              ('team', 'Team'),
              ('position', 'Position'),
              if (isBatterTab) ...[ ('avg', 'Batting Average'), ('hr', 'Home Runs') ],
              if (!isBatterTab) ...[ ('era', 'ERA'), ('wins', 'Wins') ],
            ].map((item) => ListTile(
              title: Text(item.$2),
              trailing: _sortBy == item.$1
                  ? Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward, color: Colors.green[700])
                  : null,
              onTap: () {
                setState(() {
                  if (_sortBy == item.$1) {
                    _sortAscending = !_sortAscending;
                  } else {
                    _sortBy = item.$1;
                    _sortAscending = true;
                  }
                });
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  final Player player;
  final String? leagueId;

  const _PlayerCard({required this.player, this.leagueId});

  @override
  Widget build(BuildContext context) {
    // Get eligibility from provider if we have a league context
    final eligibility = leagueId != null
        ? context.watch<PlayerProvider>().getPlayerEligibility(player.playerId)
        : player.eligibility;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () => _showPlayerDetail(context, player),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Position badge
              CircleAvatar(
                radius: 22,
                backgroundColor: player.isPitcher ? Colors.blue[700] : Colors.green[700],
                child: Text(
                  player.primaryPosition,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
              const SizedBox(width: 12),

              // Player info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            player.fullName,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                        ),
                        if (leagueId != null) _EligibilityBadge(eligibility: eligibility),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          player.mlbTeam,
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                        if (player.jerseyNumber != null) ...[
                          Text(' #${player.jerseyNumber}', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                        ],
                        const Spacer(),
                        _buildQuickStats(player),
                      ],
                    ),
                  ],
                ),
              ),

              // Eligibility toggle (if leagueId provided)
              if (leagueId != null) ...[
                const SizedBox(width: 8),
                _EligibilityToggle(player: player, leagueId: leagueId!, eligibility: eligibility),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats(Player player) {
    if (player.isPitcher && player.pitchingStats != null) {
      final stats = player.pitchingStats!;
      return Row(
        children: [
          _MiniStat(label: 'ERA', value: stats.era),
          const SizedBox(width: 12),
          _MiniStat(label: 'W', value: '${stats.wins}'),
          const SizedBox(width: 12),
          _MiniStat(label: 'K', value: '${stats.strikeouts}'),
        ],
      );
    } else if (player.battingStats != null) {
      final stats = player.battingStats!;
      return Row(
        children: [
          _MiniStat(label: 'AVG', value: stats.avg),
          const SizedBox(width: 12),
          _MiniStat(label: 'HR', value: '${stats.homeRuns}'),
          const SizedBox(width: 12),
          _MiniStat(label: 'RBI', value: '${stats.rbi}'),
        ],
      );
    }
    return const SizedBox();
  }

  void _showPlayerDetail(BuildContext context, Player player) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => _PlayerDetailSheet(
          player: player,
          scrollController: scrollController,
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 10)),
      ],
    );
  }
}

class _EligibilityBadge extends StatelessWidget {
  final DraftEligibility eligibility;

  const _EligibilityBadge({required this.eligibility});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;

    switch (eligibility) {
      case DraftEligibility.eligible:
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case DraftEligibility.onTeam:
        color = Colors.blue;
        icon = Icons.people;
        break;
      case DraftEligibility.notEligible:
        color = Colors.grey;
        icon = Icons.block;
        break;
    }

    return Icon(icon, size: 18, color: color);
  }
}

class _EligibilityToggle extends StatelessWidget {
  final Player player;
  final String leagueId;
  final DraftEligibility eligibility;

  const _EligibilityToggle({
    required this.player,
    required this.leagueId,
    required this.eligibility,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<DraftEligibility>(
      icon: Icon(
        _getIcon(eligibility),
        color: _getColor(eligibility),
      ),
      onSelected: (newEligibility) {
        context.read<PlayerProvider>().setPlayerEligibility(
          player.playerId,
          leagueId,
          newEligibility,
        );
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: DraftEligibility.eligible,
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[700]),
              const SizedBox(width: 8),
              const Text('Eligible'),
            ],
          ),
        ),
        PopupMenuItem(
          value: DraftEligibility.onTeam,
          child: Row(
            children: [
              Icon(Icons.people, color: Colors.blue[700]),
              const SizedBox(width: 8),
              const Text('On a Team'),
            ],
          ),
        ),
        PopupMenuItem(
          value: DraftEligibility.notEligible,
          child: Row(
            children: [
              Icon(Icons.block, color: Colors.grey[600]),
              const SizedBox(width: 8),
              const Text('Not Eligible'),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getIcon(DraftEligibility eligibility) {
    switch (eligibility) {
      case DraftEligibility.eligible:
        return Icons.check_circle;
      case DraftEligibility.onTeam:
        return Icons.people;
      case DraftEligibility.notEligible:
        return Icons.block;
    }
  }

  Color _getColor(DraftEligibility eligibility) {
    switch (eligibility) {
      case DraftEligibility.eligible:
        return Colors.green;
      case DraftEligibility.onTeam:
        return Colors.blue;
      case DraftEligibility.notEligible:
        return Colors.grey;
    }
  }
}

class _PlayerDetailSheet extends StatelessWidget {
  final Player player;
  final ScrollController scrollController;

  const _PlayerDetailSheet({
    required this.player,
    required this.scrollController,
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
                radius: 35,
                backgroundColor: player.isPitcher ? Colors.blue[700] : Colors.green[700],
                child: Text(
                  player.primaryPosition,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.fullName,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${player.mlbTeam}${player.jerseyNumber != null ? ' #${player.jerseyNumber}' : ''}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    _EligibilityChip(eligibility: player.eligibility),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Player info
          _buildSection('Info', [
            _buildInfoRow('Position', player.primaryPosition),
            _buildInfoRow('Bats/Throws', '${player.batSide}/${player.pitchHand}'),
            if (player.height != null) _buildInfoRow('Height', player.height!),
            if (player.weight != null) _buildInfoRow('Weight', '${player.weight} lbs'),
            if (player.birthDate != null) _buildInfoRow('Birth Date', player.birthDate!),
            if (player.mlbDebutDate != null) _buildInfoRow('MLB Debut', player.mlbDebutDate!),
          ]),

          // WAR Metrics
          if (player.warMetrics != null) ...[
            const SizedBox(height: 20),
            _buildSection('WAR', [
              if (player.warMetrics!.fWAR != null)
                _StatChip(label: 'fWAR', value: player.warMetrics!.fWAR!.toStringAsFixed(1)),
              if (player.warMetrics!.bWAR != null)
                _StatChip(label: 'bWAR', value: player.warMetrics!.bWAR!.toStringAsFixed(1)),
            ]),
          ],

          // Scouting Grades
          if (player.scoutingGrades != null) ...[
            const SizedBox(height: 20),
            _buildScoutingGrades(player.scoutingGrades!),
          ],

          // Statistics section
          const SizedBox(height: 20),
          const Text('Statistics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          if (player.isPitcher && player.pitchingStats != null)
            _buildPitchingStats(player.pitchingStats!)
          else if (player.battingStats != null)
            _buildBattingStats(player.battingStats!)
          else
            Text('No statistics available', style: TextStyle(color: Colors.grey[600])),

          // Statcast Metrics
          if (player.statcastHitting != null) ...[
            const SizedBox(height: 20),
            _buildStatcastHitting(player.statcastHitting!),
          ],
          if (player.statcastPitching != null) ...[
            const SizedBox(height: 20),
            _buildStatcastPitching(player.statcastPitching!),
          ],

          // Fielding Metrics
          if (player.fieldingMetrics != null) ...[
            const SizedBox(height: 20),
            _buildFieldingMetrics(player.fieldingMetrics!),
          ],

          // Catcher Metrics
          if (player.isCatcher && player.catcherMetrics != null) ...[
            const SizedBox(height: 20),
            _buildCatcherMetrics(player.catcherMetrics!),
          ],
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...children,
      ],
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

  Widget _buildScoutingGrades(ScoutingGrades grades) {
    final gradeList = <MapEntry<String, int?>>[];
    if (grades.hit != null) gradeList.add(MapEntry('Hit', grades.hit));
    if (grades.gamePower != null) gradeList.add(MapEntry('Power', grades.gamePower));
    if (grades.speed != null) gradeList.add(MapEntry('Speed', grades.speed));
    if (grades.field != null) gradeList.add(MapEntry('Field', grades.field));
    if (grades.arm != null) gradeList.add(MapEntry('Arm', grades.arm));

    if (gradeList.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Scouting Grades (20-80)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: gradeList.map((e) => _GradeChip(label: e.key, grade: e.value!)).toList(),
        ),
      ],
    );
  }

  Widget _buildBattingStats(BatterStats stats) {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      children: [
        _StatChip(label: 'AVG', value: stats.avg),
        _StatChip(label: 'OBP', value: stats.obp),
        _StatChip(label: 'SLG', value: stats.slg),
        _StatChip(label: 'OPS', value: stats.ops),
        _StatChip(label: 'HR', value: stats.homeRuns.toString()),
        _StatChip(label: 'RBI', value: stats.rbi.toString()),
        _StatChip(label: 'R', value: stats.runs.toString()),
        _StatChip(label: 'H', value: stats.hits.toString()),
        _StatChip(label: '2B', value: stats.doubles.toString()),
        _StatChip(label: '3B', value: stats.triples.toString()),
        _StatChip(label: 'SB', value: stats.stolenBases.toString()),
        _StatChip(label: 'BB', value: stats.walks.toString()),
        _StatChip(label: 'SO', value: stats.strikeouts.toString()),
        _StatChip(label: 'G', value: stats.gamesPlayed.toString()),
        _StatChip(label: 'AB', value: stats.atBats.toString()),
      ],
    );
  }

  Widget _buildPitchingStats(PitcherStats stats) {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      children: [
        _StatChip(label: 'ERA', value: stats.era),
        _StatChip(label: 'W', value: stats.wins.toString()),
        _StatChip(label: 'L', value: stats.losses.toString()),
        _StatChip(label: 'WHIP', value: stats.whip),
        _StatChip(label: 'K', value: stats.strikeouts.toString()),
        _StatChip(label: 'BB', value: stats.walks.toString()),
        _StatChip(label: 'IP', value: stats.inningsPitched),
        _StatChip(label: 'SV', value: stats.saves.toString()),
        _StatChip(label: 'G', value: stats.games.toString()),
        _StatChip(label: 'GS', value: stats.gamesStarted.toString()),
        _StatChip(label: 'H', value: stats.hits.toString()),
        _StatChip(label: 'HR', value: stats.homeRuns.toString()),
        if (stats.kPer9 != null) _StatChip(label: 'K/9', value: stats.kPer9!),
        if (stats.bbPer9 != null) _StatChip(label: 'BB/9', value: stats.bbPer9!),
      ],
    );
  }

  Widget _buildStatcastHitting(StatcastHittingMetrics stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Statcast Hitting', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
            if (stats.exitVelocity != null) _StatChip(label: 'Exit Velo', value: '${stats.exitVelocity!.toStringAsFixed(1)} mph'),
            if (stats.launchAngle != null) _StatChip(label: 'LA', value: '${stats.launchAngle!.toStringAsFixed(1)}°'),
            if (stats.barrelPercent != null) _StatChip(label: 'Barrel%', value: '${stats.barrelPercent!.toStringAsFixed(1)}%'),
            if (stats.hardHitPercent != null) _StatChip(label: 'Hard Hit%', value: '${stats.hardHitPercent!.toStringAsFixed(1)}%'),
            if (stats.xBA != null) _StatChip(label: 'xBA', value: '.${(stats.xBA! * 1000).toInt()}'),
            if (stats.xSLG != null) _StatChip(label: 'xSLG', value: '.${(stats.xSLG! * 1000).toInt()}'),
            if (stats.xwOBA != null) _StatChip(label: 'xwOBA', value: '.${(stats.xwOBA! * 1000).toInt()}'),
            if (stats.sprintSpeed != null) _StatChip(label: 'Sprint', value: '${stats.sprintSpeed!.toStringAsFixed(1)} ft/s'),
          ],
        ),
      ],
    );
  }

  Widget _buildStatcastPitching(StatcastPitchingMetrics stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Statcast Pitching', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
            if (stats.pitchVelocity != null) _StatChip(label: 'Velo', value: '${stats.pitchVelocity!.toStringAsFixed(1)} mph'),
            if (stats.spinRate != null) _StatChip(label: 'Spin', value: '${stats.spinRate} rpm'),
            if (stats.xERA != null) _StatChip(label: 'xERA', value: stats.xERA!.toStringAsFixed(2)),
            if (stats.whiffPercent != null) _StatChip(label: 'Whiff%', value: '${stats.whiffPercent!.toStringAsFixed(1)}%'),
            if (stats.kPercent != null) _StatChip(label: 'K%', value: '${stats.kPercent!.toStringAsFixed(1)}%'),
            if (stats.chasePercent != null) _StatChip(label: 'Chase%', value: '${stats.chasePercent!.toStringAsFixed(1)}%'),
          ],
        ),
      ],
    );
  }

  Widget _buildFieldingMetrics(FieldingMetrics stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Fielding', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
            if (stats.oaa != null) _StatChip(label: 'OAA', value: stats.oaa.toString()),
            if (stats.fieldingRunValue != null) _StatChip(label: 'FRV', value: stats.fieldingRunValue!.toStringAsFixed(1)),
            if (stats.armStrength != null) _StatChip(label: 'Arm', value: '${stats.armStrength!.toStringAsFixed(1)} mph'),
          ],
        ),
      ],
    );
  }

  Widget _buildCatcherMetrics(CatcherMetrics stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Catching', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
            if (stats.popTime != null) _StatChip(label: 'Pop Time', value: '${stats.popTime!.toStringAsFixed(2)}s'),
            if (stats.framingRunValue != null) _StatChip(label: 'Framing', value: stats.framingRunValue!.toStringAsFixed(1)),
            if (stats.blocksAboveAverage != null) _StatChip(label: 'Blocks AA', value: stats.blocksAboveAverage!.toStringAsFixed(1)),
            if (stats.caughtStealingPercent != null) _StatChip(label: 'CS%', value: '${stats.caughtStealingPercent!.toStringAsFixed(1)}%'),
          ],
        ),
      ],
    );
  }
}

class _EligibilityChip extends StatelessWidget {
  final DraftEligibility eligibility;

  const _EligibilityChip({required this.eligibility});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;

    switch (eligibility) {
      case DraftEligibility.eligible:
        color = Colors.green;
        text = 'Eligible';
        break;
      case DraftEligibility.onTeam:
        color = Colors.blue;
        text = 'On Team';
        break;
      case DraftEligibility.notEligible:
        color = Colors.grey;
        text = 'Not Eligible';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
      ),
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
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        ],
      ),
    );
  }
}

class _GradeChip extends StatelessWidget {
  final String label;
  final int grade;

  const _GradeChip({required this.label, required this.grade});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _getGradeColor(grade).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getGradeColor(grade)),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 11)),
          Text(
            grade.toString(),
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: _getGradeColor(grade)),
          ),
          Text(
            ScoutingGrades.gradeDescription(grade),
            style: TextStyle(fontSize: 9, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Color _getGradeColor(int grade) {
    if (grade >= 70) return Colors.green[700]!;
    if (grade >= 55) return Colors.blue[700]!;
    if (grade >= 45) return Colors.orange[700]!;
    return Colors.red[700]!;
  }
}
