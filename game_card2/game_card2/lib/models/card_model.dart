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
  }) : color = (suit == '♥' || suit == '♦') ? Colors.red : Colors.black;

  String get label => '$rank$suit';
}
