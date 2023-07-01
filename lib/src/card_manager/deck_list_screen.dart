import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tableturf_mobile/src/card_manager/deck_editor_screen.dart';
import 'package:tableturf_mobile/src/game_internals/opponentAI.dart';
import 'package:tableturf_mobile/src/game_internals/player.dart';
import 'package:tableturf_mobile/src/level_selection/opponents.dart';
import 'package:tableturf_mobile/src/play_session/components/card_selection.dart';
import 'package:tableturf_mobile/src/play_session/components/selection_button.dart';

import '../audio/audio_controller.dart';
import '../audio/sounds.dart';
import '../game_internals/card.dart';
import '../game_internals/deck.dart';
import '../game_internals/tile.dart';
import '../play_session/build_game_session_page.dart';
import '../play_session/components/card_widget.dart';
import '../player_progress/player_progress.dart';
import '../settings/settings.dart';
import '../style/palette.dart';
import '../style/responsive_screen.dart';

class DeckListScreen extends StatefulWidget {
  const DeckListScreen({Key? key}) : super(key: key);

  @override
  State<DeckListScreen> createState() => _DeckListScreenState();
}

class _DeckListScreenState extends State<DeckListScreen> {
  bool _lockButtons = false;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final decks = settings.decks;
    final palette = context.watch<Palette>();
    final mediaQuery = MediaQuery.of(context);
    final screen = Column(
      children: [
        Expanded(
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide())
              ),
              child: Center(
                child: Text("Edit Deck", style: TextStyle(
                  fontFamily: "Splatfont1",
                  color: Colors.black
                ))
              ),
            )
        ),
        Expanded(
          flex: 9,
          child: ListView(
            padding: const EdgeInsets.all(10),
            children: [
              for (final deckNotifier in decks)
                AspectRatio(
                  aspectRatio: 3.95,
                  child: GestureDetector(
                    onTap: () async {
                      if (_lockButtons) return;
                      _lockButtons = true;
                      final bool changesMade = await Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) {
                            return DeckEditorScreen(deckNotifier.value);
                          })
                      );
                      if (changesMade) {
                        setState(() {});
                      }
                      _lockButtons = false;
                    },
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return ValueListenableBuilder(
                          valueListenable: deckNotifier,
                          builder: (context, TableturfDeck deck, child) {
                            final textStyle = DefaultTextStyle.of(context).style;
                            const duration = Duration(milliseconds: 200);
                            final deckWidget = SizedBox(
                              height: constraints.maxHeight,
                              width: constraints.maxWidth,
                              child: Center(
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  margin: const EdgeInsets.all(5),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(9),
                                        child: FractionallySizedBox(
                                          widthFactor: (CardWidget.CARD_WIDTH + 40) / CardWidget.CARD_WIDTH,
                                          child: Image.asset(
                                            "assets/images/card_sleeves/sleeve_${deck.cardSleeve}.png",
                                            color: Color.fromRGBO(32, 32, 32, 0.4),
                                            colorBlendMode: BlendMode.srcATop,
                                            fit: BoxFit.fitWidth,
                                          ),
                                        ),
                                      ),
                                      Center(child: Text(deck.name))
                                    ],
                                  ),
                                ),
                              ),
                            );

                            return LongPressDraggable<ValueNotifier<TableturfDeck>>(
                              data: deckNotifier,
                              maxSimultaneousDrags: 1,
                              delay: const Duration(milliseconds: 250),
                              feedback: DefaultTextStyle(
                                style: textStyle,
                                child: Opacity(
                                  opacity: 0.9,
                                  child: deckWidget,
                                ),
                              ),
                              childWhenDragging: Container(),
                              child: DragTarget<ValueNotifier<TableturfDeck>>(
                                builder: (_, accepted, rejected) {
                                  return AnimatedOpacity(
                                    opacity: accepted.length > 0 ? 0.8 : 1.0,
                                    duration: duration,
                                    //curve: curve,
                                    child: AnimatedScale(
                                        scale: accepted.length > 0 ? 0.8 : 1.0,
                                        duration: duration,
                                        curve: Curves.ease,
                                        child: deckWidget
                                    ),
                                  );
                                },
                                onWillAccept: (newDeck) => !identical(deckNotifier, newDeck),
                                onAccept: (newDeck) {
                                  settings.swapDecks(deckNotifier.value.deckID, newDeck.value.deckID);
                                },
                              )
                            );
                          }
                        );
                      }
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(5),
                child: GestureDetector(
                  onTap: () async {
                    if (_lockButtons) return;
                    _lockButtons = true;
                    final bool changesMade = await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) {
                        return DeckEditorScreen(null,
                          name: "Deck ${decks.length + 1}"
                        );
                      })
                    );
                    if (changesMade) {
                      setState(() {});
                    }
                    _lockButtons = false;
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
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide())
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    child: SelectionButton(
                      child: Text("Back"),
                      designRatio: 0.5,
                      onPressStart: () async {
                        if (_lockButtons) return false;
                        _lockButtons = true;
                        return true;
                      },
                      onPressEnd: () async {
                        Navigator.of(context).pop();
                        return Future<void>.delayed(const Duration(milliseconds: 100));
                      },
                    ),
                  ),
                )
              ]
            )
          ),
        ),
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