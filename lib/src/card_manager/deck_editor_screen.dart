// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tableturf_mobile/src/components/selection_button.dart';

import '../components/list_select_prompt.dart';
import '../game_internals/card.dart';
import '../game_internals/deck.dart';
import '../components/card_widget.dart';
import '../settings/settings.dart';
import '../style/palette.dart';
import 'card_popup_transition_painter.dart';


class DeckCardWidget extends StatelessWidget {
  final TableturfCardData? card;
  const DeckCardWidget({super.key, required this.card});

  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();
    final card = this.card;
    if (card == null) {
      return LayoutBuilder(
          builder: (context, constraints) {
            final isLandscape = (constraints.maxWidth / constraints.maxHeight) > 1.0;
            final cardAspectRatio = isLandscape
                ? CardWidget.CARD_HEIGHT / CardWidget.CARD_WIDTH
                : CardWidget.CARD_WIDTH / CardWidget.CARD_HEIGHT;
            return AspectRatio(
                aspectRatio: cardAspectRatio,
                child: Container(
                  decoration: BoxDecoration(
                    color: palette.cardBackgroundSelectable,
                    border: Border.all(
                      width: 1.0,
                      color: palette.cardEdge,
                    ),
                  ),
                  child: Center(
                      child: Icon(
                        Icons.add_circle_outline,
                        color: const Color.fromRGBO(255, 255, 255, 0.2),
                        size: constraints.maxHeight * (140 / CardWidget.CARD_HEIGHT),
                      )
                  ),
                )
            );
          }
      );
    }
    return HandCardWidget(card: card, background: palette.cardBackgroundSelectable);
  }
}


class ExactGrid extends StatelessWidget {
  final int height, width;
  final List<Widget> children;
  const ExactGrid({
    super.key,
    required this.height,
    required this.width,
    this.children = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < height * width; i += width)
          Expanded(
            child: Center(
              child: Row(
                children: [
                  for (int j = 0; j < width; j++)
                    Expanded(
                      child: Center(
                        child: i+j >= children.length ? Container() : children[i+j]
                      )
                    )
                ]
              ),
            )
          )
      ]
    );
  }
}


class DeckEditorScreen extends StatefulWidget {
  final TableturfDeck? deck;
  final String? name;
  const DeckEditorScreen(this.deck, {super.key, this.name});

  @override
  State<DeckEditorScreen> createState() => _DeckEditorScreenState();
}

