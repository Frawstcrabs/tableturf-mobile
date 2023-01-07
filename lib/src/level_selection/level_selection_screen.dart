// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tableturf_mobile/src/game_internals/opponentAI.dart';
import 'package:tableturf_mobile/src/game_internals/player.dart';
import 'package:tableturf_mobile/src/level_selection/opponents.dart';

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
                  for (final opponent in opponents)
                    ListTile(
                      onTap: () {
                        const playerDeck = [97, 98, 158, 12, 44, 136, 21, 51, 140, 27, 54, 102, 0, 55, 91];
                        Navigator.of(context).push(buildGameSessionPage(
                          context: context,
                          stage: opponent.map,
                          yellowDeck: playerDeck.map((i) => cards[i]).toList(),
                          yellowSleeve: "ultracool",
                          blueDeck: (
                            opponent.name == "Clone Jelly"
                              ? playerDeck
                              : opponent.deck
                          ).map((i) => cards[i]).toList(),
                          blueName: opponent.name,
                          blueSleeve: opponent.sleeveDesign,
                          aiLevel: AILevel.level4,
                        ));
                      },
                      title: Text(
                        opponent.name,
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
