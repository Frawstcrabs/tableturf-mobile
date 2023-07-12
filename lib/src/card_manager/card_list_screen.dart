import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tableturf_mobile/src/game_internals/player.dart';
import 'package:tableturf_mobile/src/play_session/components/card_selection.dart';
import 'package:tableturf_mobile/src/play_session/components/selection_button.dart';
import 'package:tableturf_mobile/src/settings/settings.dart';

import '../game_internals/card.dart';
import '../play_session/components/card_widget.dart';
import '../style/palette.dart';
import 'deck_list_screen.dart';

class CardRarityDisplay extends StatefulWidget {
  final String rarity;
  const CardRarityDisplay({
    super.key,
    required this.rarity
  });

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
          widget.rarity[0].toUpperCase() + widget.rarity.substring(1).toLowerCase(),
          style: const TextStyle(
            fontFamily: "Splatfont1",
            color: Colors.black,
            fontSize: 36,
            shadows: [Shadow(color: Color.fromRGBO(0, 0, 0, 0.2), offset: Offset(2,2))]
          )
        ),
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
            transform: GradientRotation((pi * 2) * backgroundController.value)
          ),
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
            transform: GradientRotation((pi * 2) * backgroundController.value)
          ),
        }[widget.rarity];
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: bgGradient,
            color: widget.rarity != "rare" && widget.rarity != "fresh"
              ? Colors.white
              : null
          ),
          child: child
        );
      }
    );
  }
}

class CardPopup extends StatelessWidget {
  final TableturfCardData card;
  const CardPopup({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (context, constraints) {
          const headerFlex = 6.0;
          const gapFlex = 0.5;
          const cardFlex = 32.0;
          const flexSum = headerFlex + gapFlex + cardFlex;
          const boxLayoutRatio = CardWidget.CARD_WIDTH / (CardWidget.CARD_HEIGHT * (((flexSum*2) - cardFlex) / flexSum));
          final realLayoutRatio = constraints.maxWidth / constraints.maxHeight;
          final columnWidth = boxLayoutRatio > realLayoutRatio
              ? constraints.maxWidth
              : constraints.maxWidth * (boxLayoutRatio / realLayoutRatio);
          return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: columnWidth,
                  child: AspectRatio(
                    aspectRatio: flexSum/headerFlex,
                    child: Row(
                        children: [
                          Expanded(
                              child: FittedBox(
                                  fit: BoxFit.fitHeight,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                      "No. ${card.num}",
                                      style: TextStyle(
                                        fontFamily: "Splatfont1",
                                        color: const Color.fromRGBO(
                                            192, 192, 192, 1.0),
                                        fontSize: 36,
                                      )
                                  )
                              )
                          ),
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
                                            child: CardRarityDisplay(rarity: card.rarity)
                                        ),
                                      )
                                  ),
                                ),
                              )
                          )
                        ]
                    ),
                  ),
                ),
                SizedBox(
                    width: columnWidth,
                    child: AspectRatio(aspectRatio: flexSum/gapFlex)
                ),
                SizedBox(
                  width: columnWidth,
                  child: CardFrontWidget(
                    card: card,
                    traits: const YellowTraits(),
                    isHidden: false,
                  ),
                )
              ]
          );
        }
    );
  }
}

class CardListItem extends StatefulWidget {
  final TableturfCardIdentifier ident;
  final ValueListenable<TableturfCardIdentifier?> cardScrollNotifier;
  final bool isHidden;

