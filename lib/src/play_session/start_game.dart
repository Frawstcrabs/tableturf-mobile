import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:tableturf_mobile/src/audio/audio_controller.dart';

import 'package:tableturf_mobile/src/game_internals/player.dart';
import 'package:tableturf_mobile/src/game_internals/card.dart';
import 'package:tableturf_mobile/src/game_internals/map.dart';
import 'package:tableturf_mobile/src/game_internals/tile.dart';
import 'package:tableturf_mobile/src/player_progress/player_progress.dart';
import 'package:tableturf_mobile/src/style/my_transition.dart';
import 'package:tableturf_mobile/src/style/constants.dart';

import '../game_internals/deck.dart';
import '../game_internals/opponentAI.dart';
import 'session_intro.dart';

PageRouteBuilder<T> _buildGameSessionPage<T>({
  required BuildContext context,
  required Completer sessionCompleter,
  required TableturfMap map,
  required TableturfDeck yellowDeck,
  required TableturfDeck blueDeck,
  String yellowName = "You",
  String blueName = "Them",
  String? yellowIcon,
  String? blueIcon,
  required AILevel aiLevel,
  AILevel? playerAI,
  void Function()? onWin,
  void Function()? onLose,
  Future<void> Function(BuildContext)? onPostGame,
  required bool showXpPopup,
}) {
  final playerProgress = PlayerProgress();

  final yellowDeckCards = yellowDeck.cards
      .map((ident) => TableturfCard(playerProgress.identToCard(ident)))
      .toList();

  final blueDeckCards = blueDeck.cards
      .map((ident) => TableturfCard(playerProgress.identToCard(ident)))
      .toList();

  final yellowPlayer = TableturfPlayer(
    name: yellowName,
    deck: yellowDeckCards,
    icon: yellowIcon == null ? null : "assets/images/character_icons/$yellowIcon.png",
    hand: Iterable.generate(4, (c) => ValueNotifier<TableturfCard?>(null)).toList(),
    traits: const YellowTraits(),
    cardSleeve: "assets/images/card_sleeves/sleeve_${yellowDeck.cardSleeve}.png",
    special: 0,
  );
  final bluePlayer = TableturfPlayer(
    name: blueName,
    deck: blueDeckCards,
    icon: blueIcon == null ? null : "assets/images/character_icons/$blueIcon.png",
    hand: Iterable.generate(4, (c) => ValueNotifier<TableturfCard?>(null)).toList(),
    traits: const BlueTraits(),
    cardSleeve: "assets/images/card_sleeves/sleeve_${blueDeck.cardSleeve}.png",
    special: 0,
  );

  return buildFadeToBlackTransition(
    child: PlaySessionIntro(
      sessionCompleter: sessionCompleter,
      yellow: yellowPlayer,
      blue: bluePlayer,
      board: map.board.copy(),
      boardHeroTag: "boardView-${Random().nextInt(2^31).toString()}",
      aiLevel: aiLevel,
      playerAI: playerAI,
      onWin: onWin,
      onLose: onLose,
      onPostGame: onPostGame,
      showXpPopup: showXpPopup,
    ),
    color: Palette.backgroundPlaySession,
    transitionDuration: Durations.transitionToGame,
    reverseTransitionDuration: Durations.transitionToGame,
  );
}

Future<void> startGame({
  required BuildContext context,
  required TableturfMap map,
  required TableturfDeck yellowDeck,
  required TableturfDeck blueDeck,
  String yellowName = "You",
  String blueName = "Them",
  String? yellowIcon,
  String? blueIcon,
  required AILevel aiLevel,
  AILevel? playerAI,
  void Function()? onWin,
  void Function()? onLose,
  Future<void> Function(BuildContext)? onPostGame,
  bool showXpPopup = false,
}) async {
  final sessionCompleter = Completer();
  Navigator.of(context).push(_buildGameSessionPage(
    context: context,
    sessionCompleter: sessionCompleter,
    map: map,
    yellowDeck: yellowDeck,
    blueDeck: blueDeck,
    yellowName: yellowName,
    blueName: blueName,
    yellowIcon: yellowIcon,
    blueIcon: blueIcon,
    aiLevel: aiLevel,
    playerAI: playerAI,
    onWin: onWin,
    onLose: onLose,
    onPostGame: onPostGame,
    showXpPopup: showXpPopup,
  ));
  await sessionCompleter.future;
  AudioController().stopSong(fadeDuration: Durations.transitionToGame);
}