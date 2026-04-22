import 'package:flutter/material.dart';

import '../models/card_model.dart';

class PlayingCardWidget extends StatelessWidget {
  final CardModel? card;
  final bool faceDown;
  final bool selected;
  final VoidCallback? onTap;

  const PlayingCardWidget({
    super.key,
    required this.card,
    this.faceDown = false,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? Colors.amber : Colors.grey.shade300;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 70,
          height: 100,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: faceDown ? Colors.blueGrey.shade900 : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: faceDown || card == null
              ? Center(
                  child: Icon(
                    Icons.help_outline,
                    color: Colors.white.withOpacity(0.8),
                    size: 32,
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      card!.rank,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: card!.color,
                      ),
                    ),
                    Text(
                      card!.suitSymbol,
                      style: TextStyle(
                        fontSize: 28,
                        color: card!.color,
                      ),
                    ),
                    Opacity(
                      opacity: 0.65,
                      child: Text(
                        card!.rank,
                        style: TextStyle(
                          fontSize: 14,
                          color: card!.color,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
