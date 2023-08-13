import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tableturf_mobile/src/game_internals/player.dart';
import 'package:tableturf_mobile/src/components/card_selection.dart';
import 'package:tableturf_mobile/src/components/selection_button.dart';
import 'package:tableturf_mobile/src/settings/settings.dart';

import '../game_internals/card.dart';
import '../components/card_widget.dart';
import '../player_progress/player_progress.dart';
import '../style/constants.dart';
import 'deck_list_screen.dart';

class CardRarityDisplay extends StatefulWidget {
  final String rarity;
  const CardRarityDisplay({super.key, required this.rarity});

  @override
  State<CardRarityDisplay> createState() => _CardRarityDisplayState();
}

class _CardRarityDisplayState extends State<CardRarityDisplay>
    with SingleTickerProviderStateMixin {
  late final AnimationController backgroundController;

  @override
  void initState() {
    super.initState();
    backgroundController = AnimationController(
      duration: const Duration(milliseconds: 12000),
      vsync: this,
    );
    if (widget.rarity == "rare" || widget.rarity == "fresh") {
      backgroundController.repeat();
    }
  }

  @override
  void dispose() {
    backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: backgroundController,
        child: FittedBox(
          fit: BoxFit.fitHeight,
          child: Text(
              widget.rarity[0].toUpperCase() +
                  widget.rarity.substring(1).toLowerCase(),
              style: const TextStyle(
                  fontFamily: "Splatfont1",
                  color: Colors.black,
                  fontSize: 36,
                  shadows: [
                    Shadow(
                        color: Color.fromRGBO(0, 0, 0, 0.2),
                        offset: Offset(2, 2))
                  ])),
        ),
        builder: (context, child) {
          Gradient? bgGradient = {
            "rare": SweepGradient(
                colors: const [
                  Color.fromRGBO(254, 210, 0, 1.0),
                  Color.fromRGBO(255, 251, 207, 1.0),
                  Color.fromRGBO(223, 170, 13, 1.0),
                  Color.fromRGBO(255, 252, 209, 1.0),
                  Color.fromRGBO(254, 210, 0, 1.0),
                ],
                stops: const [
                  0.0,
                  0.2,
                  0.55,
                  0.9,
                  1.0,
                ],
                transform:
                    GradientRotation((pi * 2) * backgroundController.value)),
            "fresh": SweepGradient(
                colors: const [
                  Color.fromRGBO(255, 235, 68, 1.0),
                  Color.fromRGBO(65, 244, 255, 1.0),
                  Color.fromRGBO(240, 90, 177, 1.0),
                  Color.fromRGBO(28, 253, 57, 1.0),
                  Color.fromRGBO(255, 235, 68, 1.0),
                ],
                stops: const [
                  0.0,
                  0.1,
                  0.45,
                  0.7,
                  1.0,
                ],
                tileMode: TileMode.repeated,
                transform:
                    GradientRotation((pi * 2) * backgroundController.value)),
          }[widget.rarity];
          return DecoratedBox(
              decoration: BoxDecoration(
                  gradient: bgGradient,
                  color: widget.rarity != "rare" && widget.rarity != "fresh"
                      ? Colors.white
                      : null),
              child: child);
        });
  }
}

class CardPopup extends StatelessWidget {
  final TableturfCardData card;
  final bool isVisible;
  const CardPopup({
    super.key,
    required this.card,
    required this.isVisible,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      const headerFlex = 6.0;
      const gapFlex = 0.5;
      const cardFlex = 32.0;
      const flexSum = headerFlex + gapFlex + cardFlex;
      const boxLayoutRatio = CardWidget.CARD_WIDTH /
          (CardWidget.CARD_HEIGHT * (((flexSum * 2) - cardFlex) / flexSum));
      final realLayoutRatio = constraints.maxWidth / constraints.maxHeight;
      final columnWidth = boxLayoutRatio > realLayoutRatio
          ? constraints.maxWidth
          : constraints.maxWidth * (boxLayoutRatio / realLayoutRatio);
      return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        SizedBox(
          width: columnWidth,
          child: AspectRatio(
            aspectRatio: flexSum / headerFlex,
            child: Row(children: [
              Expanded(
                  child: FittedBox(
                      fit: BoxFit.fitHeight,
                      alignment: Alignment.centerLeft,
                      child: Text("No. ${card.num}",
                          style: TextStyle(
                            fontFamily: "Splatfont1",
                            color: const Color.fromRGBO(192, 192, 192, 1.0),
                            fontSize: 36,
                          )))),
              Expanded(
                  child: Align(
                alignment: Alignment.centerRight,
                child: Transform.rotate(
                  angle: 0.05 * pi,
                  child: FractionallySizedBox(
                      heightFactor: 0.7,
                      child: AspectRatio(
                        aspectRatio: 3.0,
                        child: RepaintBoundary(
                            child: CardRarityDisplay(rarity: card.rarity)),
                      )),
                ),
              ))
            ]),
          ),
        ),
        SizedBox(
            width: columnWidth,
            child: AspectRatio(aspectRatio: flexSum / gapFlex)),
        SizedBox(
          width: columnWidth,
          child: CardFrontWidget(
            card: card,
            traits: const YellowTraits(),
            isVisible: isVisible,
          ),
        )
      ]);
    });
  }
}

