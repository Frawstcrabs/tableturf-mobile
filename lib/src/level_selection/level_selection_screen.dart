// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tableturf_mobile/src/components/selection_button.dart';
import 'package:tableturf_mobile/src/game_internals/opponentAI.dart';
import 'package:tableturf_mobile/src/game_internals/player.dart';
import 'package:tableturf_mobile/src/level_selection/opponents.dart';
import 'package:tableturf_mobile/src/player_progress/player_progress.dart';
import 'package:tableturf_mobile/src/settings/settings.dart';

import '../components/list_select_prompt.dart';
import '../game_internals/card.dart';
import '../game_internals/deck.dart';
import '../game_internals/map.dart';
import '../game_internals/tile.dart';
import '../play_session/build_game_session_page.dart';
import '../style/constants.dart';
import '../style/responsive_screen.dart';
import '../components/deck_thumbnail.dart';

const cardNameCharacters = [
  'A', 'B', 'C', 'D', 'E', 'F',
  'G', 'H', 'I', 'J', 'K', 'L',
  'M', 'N', 'O', 'P', 'Q', 'R',
  'S', 'T', 'U', 'V', 'W', 'X',
  'Y', 'Z'
];

Set<Coords> getSurroundingCoords(Coords point, [bool checkBounds = true]) {
  return Set.of([
    for (int dy = -1; dy <= 1; dy++)
      for (int dx = -1; dx <= 1; dx++)
        if (
          !checkBounds || (
              point.x + dx >= 0 && point.x + dx < 8 &&
              point.y + dy >= 0 && point.y + dy < 8))
          Coords(point.x + dx, point.y + dy)
  ])..remove(point);
}

int randomiserCardID = 0;
List<TableturfCardData> createPureRandomCards() {
  const cardSizes = [
    1, 2, 3, 4, 5, 6,
    7, 7, 8, 8, 9, 9, 10, 10,
    11, 12, 13, 14, 15, 16, 17
  ];
  const specialCosts = [1, 1, 1, 1, 2, 2, 3, 3, 3, 4, 4, 4, 5, 5, 5, 6, 6, 6];
  final rng = Random();
  var noSpecialCards = 2;
  final List<TableturfCardData> ret = [];
  for (final size in cardSizes.randomSample(15)) {
    final rawPattern = [
      for (int i = 0; i < 8; i++) [
        for (int j = 0; j < 8; j++)
          TileState.unfilled
      ]
    ];
    late final bool hasSpecial;
    if (noSpecialCards > 0 && size >= 6 && rng.nextDouble() < 0.05) {
      hasSpecial = false;
      noSpecialCards -= 1;
    } else {
      hasSpecial = true;
    }

    final Coords startPoint = Coords(rng.nextInt(8), rng.nextInt(8));
    final Set<Coords> specialSurrounding = getSurroundingCoords(startPoint, false);
    final Set<Coords> filledTiles = {startPoint};
    rawPattern[startPoint.y][startPoint.x] = hasSpecial ? TileState.yellowSpecial : TileState.yellow;
    for (var i = 1; i < size; i++) {
      while (true) {
        final nextStartPoint = filledTiles.toList().random();
        final newPoint = getSurroundingCoords(nextStartPoint).toList().random();
        if (filledTiles.contains(newPoint)) {
          continue;
        }
        if (hasSpecial && specialSurrounding.contains(newPoint) && specialSurrounding.length == 1) {
          // adding this point would mean the special is completely surrounded, which we can't allow
          continue;
        }
        filledTiles.add(newPoint);
        specialSurrounding.remove(newPoint);
        rawPattern[newPoint.y][newPoint.x] = TileState.yellow;
        break;
      }
    }

    final centeredPattern = getMinPattern(rawPattern);
    final height = centeredPattern.length;
    final width = centeredPattern[0].length;

    for (var i = width; i < 8; i++) {
      if (i % 2 == 1) {
        for (final row in centeredPattern) {
          row.add(TileState.unfilled);
        }
      } else {
        for (final row in centeredPattern) {
          row.insert(0, TileState.unfilled);
        }
      }
    }

    for (var i = height; i < 8; i++) {
      if (i % 2 == 1) {
        centeredPattern.add([
          TileState.unfilled, TileState.unfilled,
          TileState.unfilled, TileState.unfilled,
          TileState.unfilled, TileState.unfilled,
          TileState.unfilled, TileState.unfilled,
        ]);
      } else {
        centeredPattern.insert(0, [
          TileState.unfilled, TileState.unfilled,
          TileState.unfilled, TileState.unfilled,
          TileState.unfilled, TileState.unfilled,
          TileState.unfilled, TileState.unfilled,
        ]);
      }
    }

    final name = cardNameCharacters.randomSample(3 + rng.nextInt(7)).join();
    final specialCost = max(1, specialCosts[size] - (hasSpecial ? 0 : 2));
    ret.add(TableturfCardData(
        randomiserCardID,
      name,
      "randomiser",
      specialCost,
      centeredPattern,
      name,
      TableturfCardType.randomiser,
      "assets/images/card_illustrations/random${rng.nextInt(4)}.png"
    ));
    randomiserCardID += 1;
  }
  return ret;
}


