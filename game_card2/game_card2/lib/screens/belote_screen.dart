import 'package:flutter/material.dart';

import '../models/card_model.dart';
import '../widgets/card_widget.dart';

const beloteValues = {
  'Valet': [2, 20],
  '9': [0, 14],
  'As': [11, 11],
  '10': [10, 10],
  'Roi': [4, 4],
  'Reine': [3, 3],
  '8': [0, 0],
  '7': [0, 0],
};

class BeloteScreen extends StatefulWidget {
  const BeloteScreen({super.key});

  @override
  State<BeloteScreen> createState() => _BeloteScreenState();
}

class _BeloteScreenState extends State<BeloteScreen> {
  final List<CardModel> deck = [];
  final List<CardModel> playerHand = [];
  final List<List<CardModel>> aiHands = [[], [], []];
  final List<CardModel> currentTrick = [];
  late String trumpSuit;
  int playerScore = 0;
  int aiScore = 0;
  String statusMessage = 'À vous de jouer la première carte !';

  @override
  void initState() {
    super.initState();
    resetGame();
  }

  void resetGame() {
    deck.clear();
    playerHand.clear();
    aiHands[0].clear();
    aiHands[1].clear();
    aiHands[2].clear();
    currentTrick.clear();

    final suits = ['Trefle', 'Coeur', 'Carreau', 'Pique'];
    final ranks = ['7', '8', '9', '10', 'Valet', 'Reine', 'Roi', 'As'];

    for (final suit in suits) {
      for (final rank in ranks) {
        deck.add(CardModel(suit: suit, rank: rank, value: 0));
      }
    }
    deck.shuffle();

    for (var i = 0; i < 8; i++) {
      playerHand.add(deck.removeLast());
    }
    for (var j = 0; j < 3; j++) {
      for (var i = 0; i < 8; i++) {
        aiHands[j].add(deck.removeLast());
      }
    }
    trumpSuit = suits[DateTime.now().millisecondsSinceEpoch.remainder(suits.length)];
    playerScore = 0;
    aiScore = 0;
    statusMessage = 'À vous de jouer la première carte !';
    setState(() {});
  }

  int points(CardModel card) {
    final isTrump = card.suit == trumpSuit;
    final rankPoints = beloteValues[card.rank]!;
    return isTrump ? rankPoints[1] : rankPoints[0];
  }

  int evaluateTrick() {
    if (currentTrick.isEmpty) return 0;
    final askedSuit = currentTrick.first.suit;
    var bestIndex = 0;
    var bestCard = currentTrick.first;

    for (var i = 1; i < currentTrick.length; i++) {
      final card = currentTrick[i];
      final isTrump = card.suit == trumpSuit;
      final bestIsTrump = bestCard.suit == trumpSuit;
      if (isTrump && !bestIsTrump) {
        bestCard = card;
        bestIndex = i;
      } else if (isTrump && bestIsTrump) {
        if (beloteValues[card.rank]![1] > beloteValues[bestCard.rank]![1]) {
          bestCard = card;
          bestIndex = i;
        }
      } else if (card.suit == askedSuit && !bestIsTrump) {
        if (beloteValues[card.rank]![0] > beloteValues[bestCard.rank]![0]) {
          bestCard = card;
          bestIndex = i;
        }
      }
    }

    return bestIndex;
  }

  void playCard(int index) {
    if (playerHand.isEmpty || currentTrick.length == 4) {
      currentTrick.clear();
    }
    currentTrick.add(playerHand.removeAt(index));
    statusMessage = 'Au tour des IA...';
    setState(() {});
    Future.delayed(const Duration(milliseconds: 400), aiTurn);
  }

  void aiTurn() {
    for (var i = 0; i < aiHands.length; i++) {
      final hand = aiHands[i];
      if (hand.isNotEmpty) {
        final cardPlayed = hand.removeAt(0);
        currentTrick.add(cardPlayed);
      }
    }

    final winnerIndex = evaluateTrick();
    final pointsTrick = currentTrick.fold<int>(0, (sum, card) => sum + points(card));
    if (winnerIndex == 0) {
      playerScore += pointsTrick;
      statusMessage = 'Vous remportez le pli ! (+$pointsTrick pts)';
    } else {
      aiScore += pointsTrick;
      statusMessage = 'L\'IA ${winnerIndex} remporte le pli. (+$pointsTrick pts)';
    }

    setState(() {});
    Future.delayed(const Duration(milliseconds: 800), () {
      currentTrick.clear();
      if (playerHand.isEmpty) {
        statusMessage = 'Partie terminée !';
      } else {
        statusMessage = 'Nouveau pli, à vous !';
      }
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Belote')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Belote', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.cyan)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Atout : $trumpSuit', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                Text('Score - Vous: $playerScore | IA: $aiScore', style: const TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),
            Text(statusMessage, style: const TextStyle(fontSize: 16, color: Colors.amber)),
            const SizedBox(height: 16),
            const Text('Le Pli en cours :', style: TextStyle(fontStyle: FontStyle.italic)),
            const SizedBox(height: 8),
            Container(
              height: 150,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade900,
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: currentTrick.map((card) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: PlayingCardWidget(card: card),
                )).toList(),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Votre main (Cliquez pour jouer) :', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: GridView.builder(
                itemCount: playerHand.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.75,
                ),
                itemBuilder: (context, index) {
                  return PlayingCardWidget(
                    card: playerHand[index],
                    onTap: () => playCard(index),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: resetGame, child: const Text('Rejouer')),
          ],
        ),
      ),
    );
  }
}
