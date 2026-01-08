import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/league_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/draft_provider.dart';
import '../../models/league.dart';
import '../../config/routes.dart';
import '../draft/draft_configuration_screen.dart';

class LeagueDetailScreen extends StatefulWidget {
  final String leagueId;

  const LeagueDetailScreen({super.key, required this.leagueId});

  @override
  State<LeagueDetailScreen> createState() => _LeagueDetailScreenState();
}

class _LeagueDetailScreenState extends State<LeagueDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadLeague();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLeague() async {
    await context.read<LeagueProvider>().loadLeagueDetails(widget.leagueId);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LeagueProvider>(
      builder: (context, provider, _) {
        final league = provider.selectedLeague;

        if (provider.isLoading || league == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('League'),
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final isCommissioner = league.isCommissioner(
          context.read<AuthProvider>().user?.uid ?? '',
        );

        return Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: AppBar(
            backgroundColor: Colors.green[700],
            foregroundColor: Colors.white,
            title: Text(league.name),
            actions: [
              if (isCommissioner)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) => _handleMenuAction(value, league),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'settings',
                      child: Row(
                        children: [
                          Icon(Icons.settings, color: Colors.grey),
                          SizedBox(width: 8),
                          Text('League Settings'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'announce',
                      child: Row(
                        children: [
                          Icon(Icons.campaign, color: Colors.grey),
                          SizedBox(width: 8),
                          Text('Send Announcement'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'regenerate',
                      child: Row(
                        children: [
                          Icon(Icons.refresh, color: Colors.grey),
                          SizedBox(width: 8),
                          Text('New Invite Code'),
                        ],
                      ),
                    ),
                    if (league.status == LeagueStatus.preDraft)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete League', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                  ],
                ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Teams'),
                Tab(text: 'Draft'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _OverviewTab(league: league, isCommissioner: isCommissioner),
              _TeamsTab(league: league, isCommissioner: isCommissioner),
              _DraftTab(league: league, isCommissioner: isCommissioner),
            ],
          ),
        );
      },
    );
  }

  void _handleMenuAction(String action, League league) {
    switch (action) {
      case 'settings':
        _showSettings(league);
        break;
      case 'announce':
        _showAnnouncementDialog();
        break;
      case 'regenerate':
        _regenerateInviteCode();
        break;
      case 'delete':
        _confirmDeleteLeague();
        break;
    }
  }

  void _showSettings(League league) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        expand: false,
        builder: (context, scrollController) => _LeagueSettingsSheet(
          league: league,
          scrollController: scrollController,
        ),
      ),
    );
  }

  void _showAnnouncementDialog() {
    final messageController = TextEditingController();
    final titleController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Announcement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
                hintText: 'Enter your announcement...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (messageController.text.trim().isEmpty) return;
              await context.read<LeagueProvider>().sendAnnouncement(
                widget.leagueId,
                messageController.text.trim(),
                title: titleController.text.trim().isNotEmpty
                    ? titleController.text.trim()
                    : null,
              );
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Announcement sent!')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
            child: const Text('Send', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _regenerateInviteCode() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Regenerate Invite Code?'),
        content: const Text(
          'The old invite code will stop working. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Regenerate'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<LeagueProvider>().regenerateInviteCode(widget.leagueId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New invite code generated!')),
        );
      }
    }
  }

  void _confirmDeleteLeague() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete League?'),
        content: const Text(
          'This action cannot be undone. All teams and data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await context.read<LeagueProvider>().deleteLeague(widget.leagueId);
              if (mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final League league;
  final bool isCommissioner;

  const _OverviewTab({required this.league, required this.isCommissioner});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: _getStatusColor(league.status),
                    child: Icon(
                      _getStatusIcon(league.status),
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          league.status.displayName,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(league.status),
                          ),
                        ),
                        Text(
                          '${league.season} Season',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  if (isCommissioner)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber[700], size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'Commissioner',
                            style: TextStyle(
                              color: Colors.amber[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
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

          // Invite Code Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.key, color: Colors.green[700]),
                      const SizedBox(width: 8),
                      const Text(
                        'Invite Code',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            league.inviteCode,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: league.inviteCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Copied to clipboard!')),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Settings Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'League Settings',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  _SettingRow(
                    icon: Icons.people,
                    label: 'Teams',
                    value: '${league.teamCount ?? 0}/${league.settings.maxTeams}',
                  ),
                  _SettingRow(
                    icon: Icons.loop,
                    label: 'Draft Format',
                    value: league.settings.draftFormat == 'serpentine'
                        ? 'Serpentine'
                        : 'Straight',
                  ),
                  _SettingRow(
                    icon: Icons.timer,
                    label: 'Pick Timer',
                    value: '${league.settings.pickTimer} seconds',
                  ),
                  _SettingRow(
                    icon: Icons.format_list_numbered,
                    label: 'Rounds',
                    value: '${league.settings.rounds}',
                  ),
                  _SettingRow(
                    icon: Icons.swap_horiz,
                    label: 'Pick Trading',
                    value: league.settings.tradePicksEnabled ? 'Enabled' : 'Disabled',
                  ),
                ],
              ),
            ),
          ),

          // Quick Actions
          if (league.status == LeagueStatus.preDraft) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quick Actions',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    if (isCommissioner) ...[
                      _ActionButton(
                        icon: Icons.shuffle,
                        label: 'Manage Draft Order',
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/draft-order',
                            arguments: {'leagueId': league.leagueId},
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      _ActionButton(
                        icon: Icons.settings,
                        label: 'Configure Draft',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DraftConfigurationScreen(
                                leagueId: league.leagueId,
                                leagueName: league.name,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      _ActionButton(
                        icon: Icons.play_arrow,
                        label: 'Start Draft',
                        color: Colors.green[700]!,
                        onTap: () => _showStartDraftDialog(context, league),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(LeagueStatus status) {
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

  IconData _getStatusIcon(LeagueStatus status) {
    switch (status) {
      case LeagueStatus.preDraft:
        return Icons.hourglass_empty;
      case LeagueStatus.drafting:
        return Icons.sports_baseball;
      case LeagueStatus.inSeason:
        return Icons.play_circle;
      case LeagueStatus.completed:
        return Icons.check_circle;
    }
  }

  void _showStartDraftDialog(BuildContext context, League league) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Draft?'),
        content: Text(
          'Are you ready to start the draft with ${league.teamCount ?? 0} teams?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Not Yet'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to draft room
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
            child: const Text('Start Draft', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _TeamsTab extends StatelessWidget {
  final League league;
  final bool isCommissioner;

  const _TeamsTab({required this.league, required this.isCommissioner});

  @override
  Widget build(BuildContext context) {
    final teams = league.teams ?? [];

    if (teams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No teams yet',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Share the invite code to get teams to join',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: teams.length,
      itemBuilder: (context, index) {
        final team = teams[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green[700],
              child: Text(
                '${team.draftPosition ?? index + 1}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(team.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('Draft Position: ${team.draftPosition ?? "Not Set"}'),
            trailing: isCommissioner
                ? PopupMenuButton<String>(
                    onSelected: (value) => _handleTeamAction(context, value, team),
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'remove', child: Text('Remove from League')),
                      const PopupMenuItem(value: 'transfer', child: Text('Transfer Ownership')),
                    ],
                  )
                : null,
          ),
        );
      },
    );
  }

  void _handleTeamAction(BuildContext context, String action, LeagueTeam team) {
    if (action == 'remove') {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Remove Team?'),
          content: Text('Are you sure you want to remove "${team.name}" from the league?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await context.read<LeagueProvider>().removeTeam(
                  league.leagueId,
                  team.teamId,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Remove', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
  }
}

class _DraftTab extends StatelessWidget {
  final League league;
  final bool isCommissioner;

  const _DraftTab({required this.league, required this.isCommissioner});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Draft Status Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Draft Status',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  _getStatusWidget(league.status),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Draft Order Preview
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
                        'Draft Order',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      if (isCommissioner && league.status == LeagueStatus.preDraft)
                        TextButton.icon(
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('Manage'),
                          onPressed: () => _manageDraftOrder(context),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...(league.teams ?? []).asMap().entries.map((entry) {
                    final team = entry.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              '${team.draftPosition ?? entry.key + 1}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(team.name),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          if (isCommissioner && league.status == LeagueStatus.preDraft) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.settings),
                label: const Text('Configure Draft'),
                onPressed: () => _configureDraft(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green[700],
                  side: BorderSide(color: Colors.green[700]!),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Draft'),
                onPressed: () => _startDraft(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],

          if (league.status == LeagueStatus.drafting) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.login),
                label: const Text('Enter Draft Room'),
                onPressed: () => _enterDraftRoom(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _getStatusWidget(LeagueStatus status) {
    switch (status) {
      case LeagueStatus.preDraft:
        return Row(
          children: [
            Icon(Icons.schedule, color: Colors.orange[700]),
            const SizedBox(width: 8),
            const Text('Draft has not started yet'),
          ],
        );
      case LeagueStatus.drafting:
        return Row(
          children: [
            Icon(Icons.sports_baseball, color: Colors.blue[700]),
            const SizedBox(width: 8),
            const Text('Draft is in progress!'),
          ],
        );
      case LeagueStatus.inSeason:
        return Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[700]),
            const SizedBox(width: 8),
            const Text('Draft completed - Season in progress'),
          ],
        );
      case LeagueStatus.completed:
        return Row(
          children: [
            Icon(Icons.done_all, color: Colors.grey[600]),
            const SizedBox(width: 8),
            const Text('Season completed'),
          ],
        );
    }
  }

  void _manageDraftOrder(BuildContext context) {
    Navigator.pushNamed(
      context,
      '/draft-order',
      arguments: {'leagueId': league.leagueId},
    );
  }

  void _configureDraft(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DraftConfigurationScreen(
          leagueId: league.leagueId,
          leagueName: league.name,
        ),
      ),
    );
  }

  void _enterDraftRoom(BuildContext context) {
    Navigator.pushNamed(
      context,
      AppRoutes.draftRoom,
      arguments: {'leagueId': league.leagueId},
    );
  }

  void _startDraft(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Start Draft?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Once started, teams cannot join and the draft order will be locked.',
            ),
            const SizedBox(height: 16),
            Text(
              'Tip: Configure draft settings before starting if you haven\'t already.',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _configureDraft(context);
            },
            child: const Text('Configure First'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              final draftProvider = context.read<DraftProvider>();

              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );

              try {
                // Create the draft if it doesn't exist, then start it
                final draft = await draftProvider.createDraft(
                  leagueId: league.leagueId,
                );

                if (draft != null) {
                  await draftProvider.startDraft(draft.draftId);

                  if (context.mounted) {
                    Navigator.pop(context); // Close loading
                    // Navigate to draft room
                    Navigator.pushNamed(
                      context,
                      AppRoutes.draftRoom,
                      arguments: {'leagueId': league.leagueId},
                    );
                  }
                } else {
                  if (context.mounted) {
                    Navigator.pop(context); // Close loading
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(draftProvider.error ?? 'Failed to create draft'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context); // Close loading
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
            child: const Text('Start Now', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SettingRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: TextStyle(color: Colors.grey[600]))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: (color ?? Colors.grey[700])!.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: color ?? Colors.grey[700]),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: color ?? Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: color ?? Colors.grey[700]),
          ],
        ),
      ),
    );
  }
}

class _LeagueSettingsSheet extends StatelessWidget {
  final League league;
  final ScrollController scrollController;

  const _LeagueSettingsSheet({
    required this.league,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: ListView(
        controller: scrollController,
        children: [
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
          const Text(
            'League Settings',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ListTile(
            title: const Text('League Name'),
            subtitle: Text(league.name),
            trailing: const Icon(Icons.edit),
            onTap: () {
              // Edit name
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Max Teams'),
            subtitle: Text('${league.settings.maxTeams} teams'),
            trailing: const Icon(Icons.edit),
            onTap: () {
              // Edit max teams
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Draft Format'),
            subtitle: Text(
              league.settings.draftFormat == 'serpentine' ? 'Serpentine' : 'Straight',
            ),
            trailing: const Icon(Icons.edit),
            onTap: () {
              // Edit format
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Pick Timer'),
            subtitle: Text('${league.settings.pickTimer} seconds'),
            trailing: const Icon(Icons.edit),
            onTap: () {
              // Edit timer
            },
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Pick Trading'),
            subtitle: const Text('Allow teams to trade draft picks'),
            value: league.settings.tradePicksEnabled,
            onChanged: (value) {
              // Toggle trading
            },
          ),
        ],
      ),
    );
  }
}
