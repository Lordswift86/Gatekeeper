import 'package:flutter/material.dart';
import 'package:gatekeeper_resident/screens/login_screen.dart';
import 'package:gatekeeper_resident/screens/dashboard_screen.dart';
import 'package:gatekeeper_resident/screens/game_screen.dart';
import 'package:gatekeeper_resident/screens/game_hub_screen.dart';
import 'package:gatekeeper_resident/screens/games/snake_game.dart';
import 'package:gatekeeper_resident/screens/games/game_2048.dart';
import 'package:gatekeeper_resident/screens/games/color_switch_game.dart';
import 'package:gatekeeper_resident/screens/games/breathing_exercise.dart';
import 'package:gatekeeper_resident/screens/payments_screen.dart';
import 'package:gatekeeper_resident/screens/history_screen.dart';
import 'package:gatekeeper_resident/screens/settings_screen.dart';
import 'package:provider/provider.dart';

import 'package:gatekeeper_resident/services/api_client.dart';
import 'package:gatekeeper_resident/providers/user_provider.dart';

void main() {
  runApp(const MyApp());
}

class ThemeProvider extends ChangeNotifier {
  ThemeMode themeMode = ThemeMode.system;

  void toggleTheme() {
    themeMode = themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'GateKeeper Resident',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
              useMaterial3: true,
              brightness: Brightness.light,
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo, brightness: Brightness.dark),
              useMaterial3: true,
              brightness: Brightness.dark,
            ),
            themeMode: themeProvider.themeMode,
            initialRoute: '/login',
            routes: {
              '/login': (context) => const LoginScreen(),
              '/dashboard': (context) => const DashboardScreen(),
              '/game': (context) => const GameHubScreen(),
              '/game/memory': (context) => const GameScreen(),
              '/game/snake': (context) => const SnakeGame(),
              '/game/2048': (context) => const Game2048(),
              '/game/color': (context) => const ColorSwitchGame(),
              '/game/breathing': (context) => const BreathingExercise(),
              '/payments': (context) => const PaymentsScreen(),
              '/history': (context) => const HistoryScreen(),
              '/settings': (context) => const SettingsScreen(),
            },
          );
        },
      ),
    );
  }
}
