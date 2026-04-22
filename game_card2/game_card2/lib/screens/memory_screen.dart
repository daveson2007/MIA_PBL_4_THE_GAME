import 'dart:math';

import 'package:flutter/material.dart';

import '../models/card_model.dart';
import '../widgets/card_widget.dart';

class MemoryScreen extends StatefulWidget {
  const MemoryScreen({super.key});

  @override
  State<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends State<MemoryScreen> {
  final List<CardModel> cards = [];
  final List<bool> revealed = List<bool>.filled(16, false);
  final List<bool> matched = List<bool>.filled(16, false);
  int? firstIndex;
  String status = 'Trouvez toutes les paires !';

  @override
  void initState() {
    super.initState();
    resetGame();
  }

  void resetGame() {
    cards.clear();
    final suits = ['♥', '♠', '♦', '♣'];
    final ranks = ['A', 'R', 'D', 'V', '10', '9', '8', '7'];
    final baseCards = ranks
        .map((rank) => CardModel(
              suit: suits[Random().nextInt(suits.length)],
              rank: rank,
              value: 0,
            ))
        .toList();
    cards.addAll(baseCards);
    cards.addAll(baseCards.map((card) => CardModel(suit: card.suit, rank: card.rank, value: 0)));
    cards.shuffle(Random());

    for (var i = 0; i < 16; i++) {
      revealed[i] = false;
      matched[i] = false;
    }
    firstIndex = null;
    status = 'Trouvez toutes les paires !';
    setState(() {});
  }

  Future<void> _onCardTap(int index) async {
    if (revealed[index] || matched[index]) return;
    setState(() => revealed[index] = true);

    if (firstIndex == null) {
      firstIndex = index;
      return;
    }

    if (cards[firstIndex!].rank == cards[index].rank) {
      matched[firstIndex!] = true;
      matched[index] = true;
      firstIndex = null;
      if (matched.every((value) => value)) {
        status = 'Félicitations ! Vous avez gagné !';
      }
      setState(() {});
      return;
    }

    await Future.delayed(const Duration(milliseconds: 800));
    setState(() {
      revealed[firstIndex!] = false;
      revealed[index] = false;
      firstIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Memory')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(status, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                itemCount: cards.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.75,
                ),
                itemBuilder: (context, index) {
                  final isFaceUp = revealed[index] || matched[index];
                  return PlayingCardWidget(
                    card: cards[index],
                    faceDown: !isFaceUp,
                    selected: matched[index],
                    onTap: () => _onCardTap(index),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: resetGame, child: const Text('Réinitialiser')),
          ],
        ),
      ),
    );
  }
}
