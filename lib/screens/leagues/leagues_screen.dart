import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/league_provider.dart';
import '../../models/league.dart';
import '../../config/routes.dart';

class LeaguesScreen extends StatefulWidget {
  const LeaguesScreen({super.key});

  @override
  State<LeaguesScreen> createState() => _LeaguesScreenState();
}

class _LeaguesScreenState extends State<LeaguesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LeagueProvider>().loadLeagues();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        title: const Text('My Leagues'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.createLeague),
          ),
        ],
      ),
      body: Consumer<LeagueProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.leagues.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.emoji_events, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No leagues yet',
                    style: TextStyle(fontSize: 20, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create or join a league to get started',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.createLeague),
                        icon: const Icon(Icons.add),
                        label: const Text('Create'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.joinLeague),
                        icon: const Icon(Icons.login),
                        label: const Text('Join'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadLeagues(),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: provider.leagues.length,
              itemBuilder: (context, index) {
                final league = provider.leagues[index];
                return _LeagueCard(league: league);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.joinLeague),
        backgroundColor: Colors.green[700],
        child: const Icon(Icons.login, color: Colors.white),
      ),
    );
  }
}

class _LeagueCard extends StatelessWidget {
  final League league;

  const _LeagueCard({required this.league});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          context.read<LeagueProvider>().selectLeague(league);
          Navigator.pushNamed(
            context,
            AppRoutes.leagueDetail,
            arguments: {'leagueId': league.leagueId},
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.green[700],
                    child: const Icon(Icons.emoji_events, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          league.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${league.season} Season',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  _StatusChip(status: league.status),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _InfoItem(
                    icon: Icons.people,
                    label: 'Teams',
                    value: '${league.teamCount ?? 0}/${league.settings.maxTeams}',
                  ),
                  const SizedBox(width: 24),
                  _InfoItem(
                    icon: Icons.sports,
                    label: 'Format',
                    value: league.settings.draftFormat == 'serpentine' ? 'Serpentine' : 'Straight',
                  ),
                  const SizedBox(width: 24),
                  _InfoItem(
                    icon: Icons.timer,
                    label: 'Timer',
                    value: '${league.settings.pickTimer}s',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Invite Code: ${league.inviteCode}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    onPressed: () {
                      // Copy invite code
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Copied: ${league.inviteCode}')),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final LeagueStatus status;

  const _StatusChip({required this.status});

  Color get _color {
    switch (status) {
      case LeagueStatus.preDraft:
        return Colors.orange;
      case LeagueStatus.drafting:
        return Colors.blue;
      case LeagueStatus.inSeason:
        return Colors.green;
      case LeagueStatus.completed:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withAlpha(50),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(color: _color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 10)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
          ],
        ),
      ],
    );
  }
}
