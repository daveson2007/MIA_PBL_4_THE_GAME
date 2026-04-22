import 'package:flutter/material.dart';

import '../models/card_model.dart';
import '../models/deck.dart';
import '../widgets/card_widget.dart';

class PresidentScreen extends StatefulWidget {
  const PresidentScreen({super.key});

  @override
  State<PresidentScreen> createState() => _PresidentScreenState();
}

class _PresidentScreenState extends State<PresidentScreen> {
  late Deck deck;
  final List<CardModel> playerHand = [];
  final List<List<CardModel>> aiHands = [[], [], []];
  final List<CardModel> tableCards = [];
  String statusMessage = 'Votre tour. Jouez une carte plus forte que la table.';
  int? selectedIndex;

  static const rankOrder = {
    '3': 1,
    '4': 2,
    '5': 3,
    '6': 4,
    '7': 5,
    '8': 6,
    '9': 7,
    '10': 8,
    'V': 9,
    'D': 10,
    'R': 11,
    'A': 12,
    '2': 13,
  };

  @override
  void initState() {
    super.initState();
    resetGame();
  }

  void resetGame() {
    deck = Deck();
    playerHand.clear();
    for (var i = 0; i < 13; i++) {
      final card = deck.draw();
      if (card != null) playerHand.add(card);
    }
    playerHand.sort((a, b) => rankOrder[a.rank]!.compareTo(rankOrder[b.rank]!));

    for (var hand in aiHands) {
      hand.clear();
      for (var i = 0; i < 13; i++) {
        final card = deck.draw();
        if (card != null) hand.add(card);
      }
      hand.sort((a, b) => rankOrder[a.rank]!.compareTo(rankOrder[b.rank]!));
    }

    tableCards.clear();
    statusMessage = 'Votre tour. Jouez une carte plus forte que la table.';
    selectedIndex = null;
    setState(() {});
  }

  int _tableValue() {
    if (tableCards.isEmpty) return 0;
    return rankOrder[tableCards.last.rank]!;
  }

  void _playCard() {
    if (selectedIndex == null) return;
    final card = playerHand[selectedIndex!];
    final currentValue = _tableValue();
    final cardValue = rankOrder[card.rank]!;
    if (cardValue <= currentValue) {
      setState(() => statusMessage = 'Carte trop faible !');
      return;
    }

    setState(() {
      tableCards.add(card);
      playerHand.removeAt(selectedIndex!);
      selectedIndex = null;
      statusMessage = 'Carte jouée. Tour de l’IA...';
    });

    if (playerHand.isEmpty) {
      setState(() => statusMessage = 'VICTOIRE ! Vous avez vidé votre main.');
      return;
    }

    Future.delayed(const Duration(milliseconds: 500), _aiTurn);
  }

  void _passTurn() {
    setState(() {
      tableCards.clear();
      statusMessage = 'Vous passez. La table est nettoyée.';
      selectedIndex = null;
    });
    Future.delayed(const Duration(milliseconds: 400), _aiTurn);
  }

  void _aiTurn() {
    if (aiHands.every((hand) => hand.isEmpty)) {
      setState(() => statusMessage = 'L’IA n’a plus de cartes. Vous avez gagné !');
      return;
    }

    final currentValue = _tableValue();
    for (var i = 0; i < aiHands.length; i++) {
      final hand = aiHands[i];
      hand.sort((a, b) => rankOrder[a.rank]!.compareTo(rankOrder[b.rank]!));
      final index = hand.indexWhere((card) => rankOrder[card.rank]! > currentValue);
      if (index != -1) {
        final card = hand.removeAt(index);
        setState(() {
          tableCards.add(card);
          statusMessage = 'L’IA ${i + 1} a joué ${card.label}.';
        });
        return;
      }
    }

    setState(() {
      tableCards.clear();
      statusMessage = 'Toutes les IA ont passé. La table est vide !';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Président')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Le Président', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Table : ${tableCards.isEmpty ? 'vide' : tableCards.last.label}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: tableCards
                    .map((card) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: PlayingCardWidget(card: card),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),
            Text(statusMessage, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const Divider(height: 32),
            const Text('Votre main', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                itemCount: playerHand.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.75,
                ),
                itemBuilder: (context, index) {
                  return PlayingCardWidget(
                    card: playerHand[index],
                    selected: selectedIndex == index,
                    onTap: () => setState(() => selectedIndex = index),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              children: [
                ElevatedButton(onPressed: _playCard, child: const Text('Jouer la carte')),
                OutlinedButton(onPressed: _passTurn, child: const Text('Passer / Nettoyer')),
                TextButton(onPressed: resetGame, child: const Text('Rejouer')),
              ],
            )
          ],
        ),
      ),
    );
  }
}
