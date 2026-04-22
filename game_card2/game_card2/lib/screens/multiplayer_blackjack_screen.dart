import 'package:flutter/material.dart';
import '../models/card_model.dart';
import '../models/deck.dart';
import '../widgets/card_widget.dart';
import '../services/multiplayer_service.dart';

class MultiplayerBlackjackScreen extends StatefulWidget {
  const MultiplayerBlackjackScreen({super.key});

  @override
  State<MultiplayerBlackjackScreen> createState() => _MultiplayerBlackjackScreenState();
}

class _MultiplayerBlackjackScreenState extends State<MultiplayerBlackjackScreen> {
  late MultiplayerService _service;
  late Deck deck;
  final List<CardModel> dealerHand = [];
  final Map<String, List<CardModel>> playerHands = {};
  final Map<String, bool> playerStands = {};
  final Map<String, String> playerStatuses = {};
  List<String> playerOrder = [];
  int currentPlayerIndex = 0;
  String myId = 'Player${DateTime.now().millisecondsSinceEpoch}';
  bool gameStarted = false;
  String statusMessage = 'En attente des joueurs...';

  @override
  void initState() {
    super.initState();
    _service = ModalRoute.of(context)!.settings.arguments as MultiplayerService;
    _service.onMessageReceived = _onMessageReceived;
    myId = _service.isHost ? 'Host' : 'Player${DateTime.now().millisecondsSinceEpoch % 1000}';
    _initializeGame();
  }

  void _initializeGame() {
    if (_service.isHost) {
      deck = Deck();
      playerOrder = [myId];
      playerHands[myId] = [];
      playerStands[myId] = false;
      playerStatuses[myId] = 'En attente';
      statusMessage = 'Vous êtes l\'hôte. Attendez que les joueurs rejoignent.';
    } else {
      // Send join message
      _service.sendMessage({
        'type': 'join',
        'playerId': myId,
      });
    }
  }

  void _onMessageReceived(Map<String, dynamic> message) {
    switch (message['type']) {
      case 'join':
        if (_service.isHost) {
          final playerId = message['playerId'];
          playerOrder.add(playerId);
          playerHands[playerId] = [];
          playerStands[playerId] = false;
          playerStatuses[playerId] = 'En attente';
          _broadcastGameState();
        }
        break;
      case 'gameState':
        _updateGameState(message['state']);
        break;
      case 'action':
        _handleAction(message);
        break;
    }
  }

  void _updateGameState(Map<String, dynamic> state) {
    setState(() {
      playerOrder = List<String>.from(state['playerOrder']);
      dealerHand.clear();
      dealerHand.addAll((state['dealerHand'] as List).map((c) => CardModel.fromJson(c)));
      playerHands.clear();
      for (var entry in state['playerHands'].entries) {
        playerHands[entry.key] = (entry.value as List).map((c) => CardModel.fromJson(c)).toList();
      }
      playerStands.clear();
      playerStands.addAll(Map<String, bool>.from(state['playerStands']));
      playerStatuses.clear();
      playerStatuses.addAll(Map<String, String>.from(state['playerStatuses']));
      currentPlayerIndex = state['currentPlayerIndex'];
      gameStarted = state['gameStarted'];
      statusMessage = state['statusMessage'];
    });
  }

  void _handleAction(Map<String, dynamic> message) {
    final action = message['action'];
    final playerId = message['playerId'];
    if (action == 'hit') {
      _hit(playerId);
    } else if (action == 'stand') {
      _stand(playerId);
    }
  }

  void _broadcastGameState() {
    if (!_service.isHost) return;
    final state = {
      'playerOrder': playerOrder,
      'dealerHand': dealerHand.map((c) => c.toJson()).toList(),
      'playerHands': playerHands.map((k, v) => MapEntry(k, v.map((c) => c.toJson()).toList())),
      'playerStands': playerStands,
      'playerStatuses': playerStatuses,
      'currentPlayerIndex': currentPlayerIndex,
      'gameStarted': gameStarted,
      'statusMessage': statusMessage,
    };
    _service.sendMessage({
      'type': 'gameState',
      'state': state,
    });
  }

