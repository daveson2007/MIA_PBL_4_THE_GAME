import 'package:flutter/material.dart';

import '../models/card_model.dart';
import '../models/deck.dart';
import '../widgets/card_widget.dart';

const pokerValues = {
  '2': 2,
  '3': 3,
  '4': 4,
  '5': 5,
  '6': 6,
  '7': 7,
  '8': 8,
  '9': 9,
  '10': 10,
  'V': 11,
  'D': 12,
  'R': 13,
  'A': 14,
};

String evaluatePokerHand(List<CardModel> hand) {
  if (hand.length < 5) return 'En attente...';
  final values = hand.map((card) => pokerValues[card.rank]!).toList()..sort((a, b) => b.compareTo(a));
  final suits = hand.map((card) => card.suit).toList();

  final isFlush = suits.toSet().length == 1;
  var isStraight = false;
  final uniqueValues = values.toSet().toList();
  if (uniqueValues.length == 5) {
    if (values.first - values.last == 4) {
      isStraight = true;
    } else if (values.join(',') == '14,5,4,3,2') {
      isStraight = true;
    }
  }

  final counts = <int, int>{};
  for (final value in values) {
    counts[value] = (counts[value] ?? 0) + 1;
  }
  final frequencies = counts.values.toList()..sort((a, b) => b.compareTo(a));

  if (isFlush && isStraight) {
    if (values[0] == 14 && values[1] == 13) return 'Quinte Flush Royale';
    return 'Quinte Flush';
  }
  if (frequencies.length == 2 && frequencies[0] == 4) return 'Carré';
  if (frequencies.length == 2 && frequencies[0] == 3 && frequencies[1] == 2) return 'Full (Main Pleine)';
  if (isFlush) return 'Couleur';
  if (isStraight) return 'Quinte (Suite)';
  if (frequencies.length == 3 && frequencies[0] == 3) return 'Brelan';
  if (frequencies.length == 3 && frequencies[0] == 2 && frequencies[1] == 2) return 'Double Paire';
  if (frequencies.length == 4 && frequencies[0] == 2) return 'Paire';
  return 'Carte Haute';
}

class PokerScreen extends StatefulWidget {
  const PokerScreen({super.key});

  @override
  State<PokerScreen> createState() => _PokerScreenState();
}

class _PokerScreenState extends State<PokerScreen> {
  late Deck deck;
  final List<CardModel> playerHand = [];
  final List<bool> heldCards = List<bool>.filled(5, false);
  int phase = 0;
  String statusMessage = 'Appuyez sur Distribuer';

  @override
  void initState() {
    super.initState();
    resetGame();
  }

  void resetGame() {
    deck = Deck();
    playerHand.clear();
    for (var i = 0; i < 5; i++) {
      final card = deck.draw();
      if (card != null) playerHand.add(card);
    }
    for (var i = 0; i < 5; i++) {
      heldCards[i] = false;
    }
    phase = 1;
    statusMessage = 'Choisissez vos cartes à garder.';
    setState(() {});
  }

  void toggleHold(int index) {
    if (phase != 1) return;
    setState(() {
      heldCards[index] = !heldCards[index];
    });
  }

  void playTurn() {
    if (phase == 0 || phase == 2) {
      resetGame();
      return;
    }

    for (var i = 0; i < 5; i++) {
      if (!heldCards[i]) {
        final newCard = deck.draw();
        if (newCard != null) {
          playerHand[i] = newCard;
        }
      }
    }
    final result = evaluatePokerHand(playerHand);
    final isWinning = result != 'Carte Haute';
    setState(() {
      statusMessage = 'RÉSULTAT : $result';
      phase = 2;
    });
    if (isWinning) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✨ BIEN JOUÉ ! $result ✨')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Poker')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Video Poker (5 Cartes)', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                ElevatedButton(onPressed: () => _showRules(context), child: const Text('Règles')),
              ],
            ),
            const SizedBox(height: 16),
            Text(statusMessage, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                itemCount: playerHand.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.72,
                ),
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => toggleHold(index),
                    child: PlayingCardWidget(
                      card: playerHand[index],
                      selected: heldCards[index],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: playTurn,
              child: Text(phase == 2 ? 'Nouveau Tirage' : 'Distribuer / Valider'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRules(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Règles du Poker'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Hiérarchie des cartes : 2 < 3 < 4 < 5 < 6 < 7 < 8 < 9 < 10 < V < D < R < A'),
                SizedBox(height: 12),
                Text('Mains :'),
                Text('• Quinte Flush Royale'),
                Text('• Quinte Flush'),
                Text('• Carré'),
                Text('• Full (Main Pleine)'),
                Text('• Couleur'),
                Text('• Quinte (Suite)'),
                Text('• Brelan'),
                Text('• Double Paire'),
                Text('• Paire'),
                Text('• Carte Haute'),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
          ],
        );
      },
    );
  }
}