const BATTLE_LOSS_XP = 40;

class LevelSelectionEntry extends StatefulWidget {
  final String name;
  final String entryID;
  final String? openedEntryID;
  final String? icon;
  final Future<void> Function(TableturfDeck, AILevel) onStart;
  const LevelSelectionEntry({
    super.key,
    required this.name,
    this.icon,
    required this.entryID,
    required this.openedEntryID,
    required this.onStart,
  });

  @override
  State<LevelSelectionEntry> createState() => _LevelSelectionEntryState();
}

class _LevelSelectionEntryState extends State<LevelSelectionEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _expandController;
  late final Animation<double> entryHeight;
  late final Animation<double> detailsOpacity;
  final ValueNotifier<bool> offstageNotifier = ValueNotifier(true);
  final ValueNotifier<TableturfDeck?> deckNotifier = ValueNotifier(null);
  late final ValueNotifier<AILevel> difficultyNotifier = ValueNotifier(AILevel.level1);
  static const DESIGN_WIDTH = 500.0;
  static const DESIGN_HEIGHT = 200.0;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _expandController.value = (widget.entryID == widget.openedEntryID) ? 1.0 : 0.0;
    offstageNotifier.value = widget.entryID != widget.openedEntryID;
    entryHeight = Tween<double>(
      begin: 0.0,
      end: DESIGN_HEIGHT,
    ).animate(
      CurvedAnimation(
        parent: _expandController,
        curve: Interval(0.0, 0.5, curve: Curves.ease),
        reverseCurve: Interval(0.5, 1.0, curve: Curves.ease.flipped),
      ),
    );
    detailsOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _expandController,
        curve: Interval(0.5, 1.0),
        reverseCurve: Interval(0.0, 0.5),
      ),
    );
  }

  Future<void> _openDetails() async {
    _expandController.value = 0.0;
    await _expandController.animateTo(0.5);
    offstageNotifier.value = false;
    await _expandController.animateTo(1.0);
  }

  Future<void> _closeDetails() async {
    await _expandController.reverse(from: 1.0);
    offstageNotifier.value = true;
  }

  @override
  void didUpdateWidget(covariant LevelSelectionEntry oldWidget) {
    super.didUpdateWidget(oldWidget);
    final isOpened = widget.entryID == widget.openedEntryID;
    final wasOpened = oldWidget.entryID == oldWidget.openedEntryID;
    if (!wasOpened && isOpened) {
      _openDetails();
    } else if (wasOpened && !isOpened) {
      _closeDetails();
    }
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  Future<void> _showSelectDeckPrompt() async {
    final settings = Settings();
    final ScrollController scrollController = ScrollController();
    const popupBorderWidth = 1.0;
    const itemListPadding = 10.0;
    const interItemPadding = 5.0;

    final TableturfDeck? selectedCard = await showListSelectPrompt(
      context,
      title: "Select Deck",
      builder: (context, exitPopup) => RawScrollbar(
        controller: scrollController,
        thickness: popupBorderWidth + (itemListPadding / 2),
        padding: const EdgeInsets.fromLTRB(
          (popupBorderWidth + interItemPadding) / 2,
          popupBorderWidth + itemListPadding + interItemPadding,
          (popupBorderWidth + interItemPadding) / 2,
          popupBorderWidth + itemListPadding + interItemPadding,
        ),
        thumbColor: const Color.fromRGBO(0, 0, 0, 0.4),
        radius: Radius.circular(6),
        child: ListView.builder(
          controller: scrollController,
          itemCount: settings.decks.length,
          padding: const EdgeInsets.all(itemListPadding),
          itemBuilder: (_, i) => GestureDetector(
            onTap: () {
              exitPopup(settings.decks[i].value);
            },
            child: AspectRatio(
              aspectRatio: DeckThumbnail.THUMBNAIL_RATIO,
              child: DeckThumbnail(
                deck: settings.decks[i].value
              ),
            )
          ),
        ),
      ),
    );
    if (selectedCard != null) {
      deckNotifier.value = selectedCard;
    }
    scrollController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = Settings();
    final playerProgress = PlayerProgress();
    final winCountMap = playerProgress.getWins(widget.entryID);
    final difficultySet = playerProgress.getDifficulties(widget.entryID);
    return Padding(
      padding: const EdgeInsets.all(3.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const designWidth = 440;
          final designRatio = constraints.maxWidth / designWidth;
          final winCountTextStyle = TextStyle(
            color: Colors.white, //Colors.grey[600],
            fontSize: 16 * designRatio,
            letterSpacing: 0.3 * designRatio,
            fontFamily: "Splatfont2"
          );
          const borderWidth = 1.0;
          final borderRadius = 6 * designRatio;
          final winCounts = DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(width: borderWidth),
              borderRadius: BorderRadius.circular(borderRadius),
              color: Colors.grey[600]
            ),
            child: Padding(
              padding: const EdgeInsets.all(borderWidth),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(borderRadius),
                child: ListenableBuilder(
                  listenable: Listenable.merge([difficultyNotifier]),
                  builder: (_, __) {
                    final currentDifficulty = difficultyNotifier.value;
                    var makeWinCountLine = (int i) {
                      final level = AILevel.values[i];
                      final textStyle = winCountTextStyle.copyWith(
                        color: currentDifficulty == level
                          ? Colors.black
                          : Colors.white
                      );
                      return GestureDetector(
                        onTap: () {
                          if (!difficultySet.contains(level)) {
                            return;
                          }
                          difficultyNotifier.value = level;
                        },
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: currentDifficulty == level
                              ? Colors.white
                              : !difficultySet.contains(level)
                                ? Colors.grey[850]
                                : Colors.grey[650]
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Text(
                                "Lv. ${i+1}",
                                style: textStyle
                              ),
                              RichText(
                                text: TextSpan(children: [
                                  TextSpan(
                                    text: winCountMap[level].toString(),
                                    style: textStyle,
                                  ),
                                  TextSpan(
                                    text: " Wins",
                                    style: textStyle.copyWith(
                                      fontSize: 10 * designRatio,
                                    ),
                                  ),
                                ]),
                              )
                            ]
                          ),
                        ),
                      );
                    };
                    return Column(
                      children: [
                        for (var i = 0; i < AILevel.values.length; i++)
                          Expanded(
                            child: makeWinCountLine(i)
                          )
                      ]
                    );
                  },
                ),
              ),
            ),
          );
          return Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey[900]!,
                width: 3 * designRatio,
              ),
              color: Colors.indigo[700],
              borderRadius: BorderRadius.circular(10.0 * designRatio),
            ),
            child: Column(
              children: [
                Container(
                  height: 80 * designRatio,
                  child: SizedBox.expand(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Padding(
                            padding: EdgeInsets.all((80 * 0.05)* designRatio),
                            child: Image.asset(
                              "assets/images/character_icons/${widget.icon}.png",
                              opacity: const AlwaysStoppedAnimation(0.6),
                            ),
                          ),
                        ),
                        Center(
                          child: Text(
                            widget.name,
                            style: TextStyle(fontSize: 20 * designRatio)
                          )
                        ),
                      ],
                    ),
                  )
                ),
                AnimatedBuilder(
                  animation: entryHeight,
                  child: ValueListenableBuilder(
                    valueListenable: offstageNotifier,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        14.0 * designRatio,
                        7.0 * designRatio,
                        14.0 * designRatio,
                        14.0 * designRatio,
                      ),
                      child: Row(
                        children: [
                          const Spacer(flex: 1),
                          Expanded(
                            flex: 5,
                            child: winCounts
                          ),
                          const Spacer(flex: 1),
                          Expanded(
                            flex: 10,
                            child: Column(
                              children: [
                                Expanded(
                                  flex: 5,
                                  child: GestureDetector(
                                    onTap: () async {
                                      _showSelectDeckPrompt();
                                    },
                                    child: ValueListenableBuilder(
                                      valueListenable: deckNotifier,
                                      builder: (context, TableturfDeck? deck, _) {
                                        late final Widget thumbnail;
                                        if (deck == null) {
                                          thumbnail = Center(
                                            child: AspectRatio(
                                              aspectRatio: DeckThumbnail.THUMBNAIL_RATIO,
                                              child: DecoratedBox(
                                                decoration: BoxDecoration(
                                                  border: Border.all(),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Center(
                                                  child: Text("Select deck"),
                                                ),
                                              ),
                                            ),
                                          );
                                        } else {
                                          thumbnail = DeckThumbnail(deck: deck);
                                        }
                                        return thumbnail;
                                      }
                                    ),
                                  )
                                ),
                                const Spacer(flex: 1),
                                Expanded(
                                  flex: 5,
                                  child: SelectionButton(
                                    designRatio: designRatio / 1.5,
                                    onPressStart: () async {
                                      return deckNotifier.value != null;
                                    },
                                    onPressEnd: () async {
                                      final chosenDeck = deckNotifier.value!;
                                      List<TableturfCardData>? randomCards = null;
                                      late final TableturfDeck yellowDeck;
                                      if (chosenDeck.deckID == -1000) {
                                        randomCards = createPureRandomCards();
                                        for (final card in randomCards) {
                                          settings.registerTempCard(card);
                                        }
                                        yellowDeck = TableturfDeck(
                                            deckID: -1000,
                                            name: "Randomiser",
                                            cardSleeve: "randomiser",
                                            cards: [for (final card in randomCards) card.ident]
                                        );
                                      } else {
                                        yellowDeck = chosenDeck;
                                      }
                                      await Future<void>.delayed(const Duration(milliseconds: 300));
                                      await widget.onStart(
                                        yellowDeck,
                                        difficultyNotifier.value,
                                      );
                                      setState(() {});
                                      if (randomCards != null) {
                                        for (final card in randomCards) {
                                          settings.removeTempCard(card.ident);
                                        }
                                      }
                                    },
                                    child: Text("Start Game"),
                                  )
                                ),
                              ],
                            )
                          ),
                          const Spacer(flex: 1),
                        ]
                      ),
                    ),
                    builder: (ctx, bool isOffstage, child) {
                      return Offstage(
                        offstage: isOffstage,
                        child: FadeTransition(
                          opacity: detailsOpacity,
                          child: OverflowBox(
                            maxWidth: DESIGN_WIDTH * designRatio,
                            maxHeight: DESIGN_HEIGHT * designRatio,
                            alignment: Alignment.topCenter,
                            child: child
                          ),
                        )
                      );
                    }
                  ),
                  builder: (ctx, child) {
                    return ClipRect(
                      child: SizedBox(
                        width: DESIGN_WIDTH * designRatio,
                        height: entryHeight.value * designRatio,
                        child: child,
                      ),
                    );
                  }
                ),
              ]
            )
          );
        }
      ),
    );
  }
}


