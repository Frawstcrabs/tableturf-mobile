// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:tableturf_mobile/src/components/multi_choice_prompt.dart';
import 'package:tableturf_mobile/src/components/selection_button.dart';
import 'package:tableturf_mobile/src/player_progress/player_progress.dart';

import '../components/exact_grid.dart';
import '../components/list_select_prompt.dart';
import '../game_internals/card.dart';
import '../game_internals/deck.dart';
import '../components/card_widget.dart';
import '../style/constants.dart';
import 'card_list_screen.dart';


class DeckCardWidget extends StatelessWidget {
  final TableturfCardData? card;
  const DeckCardWidget({super.key, required this.card});

  Widget build(BuildContext context) {
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
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Palette.cardBackgroundUnselectable,
                border: Border.all(
                  width: 1.0,
                  color: Palette.cardEdge,
                ),
              ),
            ),
          );
        },
      );
    }
    return HandCardWidget(card: card, background: Palette.cardBackgroundSelectable);
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
    with TickerProviderStateMixin {
  late final DeckCardsModel deckCards;
  late final TextEditingController _textEditingController;
  late final TabController tabController;
  late final ValueNotifier<CardGridViewSortMode> sortMode = ValueNotifier(CardGridViewSortMode.number);
  late final ValueNotifier<String> cardSleeve = ValueNotifier("");

  late final AnimationController expandController;
  late final Animation<double> entryHeight;
  final ValueNotifier<bool> offstageNotifier = ValueNotifier(false);
  final SnapshotController snapshotController = SnapshotController(
    allowSnapshotting: true,
  );

  Future<int>? exitPopup = null;
  Future<void>? changeSleevePopup = null;
  bool _lockButtons = false;

  @override
  void initState() {
    super.initState();

    late final String name;
    if (widget.deck == null) {
      deckCards = DeckCardsModel();
      name = widget.name!;
      cardSleeve.value = "default";
    } else {
      deckCards = DeckCardsModel([...widget.deck!.cards]);
      name = widget.deck!.name;
      cardSleeve.value = widget.deck!.cardSleeve;
    }

    _textEditingController = TextEditingController(text: name);
    tabController = TabController(
      length: 2,
      vsync: this,
    );

    expandController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    entryHeight = expandController.drive(
      Tween(
        begin: 0.0,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeOutCubic)),
    );
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerProgress = PlayerProgress();
    final mediaQuery = MediaQuery.of(context);
    final screen = Column(
      children: [
        Expanded(
          flex: 2,
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: Center(
                  child: FractionallySizedBox(
                    heightFactor: 0.6,
                    child: FittedBox(
                      child: RepaintBoundary(
                        child: Builder(builder: (context) {
                          final cards = DeckCards.of(context).cards;
                          final amount = cards.fold(0, (e, c) {
                            return e + (c == null ? 0 : 1);
                          });
                          final textStyle = DefaultTextStyle.of(context).style;
                          const fontSize = 16.0;
                          return RichText(
                            text: TextSpan(children: [
                              TextSpan(
                                text: amount.toString(),
                                style: textStyle.copyWith(
                                  fontSize: fontSize,
                                ),
                              ),
                              TextSpan(
                                text: "/15",
                                style: textStyle.copyWith(
                                  fontSize: fontSize * 0.7,
                                ),
                              ),
                            ]),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: RepaintBoundary(
                  child: DeckCount(),
                ),
              ),
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                    "Edit Deck",
                    style: TextStyle(
                      fontFamily: "Splatfont1",
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: ValueListenableBuilder(
                    valueListenable: sortMode,
                    builder: (_, currentSortMode, __) => GestureDetector(
                      onTap: () {
                        sortMode.value = switch (currentSortMode) {
                          CardGridViewSortMode.number => CardGridViewSortMode.size,
                          CardGridViewSortMode.size => CardGridViewSortMode.number,
                        };
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(5),
                        child: Text(
                          "Sort: ${currentSortMode.name}",
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          )
        ),
        Expanded(
          flex: 18,
          child: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    flex: 1,
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        color: Color.fromRGBO(0, 0, 0, 0.2),
                      ),
                      child: TabBar(
                        controller: tabController,
                        tabs: [
                          for (final name in ["Official", "Custom"])
                            Center(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontFamily: "Splatfont2",
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  divider,
                  Expanded(
                    flex: 17,
                    child: ValueListenableBuilder(
                      valueListenable: sortMode,
                      builder: (_, currentSortMode, __) => TabBarView(
                        controller: tabController,
                        children: [
                          CardGridView(
                            cardList: officialCards
                                .where((c) => playerProgress.unlockedCards.contains(c.ident))
                                .toList(),
                            sortMode: currentSortMode,
                          ),
                          CardGridView(
                            cardList: [],
                            sortMode: currentSortMode,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: RepaintBoundary(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return AnimatedBuilder(
                        animation: entryHeight,
                        child: ValueListenableBuilder(
                          valueListenable: offstageNotifier,
                          child: DeckReorderView(),
                          builder: (ctx, bool isOffstage, child) {
                            return Offstage(
                              offstage: isOffstage,
                              child: OverflowBox(
                                maxWidth: constraints.maxWidth,
                                maxHeight: constraints.maxHeight,
                                alignment: Alignment.topCenter,
                                child: SnapshotWidget(
                                  controller: snapshotController,
                                  child: child,
                                ),
                              ),
                            );
                          },
                        ),
                        builder: (ctx, child) {
                          return ClipRect(
                            child: FractionallySizedBox(
                              heightFactor: entryHeight.value,
                              child: child,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        divider,
        Expanded(
          flex: 2,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: SelectionButton(
                    child: Text(
                      "Test",
                      style: TextStyle(fontSize: 16),
                    ),
                    designRatio: 0.5,
                    onPressStart: () async {
                      if (_lockButtons) {
                        return false;
                      }
                      print("testing screen goes here");
                      return true;
                    },
                    onPressEnd: () async {},
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: DeckReorderButton(
                    controller: expandController,
                    onTap: () async {
                      switch (expandController.status) {
                        case AnimationStatus.reverse:
                        case AnimationStatus.dismissed:
                          snapshotController.clear();
                          await expandController.forward();
                          snapshotController.allowSnapshotting = false;
                        case AnimationStatus.forward:
                        case AnimationStatus.completed:
                          snapshotController.allowSnapshotting = true;
                          await expandController.reverse();
                      }
                    },
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: SelectionButton(
                    child: Text(
                      "Exit",
                      style: TextStyle(fontSize: 16),
                    ),
                    designRatio: 0.5,
                    onPressStart: () async {
                      if (_lockButtons) {
                        return false;
                      }
                      _lockButtons = true;
                      exitPopup = showMultiChoicePrompt(
                        context,
                        title: "Save changes?",
                        options: ["Back to Edit", "Save!", "Don't Save"],
                        defaultResult: 0,
                      );
                      return true;
                    },
                    onPressEnd: () async {
                      final choice = await exitPopup!;
                      exitPopup = null;
                      switch (choice) {
                        case 0:
                          _lockButtons = false;
                          return;
                        case 1:
                          if (widget.deck == null) {
                            playerProgress.createDeck(
                              cards: [...deckCards.cards],
                              name: _textEditingController.text,
                              cardSleeve: cardSleeve.value,
                            );
                          } else {
                            playerProgress.updateDeck(
                              deckID: widget.deck!.deckID,
                              cards: [...deckCards.cards],
                              name: _textEditingController.text,
                              cardSleeve: cardSleeve.value,
                            );
                          }
                          Navigator.of(context).pop(true);
                          return Future<void>.delayed(const Duration(milliseconds: 100));
                        case 2:
                          Navigator.of(context).pop(false);
                          return Future<void>.delayed(const Duration(milliseconds: 100));
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
    return Scaffold(
      backgroundColor: Palette.backgroundDeckEditor,
      body: DefaultTextStyle(
        style: TextStyle(
          fontFamily: "Splatfont2",
          color: Colors.black,
          fontSize: 18,
          letterSpacing: 0.6,
          shadows: []
        ),
        child: Padding(
          padding: mediaQuery.padding,
          child: DeckCards(
            model: deckCards,
            child: screen,
          ),
        ),
      )
    );
  }
}

class DeckCount extends StatelessWidget {
  const DeckCount({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final playerProgress = PlayerProgress();
    final cards = DeckCards.of(context).cards;
    final amount = cards.fold(0, (e, c) {
      if (c == null) return e;
      return e + playerProgress.identToCard(c).count;
    });
    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: 16.0,
      height: 1.5,
    );
    return Center(
      child: FractionallySizedBox(
        heightFactor: 0.6,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: FractionalTranslation(
                translation: Offset(0, -0.025),
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: Transform.rotate(
                    angle: 0.15,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.grey[800]
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Column(
              children: [
                Expanded(
                  flex: 5,
                  child: FittedBox(
                    child: Text(
                      "Total",
                      style: textStyle,
                    ),
                  ),
                ),
                Expanded(
                  flex: 8,
                  child: FittedBox(
                    child: Text(
                      amount.toString(),
                      style: textStyle
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class DeckReorderView extends StatelessWidget {
  const DeckReorderView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final playerProgress = PlayerProgress();
    final model = DeckCards.of(context);

    final screen = ExactGrid(
      width: 3,
      height: 5,
      children: [
        for (final ident in model.cards)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                const duration = Duration(milliseconds: 200);
                final card = ident != null
                    ? playerProgress.identToCard(ident)
                    : null;
                final textStyle = DefaultTextStyle.of(context).style;
                final cardWidget = SizedBox(
                  height: constraints.maxHeight,
                  width: constraints.maxWidth,
                  child: Center(
                    child: DeckCardWidget(card: card),
                  ),
                );
                if (ident == null) {
                  return cardWidget;
                }
                return LongPressDraggable(
                  data: ident,
                  maxSimultaneousDrags: 1,
                  delay: const Duration(milliseconds: 250),
                  child: DragTarget<TableturfCardIdentifier>(
                    builder: (_, accepted, rejected) {
                      return AnimatedOpacity(
                        opacity: accepted.length > 0 ? 0.8 : 1.0,
                        duration: duration,
                        //curve: curve,
                        child: AnimatedScale(
                          scale: accepted.length > 0 ? 0.8 : 1.0,
                          duration: duration,
                          curve: Curves.ease,
                          child: cardWidget,
                        ),
                      );
                    },
                    onWillAccept: (newIdent) => ident != newIdent,
                    onAccept: (newIdent) {
                      model.swapCards(ident, newIdent);
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
              },
            ),
          ),
      ],
    );
    return Column(
      children: [
        divider,
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Color.alphaBlend(
                Color.alphaBlend(
                  Colors.black.withOpacity(0.3),
                  Colors.orange[800]!.withOpacity(0.7),
                ).withOpacity(0.3),
                Palette.backgroundDeckEditor,
              ),
            ),
            child: screen,
          ),
        ),
      ],
    );
  }
}


class CardGridView extends StatefulWidget {
  final List<TableturfCardData> cardList;
  final CardGridViewSortMode sortMode;
  const CardGridView({
    super.key,
    required this.cardList,
    required this.sortMode,
  });

  @override
  State<CardGridView> createState() => _CardGridViewState();
}

class _CardGridViewState extends State<CardGridView> {
  late final Map<CardGridViewSortMode, List<TableturfCardData>> cardLists;

  @override
  void initState() {
    super.initState();
    cardLists = {
      CardGridViewSortMode.number: widget.cardList,
      CardGridViewSortMode.size: widget.cardList.sortedBy<num>((c) => c.count),
    };
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final displayCardList = cardLists[widget.sortMode]!;
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        crossAxisCount: mediaQuery.orientation == Orientation.portrait ? 3 : 7,
        childAspectRatio: CardWidget.CARD_RATIO,
      ),
      padding: const EdgeInsets.all(10),
      itemCount: displayCardList.length,
      itemBuilder: (context, index) {
        final card = displayCardList[index];
        return CardListItem(card: card);
      },
    );
  }
}

class CardListItem extends StatelessWidget {
  final TableturfCardData card;
  const CardListItem({
    super.key,
    required this.card,
  });

  @override
  Widget build(BuildContext context) {
    var deckCards = DeckCards.of(context, card.ident);
    final isSelected = deckCards.containsCard(card.ident);
    return GestureDetector(
      onTap: () {
        if (isSelected) {
          deckCards.removeCard(card.ident);
        } else {
          deckCards.addCard(card.ident);
        }
      },
      child: HandCardWidget(
        card: card,
        background: isSelected
            ? Palette.cardBackgroundSelected
            : Palette.cardBackgroundSelectable,
      ),
    );
  }
}


class DeckCardsModel {
  final List<TableturfCardIdentifier?> _cards;
  ValueNotifier<Set<TableturfCardIdentifier>> _modifiedCards = ValueNotifier(Set());

  DeckCardsModel([List<TableturfCardIdentifier?>? cards]):
        _cards = cards ?? List.generate(15, (_) => null);

  List<TableturfCardIdentifier?> get cards => _cards;
  bool containsCard(TableturfCardIdentifier ident) {
    return _cards.any((c) => c == ident);
  }

  void addCard(TableturfCardIdentifier ident) {
    final index = _cards.indexWhere((element) => element == null);
    if (index == -1) {
      return;
    }
    _cards[index] = ident;
    _modifiedCards.value = Set.of([ident]);
  }

  void removeCard(TableturfCardIdentifier ident) {
    final index = _cards.indexWhere((element) => element == ident);
    if (index == -1) {
      return;
    }
    _cards[index] = null;
    _modifiedCards.value = Set.of([ident]);
  }

  void swapCards(TableturfCardIdentifier card1, TableturfCardIdentifier card2) {
    final index1 = _cards.indexOf(card1);
    final index2 = _cards.indexOf(card2);
    if (index1 == -1 || index2 == -1) {
      return;
    }
    _cards.swap(index1, index2);
    _modifiedCards.value = Set.of([card1, card2]);
  }
}

class DeckCards extends InheritedModel<TableturfCardIdentifier> {
  final DeckCardsModel model;
  DeckCards({
    required super.child,
    required this.model,
  });

  @override
  bool updateShouldNotify(DeckCards oldWidget) => true;

  @override
  bool updateShouldNotifyDependent(DeckCards oldWidget, dependencies) {
    final modifiedCards = oldWidget.model._modifiedCards.value;
    return modifiedCards.any(dependencies.contains);
  }

  static DeckCardsModel of(BuildContext context, [TableturfCardIdentifier? aspect]) {
    return InheritedModel.inheritFrom<DeckCards>(context, aspect: aspect)!.model;
  }

  @override
  DeckCardsElement createElement() => DeckCardsElement(this);
}

class DeckCardsElement extends InheritedModelElement<TableturfCardIdentifier> {
  DeckCardsElement(DeckCards widget) : super(widget) {
    widget.model._modifiedCards.addListener(_handleUpdate);
  }

  bool _dirty = false;

  @override
  void update(DeckCards newWidget) {
    final oldNotifier = (widget as DeckCards).model._modifiedCards;
    final newNotifier = newWidget.model._modifiedCards;
    if (oldNotifier != newNotifier) {
      oldNotifier.removeListener(_handleUpdate);
      newNotifier.addListener(_handleUpdate);
    }
    super.update(newWidget);
  }

  @override
  Widget build() {
    if (_dirty) {
      notifyClients(widget as DeckCards);
    }
    return super.build();
  }

  void _handleUpdate() {
    _dirty = true;
    markNeedsBuild();
  }

  @override
  void notifyClients(DeckCards oldWidget) {
    super.notifyClients(oldWidget);
    _dirty = false;
  }

  @override
  void unmount() {
    (widget as DeckCards).model._modifiedCards.removeListener(_handleUpdate);
    super.unmount();
  }
}

class DeckReorderButton extends StatelessWidget {
  final AnimationController controller;
  final void Function() onTap;
  const DeckReorderButton({
    super.key,
    required this.controller,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const selectDownscale = 0.85;
    final selectScale = controller.drive(
      TweenSequence([
        TweenSequenceItem(
            tween: Tween(begin: 1.0, end: selectDownscale)
                .chain(CurveTween(curve: Curves.decelerate)),
            weight: 50),
        TweenSequenceItem(
            tween: Tween(begin: selectDownscale, end: 1.05)
                .chain(CurveTween(curve: Curves.decelerate.flipped)),
            weight: 50),
      ])
    );
    final selectColor = ColorTween(
        begin: const Color.fromRGBO(71, 16, 175, 1.0),
        end: const Color.fromRGBO(167, 231, 9, 1.0))
        .animate(controller);
    final selectTextColor = ColorTween(begin: Colors.white, end: Colors.black)
        .animate(controller);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: controller,
        builder: (_, __) {
          final textStyle = DefaultTextStyle.of(context)
              .style
              .copyWith(color: selectTextColor.value);
          return AspectRatio(
            aspectRatio: 2 / 1,
            child: Transform.scale(
              scale: selectScale.value,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: selectColor.value,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.black,
                    width: 0.5,
                  ),
                ),
                child: Center(
                  child: DefaultTextStyle(
                    style: textStyle,
                    child: Text("Reorder"),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
