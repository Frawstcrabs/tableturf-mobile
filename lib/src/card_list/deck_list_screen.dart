import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tableturf_mobile/src/card_list/deck_editor_screen.dart';
import 'package:tableturf_mobile/src/components/selection_button.dart';
import 'package:tableturf_mobile/src/player_progress/player_progress.dart';
import 'package:tableturf_mobile/src/settings/custom_name_dialog.dart';

import '../components/card_widget.dart';
import '../components/list_select_prompt.dart';
import '../game_internals/deck.dart';
import '../components/deck_thumbnail.dart';
import '../settings/settings.dart';
import '../style/constants.dart';

enum DeckPopupActions {
  delete,
  duplicate,
  changeName,
  changeSleeve,
}


class DeckListScreen extends StatefulWidget {
  const DeckListScreen({super.key});

  @override
  State<DeckListScreen> createState() => _DeckListScreenState();
}

class _DeckListScreenState extends State<DeckListScreen> {
  bool _lockButtons = false;

  Future<String?> _showCardSleevePopup() async {
    final ScrollController scrollController = ScrollController();
    final playerProgress = PlayerProgress();
    const popupBorderWidth = 1.0;
    const cardListPadding = 10.0;
    const interCardPadding = 5.0;
    final cardSleeves = [
      "default",
      "cool",
      "supercool",
      "ultracool",
      "crustysean",
      "sheldon",
      "gnarlyeddy",
      "jellafleur",
      "mrcoco",
      "harmony",
      "judd",
      "liljudd",
      "murch",
      "shiver",
      "frye",
      "bigman",
      "staff",
      "cuttlefish",
      "callie",
      "marie",
      "shelly",
      "annie",
      "jelonzo",
      "fredcrumbs",
      "spyke",
    ].where((element) => playerProgress.unlockedCardSleeves.contains(element)).toList();

    final String? selectedSleeve = await showListSelectPrompt(
      context,
      title: "Select Card Sleeve",
      builder: (context, exitPopup) => RawScrollbar(
        controller: scrollController,
        thickness: popupBorderWidth + (cardListPadding / 2),
        padding: const EdgeInsets.fromLTRB(
          (popupBorderWidth + interCardPadding) / 2,
          popupBorderWidth + cardListPadding + interCardPadding,
          (popupBorderWidth + interCardPadding) / 2,
          popupBorderWidth + cardListPadding + interCardPadding,
        ),
        thumbColor: const Color.fromRGBO(0, 0, 0, 0.4),
        radius: Radius.circular(6),
        child: GridView.builder(
          controller: scrollController,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              mainAxisSpacing: interCardPadding,
              crossAxisSpacing: interCardPadding,
              crossAxisCount: 3,
              childAspectRatio: CardWidget.CARD_RATIO,
          ),
          itemCount: cardSleeves.length,
          padding: const EdgeInsets.all(cardListPadding),
          itemBuilder: (_, i) => GestureDetector(
              onTap: () {
                exitPopup(cardSleeves[i]);
              },
              child: Image.asset(
                  "assets/images/card_sleeves/sleeve_${cardSleeves[i]}.png"
              ),
          ),
        ),
      ),
    );
    scrollController.dispose();
    return selectedSleeve;
  }

  @override
  Widget build(BuildContext context) {
    final playerProgress = PlayerProgress();
    final decks = playerProgress.decks;
    final mediaQuery = MediaQuery.of(context);
    final screen = Column(
      children: [
        Expanded(
            flex: 1,
            child: Center(
              child: Text("Deck List", style: TextStyle(
                fontFamily: "Splatfont1",
                color: Colors.black
              ))
            )
        ),
        divider,
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
                                                onSelected: (val) async {
                                                  switch (val) {
                                                    case DeckPopupActions.delete:
                                                      playerProgress.deleteDeck(deck.deckID);
                                                      setState(() {});
                                                      break;
                                                    case DeckPopupActions.duplicate:
                                                      playerProgress.duplicateDeck(deck.deckID);
                                                      setState(() {});
                                                      break;
                                                    case DeckPopupActions.changeName:
                                                      final newName = await showCustomNameDialog(
                                                        context,
                                                        deck.name,
                                                      );
                                                      playerProgress.setDeckName(deck.deckID, newName);
                                                      setState(() {});
                                                      break;
                                                    case DeckPopupActions.changeSleeve:
                                                      final newSleeve = await _showCardSleevePopup();
                                                      if (newSleeve != null) {
                                                        playerProgress.setDeckSleeve(deck.deckID, newSleeve);
                                                        setState(() {});
                                                      }
                                                      break;
                                                  }
                                                },
                                                itemBuilder: (context) => [
                                                  PopupMenuItem(
                                                    child: Text("Rename"),
                                                    value: DeckPopupActions.changeName,
                                                  ),
                                                  PopupMenuItem(
                                                    child: Text("Change Sleeve"),
                                                    value: DeckPopupActions.changeSleeve,
                                                  ),
                                                  PopupMenuItem(
                                                    child: Text("Duplicate"),
                                                    value: DeckPopupActions.duplicate,
                                                  ),
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
                                  playerProgress.swapDecks(deckNotifier.value.deckID, newDeck.value.deckID);
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
        divider,
        Expanded(
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
          ),
        ),
      ]
    );
    return WillPopScope(
      onWillPop: () async => true,
      child: Scaffold(
        backgroundColor: Palette.backgroundDeckList,
        body: DefaultTextStyle(
          style: TextStyle(
            fontFamily: "Splatfont2",
            color: Colors.white,
            fontSize: 18,
            letterSpacing: 0.6,
          ),
          child: Padding(
            padding: mediaQuery.padding,
            child: screen,
          ),
        ),
      ),
    );
  }
}
