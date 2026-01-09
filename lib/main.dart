import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

import 'config/app_config.dart';
import 'config/routes.dart';
import 'providers/auth_provider.dart';
import 'providers/status_provider.dart';
import 'screens/auth/title_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'widgets/status_bar.dart';

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
        if (AppConfig.showDevStatusIndicators)
          ChangeNotifierProvider(create: (_) => StatusProvider()),
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
        },
        builder: (context, child) {
          if (!AppConfig.showDevStatusIndicators) {
            return child ?? const SizedBox.shrink();
          }

          return Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              // Only show status bar when authenticated
              if (!authProvider.isAuthenticated) {
                return child ?? const SizedBox.shrink();
              }

              return Stack(
                children: [
                  Positioned.fill(
                    bottom: 40, // Leave space for status bar
                    child: child ?? const SizedBox.shrink(),
                  ),
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: StatusBar(),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
