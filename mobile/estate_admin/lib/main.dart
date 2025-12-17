import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

void main() {
  runApp(const EstateAdminApp());
}

class EstateAdminApp extends StatelessWidget {
  const EstateAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gatekeeper Estate Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.interTextTheme(),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      ),
      routes: {
        '/': (context) => const LoginScreen(),
        '/login': (context) => const LoginScreen(),
      },
      initialRoute: '/',
    );
  }
}