class CardListItem extends StatefulWidget {
  final TableturfCardData card;
  final ValueListenable<TableturfCardIdentifier?> cardScrollNotifier;
  final bool isVisible;

  const CardListItem({
    super.key,
    required this.card,
    required this.cardScrollNotifier,
    required this.isVisible,
  });

  @override
  State<CardListItem> createState() => _CardListItemState();
}

class _CardListItemState extends State<CardListItem> {
  @override
  void initState() {
    super.initState();
    widget.cardScrollNotifier.addListener(_checkScrollToItem);
  }

  @override
  void dispose() {
    widget.cardScrollNotifier.removeListener(_checkScrollToItem);
    super.dispose();
  }

  void _checkScrollToItem() {
    if (widget.cardScrollNotifier.value == widget.card.ident) {
      Scrollable.ensureVisible(
        context,
        alignment: 0.5,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CardFrontWidget(
      card: widget.card,
      traits: const YellowTraits(),
      isVisible: widget.isVisible,
    );
  }
}

class CardListScreen extends StatefulWidget {
  const CardListScreen({Key? key}) : super(key: key);

  @override
  State<CardListScreen> createState() => _CardListScreenState();
}

class _CardListScreenState extends State<CardListScreen>
    with SingleTickerProviderStateMixin{
  bool _lockButtons = false;
  late final TabController tabController;
  late final ValueNotifier<CardGridViewSortMode> sortMode = ValueNotifier(CardGridViewSortMode.number);

  @override
  void initState() {
    super.initState();
    tabController = TabController(
      length: 2,
      vsync: this,
    );
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final playerProgress = PlayerProgress();

    final screen = Column(
      children: [
        Expanded(
          flex: 2,
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Center(
                  child: FractionallySizedBox(
                    heightFactor: 0.6,
                    child: FittedBox(
                      child: RepaintBoundary(
                        child: Builder(builder: (context) {
                          final cardCount = playerProgress.unlockedCards.length;
                          final textStyle = DefaultTextStyle.of(context).style;
                          const fontSize = 16.0;
                          return RichText(
                            text: TextSpan(children: [
                              TextSpan(
                                text: cardCount.toString(),
                                style: textStyle.copyWith(
                                  fontSize: fontSize,
                                ),
                              ),
                              TextSpan(
                                text: "/${officialCards.length}",
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
                flex: 2,
                child: Center(
                  child: Text(
                    "Card List",
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
          ),
        ),
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
                  cardList: officialCards,
                  cardIsVisible: (c) => playerProgress.unlockedCards.contains(c.ident),
                  sortMode: currentSortMode,
                ),
                CardGridView(
                  cardList: [],
                  cardIsVisible: (c) => true,
                  sortMode: currentSortMode,
                ),
              ],
            ),
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
                    child: Text("Deck List"),
                    designRatio: 0.5,
                    onPressStart: () async {
                      if (_lockButtons) return false;
                      _lockButtons = true;
                      return true;
                    },
                    onPressEnd: () async {
                      await Navigator.of(context)
                          .push(MaterialPageRoute(builder: (_) {
                        return const DeckListScreen();
                      }));
                      _lockButtons = false;
                    },
                  ),
                ),
              ),
              Expanded(
                child: Padding(
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
                      return Future<void>.delayed(
                          const Duration(milliseconds: 100));
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
      backgroundColor: Palette.backgroundCardList,
      body: DefaultTextStyle(
        style: TextStyle(
          fontFamily: "Splatfont2",
          color: Colors.black,
          fontSize: 18,
          letterSpacing: 0.6,
        ),
        child: Padding(
          padding: mediaQuery.padding,
          child: screen,
        ),
      ),
    );
  }
}

enum CardGridViewSortMode {
  number,
  size,
}

class CardGridView extends StatefulWidget {
  final List<TableturfCardData> cardList;
  final CardGridViewSortMode sortMode;
  final bool Function(TableturfCardData) cardIsVisible;
  const CardGridView({
    super.key,
    required this.cardList,
    required this.cardIsVisible,
    required this.sortMode,
  });

  @override
  State<CardGridView> createState() => _CardGridViewState();
}

class _CardGridViewState extends State<CardGridView> {
  final ValueNotifier<TableturfCardIdentifier?> _cardScrollNotifier = ValueNotifier(null);
  late final Map<CardGridViewSortMode, List<TableturfCardData>> cardLists;

  @override
  void initState() {
    super.initState();
    cardLists = {
      CardGridViewSortMode.number: widget.cardList,
      CardGridViewSortMode.size: widget.cardList.sortedBy<num>((c) => c.count),
    };
  }

  Future<void> _showOfficialCardPopup(
      BuildContext context, int cardIndex) async {
    final pageController = PageController(initialPage: cardIndex);
    await Navigator.of(context).push(PageRouteBuilder(
      opaque: false,
      pageBuilder: (_, __, ___) {
        return CardDisplayPopup(
          pageController: pageController,
          cardScrollNotifier: _cardScrollNotifier,
          cardList: cardLists[widget.sortMode]!,
          cardIsVisible: widget.cardIsVisible,
        );
      },
    ));
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final displayCardList = cardLists[widget.sortMode]!;
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        mainAxisSpacing: 5,
        crossAxisSpacing: 5,
        crossAxisCount: mediaQuery.orientation == Orientation.portrait ? 3 : 7,
        childAspectRatio: CardWidget.CARD_RATIO,
      ),
      padding: EdgeInsets.all(10),
      itemCount: displayCardList.length,
      itemBuilder: (context, index) {
        final card = displayCardList[index];
        return GestureDetector(
          onTap: () {
            _cardScrollNotifier.value = card.ident;
            _showOfficialCardPopup(context, index);
          },
          child: CardListItem(
            card: card,
            cardScrollNotifier: _cardScrollNotifier,
            isVisible: widget.cardIsVisible(card),
          ),
        );
      },
    );
  }
}


class CardDisplayPopup extends StatefulWidget {
  final PageController pageController;
  final ValueNotifier<TableturfCardIdentifier?> cardScrollNotifier;
  final List<TableturfCardData> cardList;
  final bool Function(TableturfCardData) cardIsVisible;

  const CardDisplayPopup({
    super.key,
    required this.pageController,
    required this.cardScrollNotifier,
    required this.cardList,
    required this.cardIsVisible,
  });

  @override
  State<CardDisplayPopup> createState() => _CardDisplayPopupState();
}

class _CardDisplayPopupState extends State<CardDisplayPopup>
    with SingleTickerProviderStateMixin {
  late final AnimationController popupController;
  late final Animation<double> popupOpacity, cardScale;
  late final Animation<Decoration> popupBackground;

  @override
  void initState() {
    super.initState();

    popupController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    cardScale = CurvedAnimation(
      parent: popupController.drive(
        Tween(
          begin: 0.6,
          end: 1.0,
        ),
      ),
      curve: Curves.easeOutBack,
      reverseCurve: Curves.linear,
    );
    popupOpacity = popupController.drive(
      Tween(
        begin: 0.0,
        end: 1.0,
      ),
    );
    popupBackground = popupController.drive(
      DecorationTween(
        begin: BoxDecoration(
          color: Colors.transparent,
        ),
        end: BoxDecoration(
          color: Color.fromRGBO(0, 0, 0, 0.7),
        ),
      ),
    );

    onEnter();
  }

  @override
  void dispose() {
    popupController.dispose();
    super.dispose();
  }

  Future<void> onEnter() async {
    await popupController.forward();
  }

  Future<void> onExit() async {
    await popupController.reverse();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final pageView = PageView.builder(
      controller: widget.pageController,
      itemCount: widget.cardList.length,
      itemBuilder: (context, index) {
        var card = widget.cardList[index];
        return Stack(
          children: [
            GestureDetector(
              onTap: onExit,
            ),
            Center(
              child: FractionallySizedBox(
                heightFactor: 0.8,
                widthFactor: 0.8,
                child: CardPopup(
                  card: card,
                  isVisible: widget.cardIsVisible(card),
                ),
              ),
            ),
          ],
        );
      },
      onPageChanged: (newIndex) {
        widget.cardScrollNotifier.value = widget.cardList[newIndex].ident;
      },
    );
    return WillPopScope(
      onWillPop: () async {
        onExit();
        return false;
      },
      child: DefaultTextStyle(
        style: TextStyle(
          fontFamily: "Splatfont2",
          color: Colors.black,
          fontSize: 16,
          letterSpacing: 0.6,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              onTap: onExit,
              child: DecoratedBoxTransition(
                decoration: popupBackground,
                child: SizedBox.expand(),
              ),
            ),
            FadeTransition(
              opacity: popupOpacity,
              child: ScaleTransition(
                scale: cardScale,
                child: pageView,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
