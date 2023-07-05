// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tableturf_mobile/src/game_internals/opponentAI.dart';
import 'package:tableturf_mobile/src/game_internals/player.dart';
import 'package:tableturf_mobile/src/level_selection/opponents.dart';
import 'package:tableturf_mobile/src/settings/settings.dart';

import '../game_internals/card.dart';
import '../game_internals/deck.dart';
import '../game_internals/tile.dart';
import '../play_session/build_game_session_page.dart';
import '../style/palette.dart';
import '../style/responsive_screen.dart';
import 'levels.dart';

const cardNameCharacters = [
  'A', 'B', 'C', 'D', 'E', 'F',
  'G', 'H', 'I', 'J', 'K', 'L',
  'M', 'N', 'O', 'P', 'Q', 'R',
  'S', 'T', 'U', 'V', 'W', 'X',
  'Y', 'Z'
];

Set<Coords> getSurroundingCoords(Coords point, [bool checkBounds = true]) {
  return Set.of([
    for (int dy = -1; dy <= 1; dy++)
      for (int dx = -1; dx <= 1; dx++)
        if (
          !checkBounds || (
              point.x + dx >= 0 && point.x + dx < 8 &&
              point.y + dy >= 0 && point.y + dy < 8))
          Coords(point.x + dx, point.y + dy)
  ])..remove(point);
}

int randomiserCardID = 0;
List<TableturfCardData> createPureRandomDeck() {
  const cardSizes = [
    1, 2, 3, 4, 5, 6,
    7, 7, 8, 8, 9, 9, 10, 10,
    11, 12, 13, 14, 15, 16, 17
  ];
  const specialCosts = [1, 1, 1, 1, 2, 2, 3, 3, 3, 4, 4, 4, 5, 5, 5, 6, 6, 6];
  final rng = Random();
  var noSpecialCards = 2;
  final List<TableturfCardData> ret = [];
  for (final size in cardSizes.randomSample(15)) {
    final rawPattern = [
      for (int i = 0; i < 8; i++) [
        for (int j = 0; j < 8; j++)
          TileState.unfilled
      ]
    ];
    late final bool hasSpecial;
    if (noSpecialCards > 0 && size >= 6 && rng.nextDouble() < 0.05) {
      hasSpecial = false;
      noSpecialCards -= 1;
    } else {
      hasSpecial = true;
    }

    final Coords startPoint = Coords(rng.nextInt(8), rng.nextInt(8));
    final Set<Coords> specialSurrounding = getSurroundingCoords(startPoint, false);
    final Set<Coords> filledTiles = {startPoint};
    rawPattern[startPoint.y][startPoint.x] = hasSpecial ? TileState.yellowSpecial : TileState.yellow;
    for (var i = 1; i < size; i++) {
      while (true) {
        final nextStartPoint = filledTiles.toList().random();
        final newPoint = getSurroundingCoords(nextStartPoint).toList().random();
        if (filledTiles.contains(newPoint)) {
          continue;
        }
        if (hasSpecial && specialSurrounding.contains(newPoint) && specialSurrounding.length == 1) {
          // adding this point would mean the special is completely surrounded, which we can't allow
          continue;
        }
        filledTiles.add(newPoint);
        specialSurrounding.remove(newPoint);
        rawPattern[newPoint.y][newPoint.x] = TileState.yellow;
        break;
      }
    }

    final centeredPattern = getMinPattern(rawPattern);
    final height = centeredPattern.length;
    final width = centeredPattern[0].length;

    for (var i = width; i < 8; i++) {
      if (i % 2 == 1) {
        for (final row in centeredPattern) {
          row.add(TileState.unfilled);
        }
      } else {
        for (final row in centeredPattern) {
          row.insert(0, TileState.unfilled);
        }
      }
    }

    for (var i = height; i < 8; i++) {
      if (i % 2 == 1) {
        centeredPattern.add([
          TileState.unfilled, TileState.unfilled,
          TileState.unfilled, TileState.unfilled,
          TileState.unfilled, TileState.unfilled,
          TileState.unfilled, TileState.unfilled,
        ]);
      } else {
        centeredPattern.insert(0, [
          TileState.unfilled, TileState.unfilled,
          TileState.unfilled, TileState.unfilled,
          TileState.unfilled, TileState.unfilled,
          TileState.unfilled, TileState.unfilled,
        ]);
      }
    }

    final name = cardNameCharacters.randomSample(3 + rng.nextInt(7)).join();
    final specialCost = max(1, specialCosts[size] - (hasSpecial ? 0 : 2));
    ret.add(TableturfCardData(
        randomiserCardID,
      name,
      "randomiser",
      specialCost,
      centeredPattern,
      name,
      TableturfCardType.randomiser,
      "assets/images/card_illustrations/random${rng.nextInt(4)}.png"
    ));
    randomiserCardID += 1;
  }
  return ret;
}

