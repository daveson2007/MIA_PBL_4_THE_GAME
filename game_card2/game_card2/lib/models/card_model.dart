import 'package:flutter/material.dart';

class CardModel {
  final String suit;
  final String rank;
  final int value;
  final Color color;

  CardModel({
    required this.suit,
    required this.rank,
    required this.value,
  }) : color = (suit == '♥' || suit == '♦' || suit == 'Coeur' || suit == 'Carreau') ? Colors.red : Colors.black;

  String get suitSymbol {
    switch (suit) {
      case 'Coeur':
      case '♥':
        return '♥';
      case 'Carreau':
      case '♦':
        return '♦';
      case 'Trefle':
      case '♣':
        return '♣';
      case 'Pique':
      case '♠':
        return '♠';
      default:
        return suit;
    }
  }

  String get label => '$rank$suitSymbol';

  Map<String, dynamic> toJson() {
    return {
      'suit': suit,
      'rank': rank,
      'value': value,
    };
  }

  factory CardModel.fromJson(Map<String, dynamic> json) {
    return CardModel(
      suit: json['suit'],
      rank: json['rank'],
      value: json['value'],
    );
  }
}
