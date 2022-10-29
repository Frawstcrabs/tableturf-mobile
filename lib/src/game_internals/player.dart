import 'dart:ui';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'card.dart';
import 'tile.dart';

class TableturfPlayer {
  final List<TableturfCard> deck;
  final List<ValueNotifier<TableturfCard?>> hand;
  final ValueNotifier<int> special;

  TableturfPlayer({
    required this.deck,
    required this.hand,
    special = 0
  }): special = ValueNotifier(special);

  void changeHandCard(TableturfCard card) {
    hand[hand.indexWhere((element) => element.value == card)].value = deck.removeAt(Random().nextInt(deck.length));
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
  final normalTile = TileState.Yellow;
  final specialTile = TileState.YellowSpecial;

  final normalColour = const Color.fromRGBO(255, 255, 17, 1);
  final specialColour = const Color.fromRGBO(255, 159, 4, 1);

  final scoreCountBackground = const Color.fromRGBO(129, 128, 5, 1.0);
  final scoreCountText = const Color.fromRGBO(233, 255, 122, 1);
  final scoreCountShadow = const Color.fromRGBO(167, 171, 15, 1.0);

  const YellowTraits();
}

class BlueTraits implements PlayerTraits {
  final normalTile = TileState.Blue;
  final specialTile = TileState.BlueSpecial;

  final normalColour = const Color.fromRGBO(71, 92, 255, 1);
  final specialColour = const Color.fromRGBO(10, 255, 255, 1);

  final scoreCountBackground = const Color.fromRGBO(33, 5, 139, 1);
  final scoreCountText = const Color.fromRGBO(102, 124, 255, 1);
  final scoreCountShadow = const Color.fromRGBO(57, 69, 147, 1);

  const BlueTraits();
}