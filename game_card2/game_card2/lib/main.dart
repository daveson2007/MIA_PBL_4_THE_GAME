import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/belote_screen.dart';
import 'services/supabase_service.dart';
import 'screens/blackjack_screen.dart';
import 'screens/home_screen.dart';
import 'screens/inter_screen.dart';
import 'screens/memory_screen.dart';
import 'screens/multiplayer_blackjack_screen.dart';
import 'screens/multiplayer_lobby_screen.dart';
import 'screens/president_screen.dart';
import 'screens/poker_screen.dart';
import 'screens/speed_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Supabase - replace with your project values
  await Supabase.initialize(
    url: 'https://bnfeuiqzacwyhlkdesfi.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJuZmV1aXF6YWN3eWhsa2Rlc2ZpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY3ODA3ODQsImV4cCI6MjA5MjM1Njc4NH0.DA9sQWRrwCIoCwBjjhKWtGFVVnTVRjfmxqCVVavIuSM',
  );
  // Initialize local playerId and service
  await SupabaseService.I.init();
  runApp(const CardGamesApp());
}

class CardGamesApp extends StatelessWidget {
  const CardGamesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jeux de Cartes',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.redAccent),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/blackjack': (context) => const BlackjackScreen(),
        '/memory': (context) => const MemoryScreen(),
        '/president': (context) => const PresidentScreen(),
        '/inter': (context) => const InterScreen(),
        '/speed': (context) => const SpeedScreen(),
        '/poker': (context) => const PokerScreen(),
        '/belote': (context) => const BeloteScreen(),
        '/multiplayer_lobby': (context) => const MultiplayerLobbyScreen(),
        '/multiplayer_blackjack': (context) => const MultiplayerBlackjackScreen(),
      },
    );
  }
}