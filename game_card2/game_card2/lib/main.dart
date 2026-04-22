import 'package:flutter/material.dart';

import 'screens/belote_screen.dart';
import 'screens/blackjack_screen.dart';
import 'screens/home_screen.dart';
import 'screens/inter_screen.dart';
import 'screens/memory_screen.dart';
import 'screens/multiplayer_blackjack_screen.dart';
import 'screens/multiplayer_lobby_screen.dart';
import 'screens/president_screen.dart';
import 'screens/poker_screen.dart';
import 'screens/speed_screen.dart';

void main() {
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