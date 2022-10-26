import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'card.dart';
import 'tile.dart';

class TableturfPlayer {
  final List<TableturfCard> deck;
  final List<TableturfCard> hand;
  final ValueNotifier<int> special;

  TableturfPlayer({
    required this.deck,
    required this.hand,
    special = 0
  }): special = ValueNotifier(special);
}

abstract class PlayerTraits {
  abstract final TileState normalTile;
  abstract final TileState specialTile;

  abstract final Color normalColour;
  abstract final Color specialColour;
}

class YellowTraits implements PlayerTraits {
  final normalTile = TileState.Yellow;
  final specialTile = TileState.YellowSpecial;

  final normalColour = const Color.fromRGBO(255, 255, 17, 1);
  final specialColour = const Color.fromRGBO(255, 159, 4, 1);

  const YellowTraits();
}

class BlueTraits implements PlayerTraits {
  final normalTile = TileState.Blue;
  final specialTile = TileState.BlueSpecial;

  final normalColour = const Color.fromRGBO(71, 92, 255, 1);
  final specialColour = const Color.fromRGBO(10, 255, 255, 1);

  const BlueTraits();
}