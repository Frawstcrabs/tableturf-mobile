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

import '../game_internals/battle.dart';
import '../game_internals/deck.dart';
import '../game_internals/opponentAI.dart';
import 'session_intro.dart';

PageRouteBuilder<T> buildGameSessionPage<T>({
  required BuildContext context,
  required Completer sessionCompleter,
  required LocalTableturfBattle battle,
  void Function()? onWin,
  void Function()? onLose,
  Future<void> Function(BuildContext)? onPostGame,
  required bool showXpPopup,
}) {
  return buildFadeToBlackTransition(
    child: PlaySessionIntro(
      battle: battle,
      sessionCompleter: sessionCompleter,
      boardHeroTag: "boardView-${Random().nextInt(2^31).toString()}",
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

Future<void> startCustomGame({
  required BuildContext context,
  required LocalTableturfBattle battle,
  void Function()? onWin,
  void Function()? onLose,
  Future<void> Function(BuildContext)? onPostGame,
  bool showXpPopup = false,
}) async {
  final sessionCompleter = Completer();
  Navigator.of(context).push(buildGameSessionPage(
    context: context,
    sessionCompleter: sessionCompleter,
    battle: battle,
    onWin: onWin,
    onLose: onLose,
    onPostGame: onPostGame,
    showXpPopup: showXpPopup,
  ));
  await sessionCompleter.future;
  AudioController().stopSong(fadeDuration: Durations.transitionToGame);
}

Future<void> startNormalGame({
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
  final playerProgress = PlayerProgress();

  final yellowDeckCards = yellowDeck.cards
      .map((ident) => TableturfCard(playerProgress.identToCard(ident!)))
      .toList();

  final blueDeckCards = blueDeck.cards
      .map((ident) => TableturfCard(playerProgress.identToCard(ident!)))
      .toList();

  final yellowPlayer = TableturfPlayer(
    id: 0,
    name: yellowName,
    icon: yellowIcon == null ? null : "assets/images/character_icons/$yellowIcon.png",
    traits: const YellowTraits(),
    cardSleeve: "assets/images/card_sleeves/sleeve_${yellowDeck.cardSleeve}.png",
  );
  final bluePlayer = TableturfPlayer(
    id: 1,
    name: blueName,
    icon: blueIcon == null ? null : "assets/images/character_icons/$blueIcon.png",
    traits: const BlueTraits(),
    cardSleeve: "assets/images/card_sleeves/sleeve_${blueDeck.cardSleeve}.png",
  );

  final battle = LocalTableturfBattle(
    player: yellowPlayer,
    playerDeck: yellowDeckCards,
    opponent: bluePlayer,
    opponentDeck: blueDeckCards,
    board: map.board.copy(),
    aiLevel: aiLevel,
    playerAI: playerAI,
  );

  await startCustomGame(context: context, battle: battle);
}