  void _startGame() {
    if (!_service.isHost || playerOrder.length < 2) return;
    gameStarted = true;
    currentPlayerIndex = 0;
    statusMessage = 'Le jeu commence !';

    // Deal initial cards
    for (var playerId in playerOrder) {
      playerHands[playerId]!.add(deck.draw()!);
      playerHands[playerId]!.add(deck.draw()!);
      playerStatuses[playerId] = 'Joue';
    }
    dealerHand.add(deck.draw()!);
    dealerHand.add(deck.draw()!);

    _broadcastGameState();
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

  void _hit([String? playerId]) {
    playerId ??= myId;
    if (playerStands[playerId] == true) return;

    final card = deck.draw();
    if (card != null) {
      playerHands[playerId]!.add(card);
    }

    final score = calculateScore(playerHands[playerId]!);
    if (score > 21) {
      playerStatuses[playerId] = 'Bust !';
      playerStands[playerId] = true;
      _nextPlayer();
    }

    if (_service.isHost) {
      _broadcastGameState();
    } else {
      _service.sendMessage({
        'type': 'action',
        'action': 'hit',
        'playerId': playerId,
      });
    }
  }

  void _stand([String? playerId]) {
    playerId ??= myId;
    playerStands[playerId] = true;
    playerStatuses[playerId] = 'Stand';
    _nextPlayer();

    if (_service.isHost) {
      _broadcastGameState();
    } else {
      _service.sendMessage({
        'type': 'action',
        'action': 'stand',
        'playerId': playerId,
      });
    }
  }

  void _nextPlayer() {
    if (!_service.isHost) return;
    currentPlayerIndex++;
    if (currentPlayerIndex >= playerOrder.length) {
      // All players done, dealer turn
      _dealerTurn();
    } else {
      statusMessage = 'Tour de ${playerOrder[currentPlayerIndex]}';
    }
  }

  void _dealerTurn() {
    while (calculateScore(dealerHand) < 17) {
      final card = deck.draw();
      if (card != null) dealerHand.add(card);
    }

    final dealerScore = calculateScore(dealerHand);
    for (var playerId in playerOrder) {
      final playerScore = calculateScore(playerHands[playerId]!);
      if (playerScore > 21) {
        playerStatuses[playerId] = 'Perdu (Bust)';
      } else if (dealerScore > 21) {
        playerStatuses[playerId] = 'Gagné !';
      } else if (playerScore > dealerScore) {
        playerStatuses[playerId] = 'Gagné !';
      } else if (playerScore < dealerScore) {
        playerStatuses[playerId] = 'Perdu';
      } else {
        playerStatuses[playerId] = 'Égalité';
      }
    }
    statusMessage = 'Partie terminée !';
    _broadcastGameState();
  }

  bool get isMyTurn => gameStarted && playerOrder.isNotEmpty && playerOrder[currentPlayerIndex] == myId && !playerStands[myId]!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Blackjack Multijoueur')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(statusMessage, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (_service.isHost && !gameStarted && playerOrder.length >= 2)
              ElevatedButton(onPressed: _startGame, child: const Text('Démarrer le jeu')),
            const SizedBox(height: 16),
            // Dealer hand
            const Text('Croupier', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: dealerHand
                    .asMap()
                    .entries
                    .map((entry) => PlayingCardWidget(
                          card: entry.value,
                          faceDown: !gameStarted || entry.key == 0 && currentPlayerIndex < playerOrder.length,
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 24),
            // Players
            Expanded(
              child: ListView.builder(
                itemCount: playerOrder.length,
                itemBuilder: (context, index) {
                  final playerId = playerOrder[index];
                  final isCurrent = index == currentPlayerIndex;
                  return Card(
                    color: isCurrent ? Colors.blue.shade50 : null,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$playerId ${isCurrent ? '(Tour actuel)' : ''}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          Text('Score: ${calculateScore(playerHands[playerId]!)} - ${playerStatuses[playerId]}'),
                          const SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: playerHands[playerId]!
                                  .map((card) => PlayingCardWidget(card: card))
                                  .toList(),
                            ),
                          ),
                          if (playerId == myId && isMyTurn) ...[
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton(onPressed: () => _hit(), child: const Text('Tirer')),
                                const SizedBox(width: 16),
                                ElevatedButton(onPressed: () => _stand(), child: const Text('Rester')),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _service.disconnect();
    super.dispose();
  }
}