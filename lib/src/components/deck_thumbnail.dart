import 'package:flutter/material.dart';

import '../game_internals/deck.dart';
import 'card_widget.dart';

class DeckThumbnail extends StatelessWidget {
  static const THUMBNAIL_RATIO = 3.95;
  final TableturfDeck deck;
  const DeckThumbnail({super.key, required this.deck});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(),
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(5),
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: FractionallySizedBox(
                widthFactor: (CardWidget.CARD_WIDTH + 40) / CardWidget.CARD_WIDTH,
                child: Image.asset(
                  "assets/images/card_sleeves/sleeve_${deck.cardSleeve}.png",
                  color: Color.fromRGBO(32, 32, 32, 0.4),
                  colorBlendMode: BlendMode.srcATop,
                  fit: BoxFit.fitWidth,
                ),
              ),
            ),
            Center(
              child: Text(
                deck.name,
                style: TextStyle(color: Colors.white),
              )
            ),
          ],
        ),
      ),
    );
  }
}