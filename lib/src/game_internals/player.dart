import 'dart:ui';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'card.dart';
import 'tile.dart';

extension RandomChoice<T> on List<T> {
  T random() => this[Random().nextInt(this.length)];

  List<T> randomSample(int count) {
    assert(this.length >= count);
    final rng = Random();
    final ret = <T>[];
    final indexes = Iterable<int>.generate(this.length).toList();
    for (var i = 0; i < count; i++) {
      ret.add(this[indexes.removeAt(rng.nextInt(indexes.length))]);
    }
    return ret;
  }
}

class TableturfPlayer {
  final String name;
  final List<TableturfCard> deck;
  final List<ValueNotifier<TableturfCard?>> hand;
  final ValueNotifier<int> special;
  final PlayerTraits traits;

  TableturfPlayer({
    required this.name,
    required this.deck,
    required this.hand,
    required this.traits,
    special = 0
  }): special = ValueNotifier(special);

  void refreshHand() {
    print(deck.map((card) => !card.isHeld).toList());
    print(deck.map((card) => !card.hasBeenPlayed).toList());
    for (var i = 0; i < hand.length; i++) {
      final card = hand[i].value;
      if (card == null) {
        continue;
      }
      if (card.hasBeenPlayed) {
        final newCard = deck.where((card) => !card.isHeld && !card.hasBeenPlayed).toList().random();
        card.isHeld = false;
        newCard.isHeld = true;
        hand[i].value = newCard;
      }
    }
  }
}

abstract class PlayerTraits {
  abstract final TileState normalTile;
  abstract final TileState specialTile;

  abstract final Color normalColour;
  abstract final Color specialColour;

  abstract final Color scoreCountBackground;
  abstract final Color scoreCountText;
  abstract final Color scoreCountShadow;
}

class YellowTraits implements PlayerTraits {
  final normalTile = TileState.yellow;
  final specialTile = TileState.yellowSpecial;

  final normalColour = const Color.fromRGBO(255, 255, 17, 1);
  final specialColour = const Color.fromRGBO(255, 159, 4, 1);

  final scoreCountBackground = const Color.fromRGBO(129, 128, 5, 1.0);
  final scoreCountText = const Color.fromRGBO(233, 255, 122, 1);
  final scoreCountShadow = const Color.fromRGBO(167, 171, 15, 1.0);

  const YellowTraits();
}

class BlueTraits implements PlayerTraits {
  final normalTile = TileState.blue;
  final specialTile = TileState.blueSpecial;

  final normalColour = const Color.fromRGBO(71, 92, 255, 1);
  final specialColour = const Color.fromRGBO(10, 255, 255, 1);

  final scoreCountBackground = const Color.fromRGBO(33, 5, 139, 1);
  final scoreCountText = const Color.fromRGBO(102, 124, 255, 1);
  final scoreCountShadow = const Color.fromRGBO(57, 69, 147, 1);

  const BlueTraits();
}