// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Uncomment the following lines when enabling Firebase Crashlytics
// import 'dart:io';
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tableturf_mobile/src/game_internals/card.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:tableturf_mobile/src/game_internals/map.dart';
import 'package:tableturf_mobile/src/level_selection/opponents.dart';
import 'package:tableturf_mobile/src/style/shaders.dart';

import 'src/app_lifecycle/app_lifecycle.dart';
import 'src/audio/audio_controller.dart';
import 'src/main_menu/main_menu_screen.dart';
import 'src/player_progress/player_progress.dart';
import 'src/settings/settings.dart';
import 'src/style/constants.dart';
import 'src/style/snack_bar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print("loading assets");
  await Future.wait([
    loadMaps(),
    loadCards(),
    loadOpponents(),
    Shaders.loadPrograms(),
  ]);
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
  /*
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      systemNavigationBarContrastEnforced: false,
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  */

  final SharedPreferences prefs = await SharedPreferences.getInstance();
  /*
  if (prefs.containsKey("tableturf-deck_nextID")) {
    print("Initialising deck data");
    await prefs.remove("tableturf-deck_nextID");
    await prefs.remove("tableturf-deck_list");
    await prefs.remove("tableturf-deck_deck-0");
  }
  */

  runApp(
    MyApp(
      sharedPreferences: prefs,
    ),
  );
}

Logger _log = Logger('main.dart');

class MyApp extends StatelessWidget {
  final SharedPreferences sharedPreferences;

  const MyApp({
    required this.sharedPreferences,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AppLifecycleObserver(
      child: MultiProvider(
        providers: [
          Provider<PlayerProgress>(
            lazy: false,
            create: (context) => PlayerProgress()
              ..loadStateFromPersistence(sharedPreferences),
          ),
          Provider<Settings>(
            lazy: false,
            create: (context) => Settings()
              ..loadStateFromPersistence(sharedPreferences),
          ),
          ProxyProvider2<Settings, ValueNotifier<AppLifecycleState>,
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
            //dispose: (context, audio) => audio.dispose(),
          ),
        ],
        child: Builder(builder: (context) {
          return MaterialApp(
            title: 'Tableturf Mobile',
            theme: ThemeData.from(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Palette.darkPen,
                background: Palette.backgroundMain,
              ),
              textTheme: TextTheme(
                bodyMedium: TextStyle(
                  color: Palette.ink,
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
