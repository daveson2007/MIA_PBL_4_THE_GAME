import 'package:flutter/material.dart';

import '../models/card_model.dart';
import '../models/deck.dart';
import '../widgets/card_widget.dart';

const speedValues = {
  'A': 1,
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
};

bool isPlayable(CardModel card, CardModel targetCard) {
  final v1 = speedValues[card.rank]!;
  final v2 = speedValues[targetCard.rank]!;
  final diff = (v1 - v2).abs();
  return diff == 1 || diff == 12;
}

class SpeedScreen extends StatefulWidget {
  const SpeedScreen({super.key});

  @override
  State<SpeedScreen> createState() => _SpeedScreenState();
}

class _SpeedScreenState extends State<SpeedScreen> {
  late Deck deck;
  final List<CardModel> playerHand = [];
  final List<CardModel> aiHand = [];
  final List<CardModel> centerPiles = [];
  int? selectedIndex;
  String statusMessage = 'Vite ! Posez vos cartes !';

  @override
  void initState() {
    super.initState();
    resetGame();
  }

  void resetGame() {
    deck = Deck();
    playerHand.clear();
    aiHand.clear();
    centerPiles.clear();

    for (var i = 0; i < 5; i++) {
      final card = deck.draw();
      if (card != null) playerHand.add(card);
    }
    for (var i = 0; i < 5; i++) {
      final card = deck.draw();
      if (card != null) aiHand.add(card);
    }
    final first = deck.draw();
    final second = deck.draw();
    if (first != null && second != null) {
      centerPiles.addAll([first, second]);
    }
    selectedIndex = null;
    statusMessage = 'Vite ! Posez vos cartes !';
    setState(() {});
  }

  void selectCard(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  void playToPile(int pileIndex) {
    if (selectedIndex == null || centerPiles.isEmpty) return;
    final card = playerHand[selectedIndex!];
    final target = centerPiles[pileIndex];
    if (!isPlayable(card, target)) {
      setState(() => statusMessage = 'Carte non jouable sur cette pile !');
      return;
    }
    setState(() {
      centerPiles[pileIndex] = playerHand.removeAt(selectedIndex!);
      selectedIndex = null;
      statusMessage = 'Carte jouée. Tour de l’IA.';
    });
    final newCard = deck.draw();
    if (newCard != null) {
      playerHand.add(newCard);
    }
  }

  void aiMove() {
    var played = false;
    for (var i = 0; i < aiHand.length; i++) {
      final card = aiHand[i];
      for (var pileIndex = 0; pileIndex < centerPiles.length; pileIndex++) {
        if (isPlayable(card, centerPiles[pileIndex])) {
          setState(() {
            centerPiles[pileIndex] = aiHand.removeAt(i);
            statusMessage = 'L’IA a joué sur la pile ${pileIndex + 1}.';
          });
          final newCard = deck.draw();
          if (newCard != null) aiHand.add(newCard);
          played = true;
          break;
        }
      }
      if (played) break;
    }
    if (!played) {
      setState(() => statusMessage = 'L’IA ne peut pas jouer et passe.');
    }
  }

  void resetPiles() {
    final first = deck.draw();
    final second = deck.draw();
    if (first != null && second != null) {
      setState(() {
        centerPiles[0] = first;
        centerPiles[1] = second;
        statusMessage = 'Piles réinitialisées.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Speed')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Speed', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(statusMessage, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(centerPiles.length, (index) {
                return Expanded(
                  child: Column(
                    children: [
                      PlayingCardWidget(card: centerPiles[index]),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => playToPile(index),
                        child: Text('Poser ici ${index + 1}'),
                      ),
                    ],
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            const Text('Votre main', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.72,
                ),
                itemCount: playerHand.length,
                itemBuilder: (context, index) {
                  return PlayingCardWidget(
                    card: playerHand[index],
                    selected: selectedIndex == index,
                    onTap: () => selectCard(index),
                  );
                },
              ),
            ),
            Wrap(
              spacing: 12,
              children: [
                ElevatedButton(onPressed: resetGame, child: const Text('Rejouer')),
                ElevatedButton(onPressed: aiMove, child: const Text('Tour IA (Simuler)')),
                OutlinedButton(onPressed: resetPiles, child: const Text('Reset Piles')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
