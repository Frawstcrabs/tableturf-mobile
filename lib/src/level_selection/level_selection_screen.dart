// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tableturf_mobile/src/game_internals/opponentAI.dart';
import 'package:tableturf_mobile/src/game_internals/player.dart';

import '../audio/audio_controller.dart';
import '../audio/sounds.dart';
import '../game_internals/card.dart';
import '../play_session/build_game_session_page.dart';
import '../player_progress/player_progress.dart';
import '../style/palette.dart';
import '../style/responsive_screen.dart';
import 'levels.dart';

class LevelSelectionScreen extends StatelessWidget {
  const LevelSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();
    final playerProgress = context.watch<PlayerProgress>();

    return Scaffold(
      backgroundColor: palette.backgroundLevelSelection,
      body: ResponsiveScreen(
        squarishMainArea: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'Select level',
                  style:
                      TextStyle(fontFamily: 'Splatfont1', fontSize: 30),
                ),
              ),
            ),
            const SizedBox(height: 50),
            Expanded(
              child: ListView(
                children: [
                  for (final map in maps.keys)
                    ListTile(
                      onTap: () {
                        //const starterDeck = [5, 33, 158, 12, 44, 136, 21, 51, 140, 27, 54, 102, 39, 55, 91];
                        const starterDeck = [97, 98, 158, 12, 44, 136, 21, 51, 140, 27, 54, 102, 0, 55, 91];
                        Navigator.of(context).push(buildGameSessionPage(
                          context: context,
                          stage: map,
                          yellowDeck: starterDeck.map((i) => cards[i]).toList(),
                          blueDeck: starterDeck.map((i) => cards[i]).toList(),
                          //yellowDeck: cards.randomSample(15),
                          //blueDeck: cards.randomSample(15),
                          aiLevel: AILevel.level3,
                        ));
                      },
                      title: Text(
                        map.splitMapJoin("_",
                          onMatch: (s) => " ",
                          onNonMatch: (s) => "${s[0].toUpperCase()}${s.substring(1).toLowerCase()}"
                        ),
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
