// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Uncomment the following lines when enabling Firebase Crashlytics
// import 'dart:io';
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';

import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tableturf_mobile/src/game_internals/card.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import 'src/app_lifecycle/app_lifecycle.dart';
import 'src/audio/audio_controller.dart';
import 'src/level_selection/levels.dart';
import 'src/main_menu/main_menu_screen.dart';
import 'src/player_progress/persistence/local_storage_player_progress_persistence.dart';
import 'src/player_progress/persistence/player_progress_persistence.dart';
import 'src/player_progress/player_progress.dart';
import 'src/settings/settings.dart';
import 'src/style/palette.dart';
import 'src/style/snack_bar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadCards();
  await loadMaps();
  await guardedMain();
}

/// Without logging and crash reporting, this would be `void main()`.
Future<void> guardedMain() async {
  if (kReleaseMode) {
    // Don't log anything below warnings in production.
    Logger.root.level = Level.WARNING;
  }
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.time}: '
        '${record.loggerName}: '
        '${record.message}');
  });

  _log.info('Going full screen');
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );

  final SharedPreferences prefs = await SharedPreferences.getInstance();
  if (!prefs.containsKey("tableturf-deck_nextID")) {
    print("Initialising deck data");
    await prefs.setInt("tableturf-deck_nextID", 1);
    await prefs.setString("tableturf-deck_list", "[0]");
    await prefs.setString("tableturf-deck_deck-0", '''{
      "name": "Deck 1",
      "cardSleeve": "default",
      "deckID": 0,
      "cards": ${jsonEncode([
        for (final cardID in [5, 12, 21, 27, 33, 39, 44, 51, 54, 55, 91, 102, 136, 140, 158])
          cards[cardID].toJson()
      ])}
    }''');
  }

  runApp(
    MyApp(
      sharedPreferences: prefs,
      playerProgressPersistence: LocalStoragePlayerProgressPersistence(),
    ),
  );
}

Logger _log = Logger('main.dart');

class MyApp extends StatelessWidget {
  final PlayerProgressPersistence playerProgressPersistence;
  final SharedPreferences sharedPreferences;

  const MyApp({
    required this.playerProgressPersistence,
    required this.sharedPreferences,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AppLifecycleObserver(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (context) {
              var progress = PlayerProgress(playerProgressPersistence);
              progress.getLatestFromStore();
              return progress;
            },
          ),
          Provider<SettingsController>(
            lazy: false,
            create: (context) => SettingsController(
              prefs: sharedPreferences,
            )..loadStateFromPersistence(),
          ),
          ProxyProvider2<SettingsController, ValueNotifier<AppLifecycleState>,
              AudioController>(
            // Ensures that the AudioController is created on startup,
            // and not "only when it's needed", as is default behavior.
            // This way, music starts immediately.
            lazy: false,
            create: (context) => AudioController()..initialize(),
            update: (context, settings, lifecycleNotifier, audio) {
              if (audio == null) throw ArgumentError.notNull();
              audio.attachSettings(settings);
              audio.attachLifecycleNotifier(lifecycleNotifier);
              return audio;
            },
            dispose: (context, audio) => audio.dispose(),
          ),
          Provider(
            create: (context) => Palette(),
          ),
        ],
        child: Builder(builder: (context) {
          final palette = context.watch<Palette>();

          return MaterialApp(
            title: 'Tableturf Mobile',
            theme: ThemeData.from(
              colorScheme: ColorScheme.fromSeed(
                seedColor: palette.darkPen,
                background: palette.backgroundMain,
              ),
              textTheme: TextTheme(
                bodyMedium: TextStyle(
                  color: palette.ink,
                ),
              ),
            ),
            scaffoldMessengerKey: scaffoldMessengerKey,
            home: const MainMenuScreen(key: Key('main menu')),
          );
        }),
      ),
    );
  }
}
