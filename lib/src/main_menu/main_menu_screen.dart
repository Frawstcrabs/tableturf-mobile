// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../level_selection/level_selection_screen.dart';
import '../card_manager/card_list_screen.dart';
import '../settings/settings.dart';
import '../settings/settings_screen.dart';
import '../style/my_transition.dart';
import '../style/palette.dart';
import '../style/responsive_screen.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();
    final settingsController = context.watch<SettingsController>();

    return Scaffold(
      backgroundColor: palette.backgroundMain,
      body: ResponsiveScreen(
        mainAreaProminence: 0.45,
        squarishMainArea: Center(
          child: Transform.rotate(
            angle: -0.1,
            child: const Text(
              'Tableturf Mobile',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Splatfont1',
                fontSize: 55,
                height: 1,
              ),
            ),
          ),
        ),
        rectangularMenuArea: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              onPressed: () {
                //audioController.playSfx(SfxType.buttonTap);
                Navigator.of(context).push(buildMyTransition<void>(
                  child: const LevelSelectionScreen(),
                  color: palette.backgroundLevelSelection,
                ));
              },
              child: const Text('Continue'),
            ),
            _gap,
            ElevatedButton(
              onPressed: () {
                //audioController.playSfx(SfxType.buttonTap);
                Navigator.of(context).push(buildMyTransition<void>(
                  child: const LevelSelectionScreen(),
                  color: palette.backgroundLevelSelection,
                ));
              },
              child: const Text('Free play'),
            ),
            _gap,
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(buildMyTransition<void>(
                  child: const CardListScreen(),
                  color: palette.backgroundCardList,
                ));
              },
              child: const Text("Manage Cards")
            ),
            _gap,
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) {
                    return const SettingsScreen(key: Key('settings'));
                  })
                );
              },
              child: const Text('Settings'),
            ),
            _gap,
            Padding(
              padding: const EdgeInsets.only(top: 32),
              child: ValueListenableBuilder<bool>(
                valueListenable: settingsController.muted,
                builder: (context, muted, child) {
                  return IconButton(
                    onPressed: () => settingsController.toggleMuted(),
                    icon: Icon(muted ? Icons.volume_off : Icons.volume_up),
                  );
                },
              ),
            ),
            _gap,
            const Text('Music by Mr Smith'),
            _gap,
          ],
        ),
      ),
    );
  }

  /// Prevents the game from showing game-services-related menu items
  /// until we're sure the player is signed in.
  ///
  /// This normally happens immediately after game start, so players will not
  /// see any flash. The exception is folks who decline to use Game Center
  /// or Google Play Game Services, or who haven't yet set it up.
  Widget _hideUntilReady({required Widget child, required Future<bool> ready}) {
    return FutureBuilder<bool>(
      future: ready,
      builder: (context, snapshot) {
        // Use Visibility here so that we have the space for the buttons
        // ready.
        return Visibility(
          visible: snapshot.data ?? false,
          maintainState: true,
          maintainSize: true,
          maintainAnimation: true,
          child: child,
        );
      },
    );
  }

  static const _gap = SizedBox(height: 10);
}
