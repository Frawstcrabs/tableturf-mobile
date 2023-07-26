// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:tableturf_mobile/src/game_internals/opponentAI.dart';
import 'package:tableturf_mobile/src/game_internals/player.dart';
import 'package:tableturf_mobile/src/level_selection/level_selection_screen.dart';
import 'package:tableturf_mobile/src/level_selection/opponents.dart';
import 'package:tableturf_mobile/src/settings/settings.dart';

import '../game_internals/card.dart';
import '../game_internals/deck.dart';
import '../game_internals/map.dart';
import '../play_session/build_game_session_page.dart';
import '../style/constants.dart';
import '../style/responsive_screen.dart';

class FreePlayScreen extends StatefulWidget {
  const FreePlayScreen({Key? key}) : super(key: key);

  @override
  State<FreePlayScreen> createState() => _FreePlayScreenState();
}

class _FreePlayScreenState extends State<FreePlayScreen> {
  TableturfDeck? opponentDeck = null;
  TableturfDeck? playerDeck = null;
  TableturfMap? map = null;
  AILevel? difficulty = null;
  AILevel? playerAI = null;

  @override
  Widget build(BuildContext context) {
    final settings = Settings();
    //final playerProgress = context.watch<PlayerProgress>();
    const officialRandomiser = TableturfDeck(
      deckID: -1000,
      cardSleeve: "default",
      name: "Randomiser",
      cards: [],
    );
    const pureRandomiser = TableturfDeck(
      deckID: -1001,
      cardSleeve: "default",
      name: "Randomiser",
      cards: [],
    );

    final deckList = [
      for (final deck in settings.decks)
        deck.value,
      //officialRandomiser,
      pureRandomiser,
      for (final opponent in opponents)
        opponent.deck,
    ];
    final deckListWidgets = [
      for (final deck in deckList)
        DropdownMenuItem(
          value: deck,
          child: Text(deck.name)
        )
    ];
    return Scaffold(
      backgroundColor: Palette.backgroundLevelSelection,
      body: ResponsiveScreen(
        squarishMainArea: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'Free Play',
                  style: TextStyle(fontFamily: 'Splatfont1', fontSize: 30),
                ),
              ),
            ),
            const SizedBox(height: 50),
            DropdownButton2<TableturfDeck?>(
              isExpanded: true,
              hint: Text("Select opponent"),
              value: opponentDeck,
              onChanged: (TableturfDeck? newDeck) {
                setState(() {
                  opponentDeck = newDeck;
                });
              },
              items: deckListWidgets,
            ),
            DropdownButton2<TableturfDeck?>(
              isExpanded: true,
              hint: Text("Select deck"),
              value: playerDeck,
              onChanged: (TableturfDeck? newDeck) {
                setState(() {
                  playerDeck = newDeck;
                });
              },
              items: deckListWidgets,
            ),
            DropdownButton2<TableturfMap?>(
              isExpanded: true,
              hint: Text("Select map"),
              value: map,
              onChanged: (TableturfMap? newMap) {
                setState(() {
                  map = newMap;
                });
              },
              items: [
                for (final map in officialMaps + settings.maps.map((m) => m.value).toList())
                  DropdownMenuItem(
                    value: map,
                    child: Text(map.name)
                  )
              ],
            ),
            DropdownButton2<AILevel>(
              isExpanded: true,
              hint: Text("Select difficulty"),
              value: difficulty,
              onChanged: (AILevel? newDifficulty) {
                setState(() {
                  difficulty = newDifficulty;
                });
              },
              items: [
                for (var i = 0; i < AILevel.values.length; i++)
                  DropdownMenuItem(
                    value: AILevel.values[i],
                    child: Text("Level ${i+1}")
                  )
              ],
            ),
            DropdownButton2<AILevel>(
              isExpanded: true,
              hint: Text("Player controlled"),
              value: playerAI,
              onChanged: (AILevel? newDifficulty) {
                setState(() {
                  playerAI = newDifficulty;
                });
              },
              items: [
                DropdownMenuItem(
                  value: null,
                  child: Text("Player controlled")
                ),
                for (var i = 0; i < AILevel.values.length; i++)
                  DropdownMenuItem(
                    value: AILevel.values[i],
                    child: Text("Level ${i+1}")
                  )
              ],
            ),
            ElevatedButton(
              onPressed: () async {
                if (opponentDeck == null || playerDeck == null || map == null || difficulty == null) {
                  return;
                }
                List<TableturfCardData>? blueRandomiser = null;
                List<TableturfCardData>? yellowRandomiser = null;
                TableturfDeck tempPlayerDeck, tempOpponentDeck;
                if (playerDeck!.deckID == -1000) {
                  // official randomiser
                  tempPlayerDeck = TableturfDeck(
                    deckID: -1000,
                    cardSleeve: "default",
                    name: "Randomiser",
                    cards: officialCards.randomSample(15).map((c) => c.ident).toList(),
                  );
                } else if (playerDeck!.deckID == -1001) {
                  // pure randomiser
                  yellowRandomiser = createPureRandomCards();
                  for (final card in yellowRandomiser) {
                    settings.registerTempCard(card);
                  }
                  tempPlayerDeck = TableturfDeck(
                    deckID: -1001,
                    cardSleeve: "randomiser",
                    name: "Randomiser",
                    cards: yellowRandomiser.map((c) => c.ident).toList(),
                  );
                } else {
                  tempPlayerDeck = playerDeck!;
                }
                if (opponentDeck!.deckID == -1000) {
                  // official randomiser
                  tempOpponentDeck = TableturfDeck(
                    deckID: -1000,
                    cardSleeve: "default",
                    name: "Randomiser",
                    cards: officialCards.randomSample(15).map((c) => c.ident).toList(),
                  );
                } else if (opponentDeck!.deckID == -1001) {
                  // pure randomiser
                  blueRandomiser = createPureRandomCards();
                  for (final card in blueRandomiser) {
                    settings.registerTempCard(card);
                  }
                  tempOpponentDeck = TableturfDeck(
                    deckID: -1001,
                    cardSleeve: "randomiser",
                    name: "Randomiser",
                    cards: blueRandomiser.map((c) => c.ident).toList(),
                  );
                } else {
                  tempOpponentDeck = opponentDeck!;
                }

                final playerName = playerAI != null ? tempPlayerDeck.name : settings.playerName.value;

                await startGame(
                  context: context,
                  map: map!,
                  yellowDeck: tempPlayerDeck,
                  yellowName: playerName,
                  yellowIcon: deckIcons[tempPlayerDeck.deckID],
                  blueDeck: tempOpponentDeck,
                  blueName: tempOpponentDeck.name,
                  blueIcon: deckIcons[tempOpponentDeck.deckID],
                  playerAI: playerAI,
                  aiLevel: difficulty!,
                );
                if (yellowRandomiser != null) {
                  for (final card in yellowRandomiser) {
                    settings.removeTempCard(card.ident);
                  }
                }
                if (blueRandomiser != null) {
                  for (final card in blueRandomiser) {
                    settings.removeTempCard(card.ident);
                  }
                }
              },
              child: const Text('Play'),
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
