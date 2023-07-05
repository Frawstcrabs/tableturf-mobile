import 'package:flutter/material.dart';

import 'package:tableturf_mobile/src/game_internals/player.dart';
import 'package:tableturf_mobile/src/game_internals/card.dart';
import 'package:tableturf_mobile/src/game_internals/tile.dart';
import 'package:tableturf_mobile/src/level_selection/levels.dart';
import 'package:tableturf_mobile/src/style/my_transition.dart';
import 'package:tableturf_mobile/src/style/palette.dart';

import '../game_internals/deck.dart';
import '../game_internals/opponentAI.dart';
import '../settings/settings.dart';
import 'session_intro.dart';

PageRouteBuilder<T> buildGameSessionPage<T>({
  required BuildContext context,
  required String stage,
  required TableturfDeck yellowDeck,
  required TableturfDeck blueDeck,
  String yellowName = "You",
  required String blueName,
  required AILevel aiLevel,
  AILevel? playerAI,
  Palette palette = const Palette(),
}) {
  final settings = SettingsController();

  final board = settings.getMap(stage);

  final yellowDeckCards = yellowDeck.cards
      .map((ident) => TableturfCard(settings.identToCard(ident)))
      .toList();

  final blueDeckCards = blueDeck.cards
      .map((ident) => TableturfCard(settings.identToCard(ident)))
      .toList();
  final blueHand = blueDeckCards.randomSample(4);
  for (final card in blueHand) {
    card.isHeld = true;
  }

  final yellowPlayer = TableturfPlayer(
    name: yellowName,
    deck: yellowDeckCards,
    hand: Iterable.generate(4, (c) => ValueNotifier<TableturfCard?>(null)).toList(),
    traits: const YellowTraits(),
    cardSleeve: "assets/images/card_sleeves/sleeve_${yellowDeck.cardSleeve}.png",
    special: 0,
  );
  final bluePlayer = TableturfPlayer(
    name: blueName,
    deck: blueDeckCards,
    hand: blueHand.map((c) => ValueNotifier(c)).toList(),
    traits: const BlueTraits(),
    cardSleeve: "assets/images/card_sleeves/sleeve_${blueDeck.cardSleeve}.png",
    special: 0,
  );

  return buildMyTransition(
    child: PlaySessionIntro(
      yellow: yellowPlayer,
      blue: bluePlayer,
      board: board,
      aiLevel: aiLevel,
      playerAI: playerAI,
      key: const Key('play session intro'),
    ),
    color: palette.backgroundPlaySession,
  );
}