// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../audio/audio_controller.dart';
import '../audio/sounds.dart';
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
                        //final audioController = context.read<AudioController>();
                        //audioController.playSfx(SfxType.buttonTap);

                        GoRouter.of(context)
                            .go('/play/session/$map');
                      },
                      title: Text(
                        map.splitMapJoin("_",
                          onMatch: (s) => " ",
                          onNonMatch: (s) => "${s[0].toUpperCase()}${s.substring(1).toLowerCase()}"
                        ),
                        style: TextStyle(
                          fontFamily: "Splatfont2"
                        )
                      )
                    )
                ],
              ),
            ),
          ],
        ),
        rectangularMenuArea: ElevatedButton(
          onPressed: () {
            GoRouter.of(context).pop();
          },
          child: const Text('Back'),
        ),
      ),
    );
  }
}
