import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tableturf_mobile/src/game_internals/player.dart';
import 'package:tableturf_mobile/src/game_internals/card.dart';
import 'package:tableturf_mobile/src/game_internals/tile.dart';
import 'package:tableturf_mobile/src/level_selection/levels.dart';
import 'package:tableturf_mobile/src/style/my_transition.dart';
import 'package:tableturf_mobile/src/style/palette.dart';

import '../game_internals/opponentAI.dart';
import 'session_intro.dart';

PageRouteBuilder<T> buildGameSessionPage<T>({
  required BuildContext context,
  required String stage,
  required List<TableturfCardData> yellowDeck,
  required List<TableturfCardData> blueDeck,
  required AILevel aiLevel,
  Palette palette = const Palette(),
}) {

  final TileGrid board = maps[stage]!.map<List<TileState>>((row) {
    return (row as List<dynamic>).map(TileState.fromJson).toList(growable: false);
  }).toList(growable: false);

  final yellowDeckCards = yellowDeck
      .map(TableturfCard.new)
      .toList();

  final blueDeckCards = blueDeck
      .map(TableturfCard.new)
      .toList();
  final blueHand = blueDeckCards.randomSample(4);
  for (final card in blueHand) {
    card.isHeld = true;
  }

  final yellowPlayer = TableturfPlayer(
    name: "You",
    deck: yellowDeckCards,
    hand: Iterable.generate(4, (c) => ValueNotifier<TableturfCard?>(null)).toList(),
    traits: const YellowTraits(),
    cardSleeve: "assets/images/card_components/sleeve_cool.png",
    special: 0,
  );
  final bluePlayer = TableturfPlayer(
    name: "Rando",
    deck: blueDeckCards,
    hand: blueHand.map((c) => ValueNotifier(c)).toList(),
    traits: const BlueTraits(),
    special: 0,
  );

  return buildMyTransition(
    child: PlaySessionIntro(
      yellow: yellowPlayer,
      blue: bluePlayer,
      board: board,
      aiLevel: aiLevel,
      key: const Key('play session intro'),
    ),
    color: palette.backgroundPlaySession,
  );
}