class LevelSelectionScreen extends StatefulWidget {
  const LevelSelectionScreen({super.key});

  @override
  State<LevelSelectionScreen> createState() => _LevelSelectionScreenState();
}

class _LevelSelectionScreenState extends State<LevelSelectionScreen> {
  final ValueNotifier<String?> openedEntryNotifier = ValueNotifier(null);
  @override
  Widget build(BuildContext context) {
    final settings = Settings();
    final playerProgress = context.watch<PlayerProgress>();

    return Scaffold(
      backgroundColor: Palette.backgroundLevelSelection,
      body: ResponsiveScreen(
        squarishMainArea: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'Select Level',
                  style: TextStyle(fontFamily: 'Splatfont1', fontSize: 30),
                ),
              ),
            ),
            const SizedBox(height: 50),
            Expanded(
              child: DefaultTextStyle(
                style: TextStyle(
                  fontFamily: "Splatfont2",
                  color: Colors.white,
                ),
                child: ListenableBuilder(
                  listenable: openedEntryNotifier,
                  builder: (context, _) => ListView(
                    padding: const EdgeInsets.all(10),
                    children: [
                      for (final opponent in opponents)
                        GestureDetector(
                          onTap: () {
                            final entryID = "deck:${opponent.deck.deckID}";
                            if (openedEntryNotifier.value == entryID) {
                              openedEntryNotifier.value = null;
                            } else {
                              openedEntryNotifier.value = entryID;
                            }
                          },
                          child: LevelSelectionEntry(
                            name: opponent.name,
                            openedEntryID: openedEntryNotifier.value,
                            entryID: "deck:${opponent.deck.deckID}",
                            icon: deckIcons[opponent.deck.deckID],
                            onStart: (yellowDeck, difficulty) async {
                              await startGame(
                                context: context,
                                map: settings.getMap(opponent.mapID),
                                yellowDeck: yellowDeck,
                                yellowName: settings.playerName.value,
                                blueDeck: opponent.deck,
                                blueName: opponent.name,
                                blueIcon: deckIcons[opponent.deck.deckID],
                                aiLevel: difficulty,
                                onWin: () async {
                                  playerProgress.incrementWins(
                                    "deck:${opponent.deck.deckID}",
                                    difficulty
                                  );
                                  playerProgress.xp += difficulty.xpAmount;
                                },
                                onLose: () async {
                                  playerProgress.xp += BATTLE_LOSS_XP;
                                },
                                showXpPopup: true,
                              );
                            },
                          ),
                        ),
                      GestureDetector(
                        onTap: () {
                          openedEntryNotifier.value = "clonejelly";
                        },
                        child: LevelSelectionEntry(
                          name: "Clone Jelly",
                          openedEntryID: openedEntryNotifier.value,
                          entryID: "clonejelly",
                          icon: "clonejelly",
                          onStart: (yellowDeck, difficulty) async {
                            await startGame(
                              context: context,
                              map: settings.getMap(-1),
                              yellowDeck: yellowDeck,
                              yellowName: settings.playerName.value,
                              blueDeck: yellowDeck,
                              blueName: "Clone Jelly",
                              blueIcon: "clonejelly",
                              aiLevel: difficulty,
                              onWin: () async {
                                playerProgress.incrementWins(
                                    "clonejelly", difficulty);
                                playerProgress.xp += difficulty.xpAmount;
                              },
                              onLose: () async {
                                playerProgress.xp += BATTLE_LOSS_XP;
                              },
                              showXpPopup: true,
                            );
                          },
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          openedEntryNotifier.value = "randomiser";
                        },
                        child: LevelSelectionEntry(
                          name: "Randomiser",
                          openedEntryID: openedEntryNotifier.value,
                          entryID: "randomiser",
                          icon: "randomiser",
                          onStart: (yellowDeck, difficulty) async {
                            final randomCards = createPureRandomCards();
                            for (final card in randomCards) {
                              settings.registerTempCard(card);
                            }
                            final blueDeck = TableturfDeck(
                                deckID: -1000,
                                name: "Randomiser",
                                cardSleeve: "randomiser",
                                cards: [for (final card in randomCards) card.ident]
                            );
                            await startGame(
                              context: context,
                              map: officialMaps.random(),
                              yellowDeck: yellowDeck,
                              yellowName: settings.playerName.value,
                              blueDeck: blueDeck,
                              blueName: "Randomiser",
                              blueIcon: "randomiser",
                              aiLevel: difficulty,
                              onWin: () async {
                                playerProgress.incrementWins("randomiser", difficulty);
                                playerProgress.xp += difficulty.xpAmount;
                              },
                              onLose: () async {
                                playerProgress.xp += BATTLE_LOSS_XP;
                              },
                              showXpPopup: true,
                            );
                            for (final card in randomCards) {
                              settings.removeTempCard(card.ident);
                            }
                          },
                        ),
                      ),
                    ],
                  )
                ),
              ),
            ),
          ],
        ),
        rectangularMenuArea: ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Back'),
        ),
      ),
    );
  }
}
