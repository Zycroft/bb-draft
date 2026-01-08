import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

import 'providers/auth_provider.dart';
import 'providers/player_provider.dart';
import 'providers/league_provider.dart';
import 'providers/draft_provider.dart';

import 'screens/auth/title_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/players/players_screen.dart';
import 'screens/leagues/leagues_screen.dart';
import 'screens/leagues/create_league_screen.dart';
import 'screens/leagues/join_league_screen.dart';
import 'screens/leagues/league_detail_screen.dart';
import 'screens/leagues/draft_order_screen.dart';
import 'screens/leagues/trades_screen.dart';
import 'screens/leagues/propose_trade_screen.dart';
import 'screens/teams/team_settings_screen.dart';
import 'screens/draft/draft_room_screen.dart';
import 'config/routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PlayerProvider()),
        ChangeNotifierProvider(create: (_) => LeagueProvider()),
        ChangeNotifierProvider(create: (_) => DraftProvider()),
      ],
      child: MaterialApp(
        title: 'BaseBall Draft',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
          useMaterial3: true,
        ),
        initialRoute: AppRoutes.title,
        routes: {
          AppRoutes.title: (context) => const TitleScreen(),
          AppRoutes.login: (context) => const LoginScreen(),
          AppRoutes.register: (context) => const RegisterScreen(),
          AppRoutes.home: (context) => const HomeScreen(),
          AppRoutes.players: (context) => const PlayersScreen(),
          AppRoutes.leagues: (context) => const LeaguesScreen(),
          AppRoutes.createLeague: (context) => const CreateLeagueScreen(),
          AppRoutes.joinLeague: (context) => const JoinLeagueScreen(),
        },
        onGenerateRoute: (settings) {
          // Handle routes with arguments
          final args = settings.arguments as Map<String, dynamic>?;

          if (settings.name == AppRoutes.draftRoom && args != null) {
            return MaterialPageRoute(
              builder: (context) => DraftRoomScreen(
                draftId: args['draftId'] as String,
                teamId: args['teamId'] as String,
                leagueName: args['leagueName'] as String,
              ),
            );
          }

          if (settings.name == AppRoutes.leagueDetail && args != null) {
            return MaterialPageRoute(
              builder: (context) => LeagueDetailScreen(
                leagueId: args['leagueId'] as String,
              ),
            );
          }

          if (settings.name == AppRoutes.draftOrder && args != null) {
            return MaterialPageRoute(
              builder: (context) => DraftOrderScreen(
                leagueId: args['leagueId'] as String,
              ),
            );
          }

          if (settings.name == AppRoutes.trades && args != null) {
            return MaterialPageRoute(
              builder: (context) => TradesScreen(
                leagueId: args['leagueId'] as String,
              ),
            );
          }

          if (settings.name == AppRoutes.proposeTrade && args != null) {
            return MaterialPageRoute(
              builder: (context) => ProposeTradeScreen(
                leagueId: args['leagueId'] as String,
                myTeamId: args['myTeamId'] as String,
              ),
            );
          }

          // Handle /draft-order route from league_detail_screen
          if (settings.name == '/draft-order' && args != null) {
            return MaterialPageRoute(
              builder: (context) => DraftOrderScreen(
                leagueId: args['leagueId'] as String,
              ),
            );
          }

          if (settings.name == AppRoutes.teamSettings && args != null) {
            return MaterialPageRoute(
              builder: (context) => TeamSettingsScreen(
                teamId: args['teamId'] as String,
                leagueId: args['leagueId'] as String,
              ),
            );
          }

          return null;
        },
      ),
    );
  }
}