class LevelSelectionScreen extends StatelessWidget {
  const LevelSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();
    final settings = SettingsController();
    //final playerProgress = context.watch<PlayerProgress>();

    return Scaffold(
      backgroundColor: palette.backgroundLevelSelection,
      body: ResponsiveScreen(
        squarishMainArea: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'Select Level',
                  style: TextStyle(fontFamily: 'Splatfont1', fontSize: 30),
                ),
              ),
            ),
            const SizedBox(height: 50),
            Expanded(
              child: ListView(
                children: <ListTile>[
                  for (final opponent in opponents)
                    ListTile(
                      onTap: () {
                        final yellowDeck = settings.decks[0].value;
                        Navigator.of(context).push(buildGameSessionPage(
                          context: context,
                          stage: opponent.map,
                          yellowDeck: yellowDeck,
                          blueDeck: opponent.deck,
                          blueName: opponent.name,
                          aiLevel: AILevel.level4,
                        ));
                      },
                      title: Text(
                        opponent.name,
                        style: TextStyle(fontFamily: "Splatfont2")
                      )
                    ),
                  ListTile(
                    onTap: () {
                      final yellowDeck = settings.decks[0].value;
                      Navigator.of(context).push(buildGameSessionPage(
                        context: context,
                        stage: "main_street",
                        yellowDeck: yellowDeck,
                        blueDeck: yellowDeck,
                        blueName: "Clone Jelly",
                        aiLevel: AILevel.level4,
                      ));
                    },
                    title: Text(
                      "Clone Jelly",
                      style: TextStyle(fontFamily: "Splatfont2")
                    )
                  ),
                  ListTile(
                    onTap: () async {
                      final randomCards = createPureRandomDeck() + createPureRandomDeck();
                      for (final card in randomCards) {
                        settings.registerTempCard(card);
                      }
                      final yellowDeck = TableturfDeck(
                          deckID: -1,
                          name: "Randomiser",
                          cardSleeve: "randomiser",
                          cards: [for (final card in randomCards.sublist(0, 15)) card.ident]
                      );
                      final blueDeck = TableturfDeck(
                          deckID: -1,
                          name: "Randomiser",
                          cardSleeve: "randomiser",
                          cards: [for (final card in randomCards.sublist(15, 30)) card.ident]
                      );
                      await Navigator.of(context).push(buildGameSessionPage(
                        context: context,
                        stage: maps.keys.toList().random(),
                        yellowDeck: yellowDeck,
                        blueDeck: blueDeck,
                        blueName: "Randomiser",
                        aiLevel: AILevel.level4,
                      ));
                      for (final card in randomCards) {
                        settings.removeTempCard(card.ident);
                      }
                    },
                    title: Text(
                      "Randomiser",
                      style: TextStyle(fontFamily: "Splatfont2")
                    )
                  )
                ],
              ),
            ),
          ],
        ),
        rectangularMenuArea: ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Back'),
        ),
      ),
    );
  }
}
