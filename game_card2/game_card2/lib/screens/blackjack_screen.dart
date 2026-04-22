import 'package:flutter/material.dart';

import '../models/card_model.dart';
import '../models/deck.dart';
import '../widgets/card_widget.dart';

class BlackjackScreen extends StatefulWidget {
  const BlackjackScreen({super.key});

  @override
  State<BlackjackScreen> createState() => _BlackjackScreenState();
}

class _BlackjackScreenState extends State<BlackjackScreen> {
  late Deck deck;
  final List<CardModel> playerHand = [];
  final List<CardModel> dealerHand = [];
  String statusMessage = 'À vous de jouer !';
  bool gameOver = false;

  @override
  void initState() {
    super.initState();
    resetGame();
  }

  int calculateScore(List<CardModel> hand) {
    var score = hand.fold<int>(0, (value, card) => value + card.value);
    var aces = hand.where((card) => card.rank == 'A').length;
    while (score > 21 && aces > 0) {
      score -= 10;
      aces -= 1;
    }
    return score;
  }

  void hit() {
    if (gameOver) return;
    final card = deck.draw();
    if (card != null) {
      playerHand.add(card);
    }
    if (calculateScore(playerHand) > 21) {
      statusMessage = 'Bust ! Vous avez perdu.';
      gameOver = true;
    }
    setState(() {});
  }

  void stand() {
    if (gameOver) return;
    gameOver = true;
    while (calculateScore(dealerHand) < 17) {
      final card = deck.draw();
      if (card != null) dealerHand.add(card);
    }
    final playerScore = calculateScore(playerHand);
    final dealerScore = calculateScore(dealerHand);
    if (dealerScore > 21) {
      statusMessage = 'Le croupier a sauté ! VICTOIRE !';
    } else if (playerScore > dealerScore) {
      statusMessage = 'VICTOIRE !';
    } else if (playerScore < dealerScore) {
      statusMessage = 'DÉFAITE !';
    } else {
      statusMessage = 'ÉGALITÉ (Push) !';
    }
    setState(() {});
  }

  void resetGame() {
    deck = Deck();
    playerHand
      ..clear()
      ..add(deck.draw()!)
      ..add(deck.draw()!);
    dealerHand
      ..clear()
      ..add(deck.draw()!)
      ..add(deck.draw()!);
    statusMessage = 'À vous de jouer !';
    gameOver = false;
    setState(() {});
  }

  Widget _scoreText(String label, int score, {bool hidden = false}) {
    return Text(
      hidden ? '$label : ?' : '$label : $score',
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Blackjack')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Blackjack Casino', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _scoreText('Score Croupier', calculateScore(dealerHand), hidden: !gameOver),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: dealerHand
                    .asMap()
                    .entries
                    .map((entry) => PlayingCardWidget(
                          card: entry.value,
                          faceDown: !gameOver && entry.key == 0,
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 24),
            _scoreText('Score Joueur', calculateScore(playerHand)),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: playerHand.map((card) => PlayingCardWidget(card: card)).toList(),
              ),
            ),
            const SizedBox(height: 24),
            Text(statusMessage, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton(onPressed: hit, child: const Text('Tirer (Hit)')),
                ElevatedButton(onPressed: stand, child: const Text('Rester (Stand)')),
                OutlinedButton(onPressed: resetGame, child: const Text('Rejouer')),
              ],
            )
          ],
        ),
      ),
    );
  }
}
