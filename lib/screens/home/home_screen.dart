import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/league_provider.dart';
import '../../config/routes.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load leagues when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LeagueProvider>().loadLeagues();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: Colors.green[800],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('BaseBall Draft', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await auth.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, AppRoutes.title);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User profile section
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                    child: user?.photoURL == null
                        ? const Icon(Icons.person, size: 40, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Welcome, ${user?.displayName ?? user?.email ?? 'Player'}!',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Quick actions grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildActionCard(
                  icon: Icons.people,
                  title: 'Players',
                  subtitle: 'Browse MLB players',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.players),
                ),
                _buildActionCard(
                  icon: Icons.emoji_events,
                  title: 'My Leagues',
                  subtitle: 'View your leagues',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.leagues),
                ),
                _buildActionCard(
                  icon: Icons.add_circle,
                  title: 'Create League',
                  subtitle: 'Start a new league',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.createLeague),
                ),
                _buildActionCard(
                  icon: Icons.login,
                  title: 'Join League',
                  subtitle: 'Enter invite code',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.joinLeague),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // My leagues section
            const Text(
              'My Leagues',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Consumer<LeagueProvider>(
              builder: (context, leagueProvider, _) {
                if (leagueProvider.isLoading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  );
                }

                if (leagueProvider.leagues.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.sports_baseball, size: 48, color: Colors.white.withAlpha(127)),
                        const SizedBox(height: 12),
                        Text(
                          'No leagues yet',
                          style: TextStyle(color: Colors.white.withAlpha(178), fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create or join a league to get started!',
                          style: TextStyle(color: Colors.white.withAlpha(127), fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: leagueProvider.leagues.length,
                  itemBuilder: (context, index) {
                    final league = leagueProvider.leagues[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green[700],
                          child: const Icon(Icons.emoji_events, color: Colors.white),
                        ),
                        title: Text(league.name),
                        subtitle: Text('${league.status.displayName} - ${league.season}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // Navigate to league detail
                          leagueProvider.selectLeague(league);
                          // TODO: Navigate to league detail screen
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.green[700]),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green[800],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