  const CardListItem({
    required this.ident,
    required this.cardScrollNotifier,
    this.isHidden = false,
    super.key
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
    if (widget.cardScrollNotifier.value == widget.ident) {
      Scrollable.ensureVisible(
        context,
        alignment: 0.5,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsController();
    return CardFrontWidget(
      card: settings.identToCard(widget.ident),
      traits: const YellowTraits(),
      isHidden: false,
    );
  }
}


class CardListScreen extends StatefulWidget {
  const CardListScreen({Key? key}) : super(key: key);

  @override
  State<CardListScreen> createState() => _CardListScreenState();
}

class _CardListScreenState extends State<CardListScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _cardPopupController;
  late final Animation<double> _cardScaleForward, _cardScaleReverse, _cardOpacity;
  bool _popupIsActive = false;
  bool _lockButtons = false;
  final ChangeNotifier _popupExit = ChangeNotifier();
  final ValueNotifier<TableturfCardIdentifier?> _cardScrollNotifier = ValueNotifier(null);

  @override
  void initState() {
    super.initState();
    _cardPopupController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _cardScaleForward = Tween(
        begin: 0.6,
        end: 1.0
    )
        .chain(CurveTween(curve: Curves.easeOutBack))
        .animate(_cardPopupController);
    _cardScaleReverse = Tween(
        begin: 0.6,
        end: 1.0
    )
    //.chain(CurveTween(curve: Curves.easeOut))
        .animate(_cardPopupController);
    _cardOpacity = Tween(
        begin: 0.0,
        end: 1.0
    )
    //.chain(CurveTween(curve: Curves.easeOut))
        .animate(_cardPopupController);
  }

  @override
  void dispose() {
    _cardPopupController.dispose();
    super.dispose();
  }

  Future<void> _showOfficialCardPopup(BuildContext context, int cardIndex) async {
    final overlayState = Overlay.of(context);
    late final OverlayEntry overlayEntry;
    late final void Function() onPopupExit;
    onPopupExit = () async {
      await _cardPopupController.reverse();
      overlayEntry.remove();
      _popupIsActive = false;
      _popupExit.removeListener(onPopupExit);
    };
    final PageController _pageController = PageController(initialPage: cardIndex);
    overlayEntry = OverlayEntry(builder: (_) {
      return DefaultTextStyle(
        style: TextStyle(
            fontFamily: "Splatfont2",
            color: Colors.black,
            fontSize: 16,
            letterSpacing: 0.6,
            shadows: [
              Shadow(
                color: const Color.fromRGBO(256, 256, 256, 0.4),
                offset: Offset(1, 1),
              )
            ]
        ),
        child: AnimatedBuilder(
            animation: _cardPopupController,
            child: PageView.builder(
              controller: _pageController,
              itemCount: officialCards.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    GestureDetector(
                      onTap: onPopupExit,
                    ),
                    Center(
                      child: FractionallySizedBox(
                        heightFactor: 0.8,
                        widthFactor: 0.8,
                        child: CardPopup(
                          card: officialCards[index]
                        )
                      )
                    ),
                  ],
                );
              },
              onPageChanged: (newIndex) {
                _cardScrollNotifier.value = officialCards[newIndex].ident;
              },
            ),
            builder: (_, child) {
              return Stack(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                          color: Color.fromRGBO(0, 0, 0, _cardPopupController.value * 0.7)
                      ),
                      child: Container(),
                    ),
                    Opacity(
                        opacity: _cardOpacity.value,
                        child: Transform.scale(
                          scale: _cardPopupController.status == AnimationStatus.forward
                              ? _cardScaleForward.value
                              : _cardScaleReverse.value,
                          child: child!,
                        )
                    )
                  ]
              );
            }
        ),
      );
    });
    overlayState.insert(overlayEntry);
    _cardPopupController.forward(from: 0.0);
    _popupIsActive = true;
    _popupExit.addListener(onPopupExit);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();
    final mediaQuery = MediaQuery.of(context);
    final screen = Column(
        children: [
          Expanded(
              flex: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                    border: Border(bottom: BorderSide())
                ),
                child: Center(
                    child: Text(
                        "Card List",
                      style: TextStyle(
                        fontFamily: "Splatfont1",
                      )
                    )
                ),
              )
          ),
          Expanded(
            flex: 9,
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                mainAxisSpacing: 5,
                crossAxisSpacing: 5,
                crossAxisCount: mediaQuery.orientation == Orientation.portrait ? 3 : 7,
                childAspectRatio: CardWidget.CARD_RATIO
              ),
              padding: EdgeInsets.all(10),
              itemCount: officialCards.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    if (_lockButtons) return;
                    _cardScrollNotifier.value = officialCards[index].ident;
                    _showOfficialCardPopup(context, index);
                  },
                  child: CardListItem(
                    ident: officialCards[index].ident,
                    cardScrollNotifier: _cardScrollNotifier,
                    isHidden: false,
                  ),
                );
              },
            )
          ),
          Expanded(
              flex: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                    border: Border(top: BorderSide())
                ),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: SelectionButton(
                            child: Text("Edit Deck"),
                            designRatio: 0.5,
                            onPressStart: () async {
                              if (_lockButtons || _popupIsActive) return false;
                              _lockButtons = true;
                              return true;
                            },
                            onPressEnd: () async {
                              await Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) {
                                  return const DeckListScreen();
                                }
                              ));
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
                              if (_lockButtons || _popupIsActive) return false;
                              _lockButtons = true;
                              return true;
                            },
                            onPressEnd: () async {
                              Navigator.of(context).pop();
                              return Future<void>.delayed(const Duration(milliseconds: 100));
                            },
                          ),
                        ),
                      ),
                    ]
                ),
              )
          ),
        ]
    );
    return WillPopScope(
      onWillPop: () async {
        if (_popupIsActive) {
          _popupExit.notifyListeners();
          return false;
        }
        return true;
      },
      child: Scaffold(
          backgroundColor: palette.backgroundCardList,
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
              child: screen,
            ),
          )
      ),
    );
  }
}


