import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tableturf_mobile/src/card_manager/deck_editor_screen.dart';
import 'package:tableturf_mobile/src/components/selection_button.dart';

import '../game_internals/deck.dart';
import '../components/deck_thumbnail.dart';
import '../settings/settings.dart';
import '../style/palette.dart';

enum DeckPopupActions {
  delete,
}


class DeckListScreen extends StatefulWidget {
  const DeckListScreen({super.key});

  @override
  State<DeckListScreen> createState() => _DeckListScreenState();
}

class _DeckListScreenState extends State<DeckListScreen> {
  bool _lockButtons = false;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<Settings>();
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
                  aspectRatio: DeckThumbnail.THUMBNAIL_RATIO,
                  child: GestureDetector(
                    onTap: () async {
                      if (_lockButtons) return;
                      _lockButtons = true;
                      final bool? changesMade = await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) {
                          return DeckEditorScreen(deckNotifier.value);
                        })
                      );
                      if (changesMade == true) {
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

                            return Draggable<ValueNotifier<TableturfDeck>>(
                              data: deckNotifier,
                              maxSimultaneousDrags: 1,
                              feedback: DefaultTextStyle(
                                style: textStyle,
                                child: Opacity(
                                  opacity: 0.9,
                                  child: ConstrainedBox(
                                    constraints: constraints,
                                    child: DeckThumbnail(deck: deck),
                                  )
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
                                        child: Stack(
                                          children: [
                                            DeckThumbnail(deck: deck),
                                            Align(
                                              alignment: Alignment.topRight,
                                              child: PopupMenuButton<DeckPopupActions>(
                                                icon: Icon(
                                                  Icons.more_vert,
                                                  color: Colors.white,
                                                ),
                                                onSelected: (val) {
                                                  switch (val) {
                                                    case DeckPopupActions.delete:
                                                      settings.deleteDeck(deck.deckID);
                                                      setState(() {});
                                                      break;
                                                  }
                                                },
                                                itemBuilder: (context) => [
                                                  PopupMenuItem(
                                                    child: Text("Delete"),
                                                    value: DeckPopupActions.delete,
                                                  ),
                                                ],
                                              )
                                            )
                                          ],
                                        )
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
                    final bool? changesMade = await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) {
                        return DeckEditorScreen(null,
                          name: "Deck ${decks.length + 1}"
                        );
                      })
                    );
                    if (changesMade == true) {
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
