import 'dart:math';

import 'card_model.dart';

class Deck {
  final List<CardModel> cards = [];

  Deck() {
    build();
  }

  void build() {
    cards.clear();
    const suits = ['♥', '♦', '♣', '♠'];
    final ranks = <Map<String, Object>>[
      {'rank': '2', 'value': 2},
      {'rank': '3', 'value': 3},
      {'rank': '4', 'value': 4},
      {'rank': '5', 'value': 5},
      {'rank': '6', 'value': 6},
      {'rank': '7', 'value': 7},
      {'rank': '8', 'value': 8},
      {'rank': '9', 'value': 9},
      {'rank': '10', 'value': 10},
      {'rank': 'V', 'value': 10},
      {'rank': 'D', 'value': 10},
      {'rank': 'R', 'value': 10},
      {'rank': 'A', 'value': 11},
    ];

    for (final suit in suits) {
      for (final rankMap in ranks) {
        cards.add(CardModel(
          suit: suit,
          rank: rankMap['rank'] as String,
          value: rankMap['value'] as int,
        ));
      }
    }

    shuffle();
  }

  void shuffle() {
    cards.shuffle(Random());
  }

  CardModel? draw() {
    if (cards.isEmpty) return null;
    return cards.removeLast();
  }
}
