import 'package:flutter/material.dart';

import '../models/card_model.dart';
import '../models/deck.dart';
import '../widgets/card_widget.dart';

class InterScreen extends StatefulWidget {
  const InterScreen({super.key});

  @override
  State<InterScreen> createState() => _InterScreenState();
}

class _InterScreenState extends State<InterScreen> {
  late Deck deck;
  final List<CardModel> playerHand = [];
  final List<CardModel> aiHand = [];
  final List<CardModel> discardPile = [];
  String infoMessage = 'À vous de jouer !';
  int? selectedIndex;

  @override
  void initState() {
    super.initState();
    resetGame();
  }

  void resetGame() {
    deck = Deck();
    playerHand.clear();
    aiHand.clear();
    for (var i = 0; i < 4; i++) {
      final card = deck.draw();
      if (card != null) playerHand.add(card);
    }
    for (var i = 0; i < 4; i++) {
      final card = deck.draw();
      if (card != null) aiHand.add(card);
    }
    discardPile.clear();
    final firstCard = deck.draw();
    if (firstCard != null) discardPile.add(firstCard);
    selectedIndex = null;
    infoMessage = 'À vous de jouer !';
    setState(() {});
  }

  String get activeSuit => discardPile.isEmpty ? '' : discardPile.last.suit;

  void _playCard() {
    if (selectedIndex == null || discardPile.isEmpty) return;
    final selected = playerHand[selectedIndex!];
    final topCard = discardPile.last;
    final valid = selected.rank == '8' || selected.rank == topCard.rank || selected.suit == activeSuit;

    if (!valid) {
      setState(() => infoMessage = 'Coup invalide !');
      return;
    }

    setState(() {
      discardPile.add(selected);
      playerHand.removeAt(selectedIndex!);
      selectedIndex = null;
      infoMessage = 'Vous jouez ${selected.label}.';
    });

    if (playerHand.isEmpty) {
      setState(() => infoMessage = 'VICTOIRE ! Vous avez vidé votre main.');
      return;
    }

    Future.delayed(const Duration(milliseconds: 400), _aiTurn);
  }

  void _drawCard() {
    final card = deck.draw();
    if (card != null) {
      setState(() {
        playerHand.add(card);
        infoMessage = 'Vous piochez. Tour de l’IA.';
        selectedIndex = null;
      });
      Future.delayed(const Duration(milliseconds: 400), _aiTurn);
    }
  }

  void _knock() {
    if (playerHand.length <= 2) {
      setState(() => infoMessage = '✊ Toc Toc Toc !');
    }
  }

  void _aiTurn() {
    if (aiHand.isEmpty) {
      setState(() => infoMessage = 'L’IA n’a plus de cartes. Vous avez gagné !');
      return;
    }

    final topCard = discardPile.last;
    final playableIndex = aiHand.indexWhere((card) =>
        card.rank == '8' || card.rank == topCard.rank || card.suit == activeSuit);

    if (playableIndex != -1) {
      final card = aiHand.removeAt(playableIndex);
      setState(() {
        discardPile.add(card);
        infoMessage = 'L’IA a joué ${card.label}';
      });
      if (card.rank == 'A') {
        Future.delayed(const Duration(milliseconds: 400), _aiTurn);
        return;
      }
    } else {
      final card = deck.draw();
      if (card != null) {
        setState(() => infoMessage = 'L’IA pioche.');
        aiHand.add(card);
      } else {
        setState(() => infoMessage = 'L’IA passe.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('L’Inter')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('L’Inter (Jeu de la Terre)', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('Carte demandée : $activeSuit', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: discardPile
                    .map((card) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: PlayingCardWidget(card: card),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),
            Text(infoMessage, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
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
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton(onPressed: _playCard, child: const Text('Jouer')),
                ElevatedButton(onPressed: _drawCard, child: const Text('Piocher')),
                OutlinedButton(onPressed: _knock, child: const Text('✊ Toc Toc')),
                TextButton(onPressed: resetGame, child: const Text('Rejouer')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
