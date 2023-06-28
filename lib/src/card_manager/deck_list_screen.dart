import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tableturf_mobile/src/card_manager/deck_editor_screen.dart';
import 'package:tableturf_mobile/src/game_internals/opponentAI.dart';
import 'package:tableturf_mobile/src/game_internals/player.dart';
import 'package:tableturf_mobile/src/level_selection/opponents.dart';
import 'package:tableturf_mobile/src/play_session/components/card_selection.dart';
import 'package:tableturf_mobile/src/play_session/components/selection_button.dart';

import '../audio/audio_controller.dart';
import '../audio/sounds.dart';
import '../game_internals/card.dart';
import '../game_internals/tile.dart';
import '../play_session/build_game_session_page.dart';
import '../play_session/components/card_widget.dart';
import '../player_progress/player_progress.dart';
import '../style/palette.dart';
import '../style/responsive_screen.dart';

class DeckListScreen extends StatefulWidget {
  const DeckListScreen({Key? key}) : super(key: key);

  @override
  State<DeckListScreen> createState() => _DeckListScreenState();
}

class _DeckListScreenState extends State<DeckListScreen> {
  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();
    final mediaQuery = MediaQuery.of(context);
    final exampleDecks = [
      {
        "name": "My Deck",
        "sleeve": "default",
      },
      {
        "name": "My better deck",
        "sleeve": "cool",
      },
      {
        "name": "My name is Dis",
        "sleeve": "supercool",
      },
      {
        "name": "Can dis deck fit in yo mouth lmao",
        "sleeve": "ultracool",
      },
    ];
    final screen = Column(
      children: [
        Expanded(
          flex: 1,
          child: Center(
            child: Text("Edit Deck", style: TextStyle(
              fontFamily: "Splatfont1",
              color: Colors.black
            ))
          )
        ),
        Expanded(
          flex: 9,
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all()
            ),
            child: ListView(
              padding: const EdgeInsets.all(10),
              children: [
                for (final deck in exampleDecks)
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    margin: const EdgeInsets.all(5),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) {
                            return DeckEditorScreen(
                              name: deck["name"]!
                            );
                          })
                        );
                      },
                      child: AspectRatio(
                        aspectRatio: 4.3,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(9),
                              child: FractionallySizedBox(
                                widthFactor: (CardWidget.CARD_WIDTH + 40) / CardWidget.CARD_WIDTH,
                                child: Image.asset(
                                  "assets/images/card_sleeves/sleeve_${deck["sleeve"]}.png",
                                  color: Color.fromRGBO(32, 32, 32, 0.4),
                                  colorBlendMode: BlendMode.srcATop,
                                  fit: BoxFit.fitWidth,
                                ),
                              ),
                            ),
                            Center(child: Text(deck["name"]!))
                          ],
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) {
                          return DeckEditorScreen(
                            name: "Deck ${exampleDecks.length + 1}"
                          );
                        })
                      );
                    },
                    child: AspectRatio(
                      aspectRatio: 4.3,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(),
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.black54,
                        ),
                        child: Center(child: Text("Create New")),
                      ),
                    ),
                  ),
                )
              ]
            )
          )
        )
      ]
    );
    return WillPopScope(
      onWillPop: () async => true,
      child: Scaffold(
          backgroundColor: palette.backgroundDeckList,
          body: DefaultTextStyle(
            style: TextStyle(
                fontFamily: "Splatfont2",
                color: Colors.white,
                fontSize: 18,
                letterSpacing: 0.6,
                shadows: [
                  Shadow(
                    color: const Color.fromRGBO(256, 256, 256, 0.4),
                    offset: Offset(1, 1),
                  )
                ]
            ),
            child: Padding(
              padding: mediaQuery.padding,
              child: Center(
                child: screen
              ),
            ),
          )
      ),
    );
  }
}
