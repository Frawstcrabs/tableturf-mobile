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
  final String? icon;
  final List<TableturfCard> deck;
  final List<ValueNotifier<TableturfCard?>> hand;
  final ValueNotifier<int> special;
  final String cardSleeve;
  final PlayerTraits traits;

  TableturfPlayer({
    required this.name,
    this.icon,
    required this.deck,
    required this.hand,
    required this.traits,
    this.cardSleeve = "assets/images/card_sleeves/sleeve_default.png",
    special = 0,
  }): special = ValueNotifier(special);

  void refreshHand() {
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

  void reset() {
    for (final card in deck) {
      card.isHeld = false;
      card.hasBeenPlayed = false;
      card.isPlayable = false;
      card.isPlayableSpecial = false;
    }
    for (final card in hand) {
      card.value = null;
    }
    special.value = 0;
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

  const PlayerTraits();

  TileState mapCardTile(TileState tile) {
    switch (tile) {
      case TileState.yellow: return normalTile;
      case TileState.yellowSpecial: return specialTile;
      default: return tile;
    }
  }
}

class YellowTraits extends PlayerTraits {
  get normalTile => TileState.yellow;
  get specialTile => TileState.yellowSpecial;

  get normalColour => const Color.fromRGBO(255, 255, 17, 1);
  get specialColour => const Color.fromRGBO(255, 159, 4, 1);

  get scoreCountBackground => const Color.fromRGBO(129, 128, 5, 1.0);
  get scoreCountText => const Color.fromRGBO(233, 255, 122, 1);
  get scoreCountShadow => const Color.fromRGBO(167, 171, 15, 1.0);

  const YellowTraits();
}

class BlueTraits extends PlayerTraits {
  get normalTile => TileState.blue;
  get specialTile => TileState.blueSpecial;

  get normalColour => const Color.fromRGBO(71, 92, 255, 1);
  get specialColour => const Color.fromRGBO(10, 255, 255, 1);

  get scoreCountBackground => const Color.fromRGBO(33, 5, 139, 1);
  get scoreCountText => const Color.fromRGBO(102, 124, 255, 1);
  get scoreCountShadow => const Color.fromRGBO(57, 69, 147, 1);

  const BlueTraits();
}