class _DeckEditorScreenState extends State<DeckEditorScreen>
    with SingleTickerProviderStateMixin {
  late final ValueNotifier<bool> _hasEmptyCards = ValueNotifier(true);
  late final ValueNotifier<int> _deckTileCount = ValueNotifier(0);
  late final List<ValueNotifier<TableturfCardIdentifier?>> deckCards;
  late final TextEditingController _textEditingController;
  late final ValueNotifier<String> cardSleeve = ValueNotifier("");

  bool _lockButtons = false;

  @override
  void initState() {
    super.initState();

    late final String name;
    if (widget.deck == null) {
      deckCards = Iterable.generate(
        15,
        (_) => ValueNotifier<TableturfCardIdentifier?>(null)
      ).toList();
      name = widget.name!;
      cardSleeve.value = "default";
    } else {
      deckCards = widget.deck!.cards.map(ValueNotifier<TableturfCardIdentifier?>.new).toList();
      name = widget.deck!.name;
      cardSleeve.value = widget.deck!.cardSleeve;
    }
    _checkHasEmptyCards();
    _computeTileCount();
    for (final card in deckCards) {
      card.addListener(_checkHasEmptyCards);
      card.addListener(_computeTileCount);
    }
    _textEditingController = TextEditingController(text: name);
  }
  
  void _checkHasEmptyCards() {
    _hasEmptyCards.value = deckCards.any((v) => v.value == null);
  }

  void _computeTileCount() {
    final settings = Settings();
    _deckTileCount.value = deckCards
        .map((i) => i.value != null ? settings.identToCard(i.value!) : null)
        .fold(0, (a, c) => a + (c?.count ?? 0));
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  Future<void> _showCardPopup(BuildContext context, ValueNotifier<TableturfCardIdentifier?> cardNotifier) async {
    final ScrollController scrollController = ScrollController();
    const popupBorderWidth = 1.0;
    const cardListPadding = 10.0;
    const interCardPadding = 5.0;

    final TableturfCardIdentifier? selectedCard = await showListSelectPrompt(
      context,
      title: cardNotifier.value == null ? "Select Card" : "Replace Card?",
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
              childAspectRatio: CardWidget.CARD_RATIO
          ),
          itemCount: officialCards.length,
          padding: const EdgeInsets.all(cardListPadding),
          itemBuilder: (_, i) => GestureDetector(
            onTap: () {
              if (deckCards.any((c) => c.value == officialCards[i].ident)) {
                return;
              }
              exitPopup(officialCards[i].ident);
            },
            child: Padding(
              padding: const EdgeInsets.all(0),
              child: HandCardWidget(
                card: officialCards[i],
                overlayColor: deckCards.any((c) => c.value == officialCards[i].ident)
                    ? const Color.fromRGBO(0, 0, 0, 0.4)
                    : Colors.transparent
              ),
            )
          ),
        ),
      ),
    );
    if (selectedCard != null) {
      cardNotifier.value = selectedCard;
    }
    scrollController.dispose();
  }

  Future<void> _showCardSleevePopup(BuildContext context) async {
    final ScrollController scrollController = ScrollController();
    const popupBorderWidth = 1.0;
    const cardListPadding = 10.0;
    const interCardPadding = 5.0;
    const allCardSleeves = [
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
    ];

    final String? selectedCard = await showListSelectPrompt(
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
            childAspectRatio: CardWidget.CARD_RATIO
          ),
          itemCount: allCardSleeves.length,
          padding: const EdgeInsets.all(cardListPadding),
          itemBuilder: (_, i) => GestureDetector(
            onTap: () {
              exitPopup(allCardSleeves[i]);
            },
            child: Padding(
              padding: const EdgeInsets.all(0),
              child: FittedBox(child: Image.asset(
                "assets/images/card_sleeves/sleeve_${allCardSleeves[i]}.png"
              )),
            )
          ),
        ),
      )
    );
    if (selectedCard != null) {
      cardSleeve.value = selectedCard;
    }
    scrollController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<Settings>();
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
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Center(
                    child: RepaintBoundary(
                      child: ValueListenableBuilder<int>(
                        valueListenable: _deckTileCount,
                        builder: (_, count, child) {
                          return Text(count.toString());
                        }
                      ),
                    ),
                  )
                ),
                Expanded(
                  flex: 4,
                  child: TextField(
                    controller: _textEditingController,
                    style: TextStyle(
                      fontFamily: "Splatfont1",
                    ),
                    textAlign: TextAlign.center,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      border: UnderlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.all(0),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(),
                ),
                Expanded(
                  flex: 1,
                  child: GestureDetector(
                    onTap: () {
                      if (_lockButtons) return;
                      _showCardSleevePopup(context);
                    },
                    child: RepaintBoundary(
                      child: ValueListenableBuilder(
                        valueListenable: cardSleeve,
                        builder: (_, String sleeve, child) => FractionallySizedBox(
                          heightFactor: 0.8,
                          widthFactor: 0.8,
                          child: Image.asset("assets/images/card_sleeves/sleeve_${sleeve}.png"),
                        ),
                      ),
                    )
                  )
                ),
              ],
            )
          )
        ),
        Expanded(
          flex: 9,
          child: ExactGrid(
            width: 3,
            height: 5,
            children: [
              for (final cardNotifier in deckCards)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GestureDetector(
                    onTap: () {
                      if (_lockButtons) return;
                      _showCardPopup(context, cardNotifier);
                    },
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        const duration = Duration(milliseconds: 200);
                        return ValueListenableBuilder(
                          valueListenable: cardNotifier,
                          builder: (_, TableturfCardIdentifier? cardIdent, child) {
                            final card = cardIdent != null
                                ? settings.identToCard(cardIdent)
                                : null;
                            final textStyle = DefaultTextStyle.of(context).style;
                            final cardWidget = SizedBox(
                              height: constraints.maxHeight,
                              width: constraints.maxWidth,
                              child: Center(
                                child: DeckCardWidget(card: card),
                              ),
                            );
                            return LongPressDraggable(
                              data: cardNotifier,
                              maxSimultaneousDrags: 1,
                              delay: const Duration(milliseconds: 250),
                              child: DragTarget<ValueNotifier<TableturfCardIdentifier?>>(
                                builder: (_, accepted, rejected) {
                                  return AnimatedOpacity(
                                    opacity: accepted.length > 0 ? 0.8 : 1.0,
                                    duration: duration,
                                    //curve: curve,
                                    child: AnimatedScale(
                                      scale: accepted.length > 0 ? 0.8 : 1.0,
                                      duration: duration,
                                      curve: Curves.ease,
                                      child: cardWidget
                                    ),
                                  );
                                },
                                onWillAccept: (newCard) => !identical(cardNotifier, newCard),
                                onAccept: (newCard) {
                                  final temp = newCard.value;
                                  newCard.value = cardNotifier.value;
                                  cardNotifier.value = temp;
                                },
                              ),
                              feedback: DefaultTextStyle(
                                style: textStyle,
                                child: Opacity(
                                  opacity: 0.9,
                                  child: cardWidget,
                                ),
                              ),
                              childWhenDragging: Container(),
                            );
                          }
                        );
                      }
                    )
                  ),
                )
            ],
          )
        ),
        Expanded(
          flex: 1,
          child: Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide())
            ),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: ValueListenableBuilder(
                        valueListenable: _hasEmptyCards,
                        child: SelectionButton(
                          child: Text(
                            "Save and exit",
                            style: TextStyle(fontSize: 16),
                          ),
                          designRatio: 0.5,
                          onPressStart: () async {
                            if (_lockButtons || _hasEmptyCards.value) {
                              return false;
                            }
                            _lockButtons = true;
                            return true;
                          },
                          onPressEnd: () async {
                            if (widget.deck == null) {
                              settings.createDeck(
                                cards: deckCards.map((v) => v.value!).toList(),
                                name: _textEditingController.text,
                                cardSleeve: cardSleeve.value
                              );
                            } else {
                              settings.updateDeck(
                                deckID: widget.deck!.deckID,
                                cards: deckCards.map((v) => v.value!).toList(),
                                name: _textEditingController.text,
                                cardSleeve: cardSleeve.value
                              );
                            }
                            Navigator.of(context).pop(true);
                            return Future<void>.delayed(const Duration(milliseconds: 100));
                          },
                        ),
                        builder: (_, bool hasEmptyCards, child) {
                          if (!hasEmptyCards) {
                            return child!;
                          }
                          return ColorFiltered(
                            colorFilter: ColorFilter.mode(
                              Colors.black.withOpacity(0.5),
                              BlendMode.srcATop,
                            ),
                            child: child,
                          );
                        }
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: SelectionButton(
                        child: Text(
                          "Exit without saving",
                          style: TextStyle(fontSize: 16),
                        ),
                        designRatio: 0.5,
                        onPressStart: () async {
                          if (_lockButtons) return false;
                          _lockButtons = true;
                          return true;
                        },
                        onPressEnd: () async {
                          Navigator.of(context).pop(false);
                          return Future<void>.delayed(const Duration(milliseconds: 100));
                        },
                      ),
                    ),
                  ),
                ]
            ),
          ),
        )
      ]
    );
    return Scaffold(
      backgroundColor: palette.backgroundDeckEditor,
      body: DefaultTextStyle(
        style: TextStyle(
          fontFamily: "Splatfont2",
          color: Colors.black,
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
    );
  }
}
