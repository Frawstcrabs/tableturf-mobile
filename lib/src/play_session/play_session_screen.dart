// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart' hide Level;
import 'package:provider/provider.dart';

import '../ads/ads_controller.dart';
import '../audio/audio_controller.dart';
import '../audio/sounds.dart';
import '../game_internals/level_state.dart';
import '../game_internals/move.dart';
import '../game_internals/player.dart';
import '../games_services/games_services.dart';
import '../games_services/score.dart';
import '../in_app_purchase/in_app_purchase.dart';
import '../level_selection/levels.dart';
import '../player_progress/player_progress.dart';
import '../style/confetti.dart';
import '../style/palette.dart';

import '../game_internals/card.dart';
import '../game_internals/tile.dart';

import 'flip_card.dart';


Widget buildTextWidget(String str) {
  return Scaffold(
    backgroundColor: Colors.transparent,
    body: Center(
        child: Text(
            str,
            style: TextStyle(
                fontFamily: "Splatfont2",
                color: Colors.white,
                fontSize: 16,
                letterSpacing: 0.6,
                shadows: [
                  Shadow(
                    color: Color.fromRGBO(256, 256, 256, 0.4),
                    offset: Offset(1, 1),
                  )
                ]
            )
        )
    ),
  );
}

class PlaySessionScreen extends StatefulWidget {
  final TableturfBattle battle;

  const PlaySessionScreen(this.battle, {super.key});

  @override
  State<PlaySessionScreen> createState() => _PlaySessionScreenState();
}

class _PlaySessionScreenState extends State<PlaySessionScreen> {
  static final _log = Logger('PlaySessionScreenState');

  @override
  void initState() {
    super.initState();
    widget.battle.runBlueAI();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();
    final battle = widget.battle;
    final boardState = battle.board;
    final boardTileStep = BoardTile.SIDE_LEN - BoardTile.EDGE_WIDTH;
    final boardHeight = boardState.length * boardTileStep + BoardTile.EDGE_WIDTH;
    final boardWidth = boardState[0].length * boardTileStep + BoardTile.EDGE_WIDTH;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          height: 30
        ),
        const Spacer(),
        SizedBox(
          height: boardHeight,
          width: boardWidth,
          child: Stack(
            children: [
              BoardWidget(
                battle,
              ),
              MoveOverlayWidget(
                battle
              )
            ]
          )
        ),
        /*
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () {
                  int rot = battle.moveRotationNotifier.value;
                  rot -= 1;
                  rot %= 4;
                  battle.moveRotationNotifier.value = rot;
                },
                child: const Text('Rotate Left'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    battle.player1.hand[Random().nextInt(4)] = cards[Random().nextInt(cards.length)];
                  });
                },
                child: const Text('Change Card'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () {
                  var rot = battle.moveRotationNotifier.value;
                  rot += 1;
                  rot %= 4;
                  battle.moveRotationNotifier.value = rot;
                },
                child: const Text('Rotate Right'),
              ),
            ),
          ]
        ),
        */
        const Spacer(),
        SizedBox(
          height: 305,
          child: Container(
            padding: EdgeInsets.all(10),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(999)),
                            color: Color.fromRGBO(33, 5, 139, 1)
                        ),
                        child: Scaffold(
                          backgroundColor: Colors.transparent,
                          body: Center(
                              child: Text(
                                  "1",
                                  style: TextStyle(
                                      fontFamily: "Splatfont1",
                                      fontStyle: FontStyle.italic,
                                      color: Color.fromRGBO(102, 124, 255, 1),
                                      fontSize: 20,
                                      letterSpacing: 0.6,
                                      shadows: [
                                        Shadow(
                                          color: Color.fromRGBO(57, 69, 147, 1),
                                          offset: Offset(2, 2),
                                        )
                                      ]
                                  )
                              )
                          ),
                        )
                    ),
                    Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(999)),
                            color: Color.fromRGBO(191, 191, 191, 1)
                        ),
                        child: Scaffold(
                          backgroundColor: Colors.transparent,
                          body: Center(
                              child: Text(
                                  "12",
                                  style: TextStyle(
                                      fontFamily: "Splatfont1",
                                      fontStyle: FontStyle.italic,
                                      color: Colors.white,
                                      fontSize: 20,
                                      letterSpacing: 0.6,
                                      shadows: [
                                        Shadow(
                                          color: Color.fromRGBO(128, 128, 128, 1),
                                          offset: Offset(2, 2),
                                        )
                                      ]
                                  )
                              )
                          ),
                        )
                    ),
                    Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(999)),
                            color: Color.fromRGBO(154, 169, 77, 1)
                        ),
                        child: Scaffold(
                          backgroundColor: Colors.transparent,
                          body: Center(
                              child: Text(
                                  "1",
                                  style: TextStyle(
                                      fontFamily: "Splatfont1",
                                      fontStyle: FontStyle.italic,
                                      color: Color.fromRGBO(233, 255, 122, 1),
                                      fontSize: 20,
                                      letterSpacing: 0.6,
                                      shadows: [
                                        Shadow(
                                          color: Color.fromRGBO(128, 128, 128, 1),
                                          offset: Offset(2, 2),
                                        )
                                      ]
                                  )
                              )
                          ),
                        )
                    ),
                  ]
                ),
                Expanded(
                  child: Row(
                    //mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            childAspectRatio: CardWidget.CARD_WIDTH/CardWidget.CARD_HEIGHT,
                            children: Iterable.generate(battle.player1.hand.length, (i) {
                              return Center(
                                child: CardWidget(
                                  card: battle.player1.hand[i],
                                  battle: battle,
                                ),
                              );
                            }).toList(growable: false)
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Row(
                              children: [
                                GestureDetector(
                                    onTap: () {
                                      if (battle.yellowMoveNotifier.value != null) {
                                        return;
                                      }
                                      int rot = battle.moveRotationNotifier.value;
                                      rot -= 1;
                                      rot %= 4;
                                      battle.moveRotationNotifier.value = rot;
                                    },
                                    child: Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                            borderRadius: BorderRadius.all(Radius.circular(999)),
                                            border: Border.all(
                                              color: Colors.black,
                                              width: BoardTile.EDGE_WIDTH,
                                            ),
                                            color: Color.fromRGBO(109, 161, 198, 1)
                                        ),
                                        child: Center(
                                          child: buildTextWidget("L")
                                        )
                                    )
                                ),
                                Container(
                                  width: 10,
                                ),
                                GestureDetector(
                                    onTap: () {
                                      if (battle.yellowMoveNotifier.value != null) {
                                        return;
                                      }
                                      int rot = battle.moveRotationNotifier.value;
                                      rot += 1;
                                      rot %= 4;
                                      battle.moveRotationNotifier.value = rot;
                                    },
                                    child: Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                            borderRadius: BorderRadius.all(Radius.circular(999)),
                                            border: Border.all(
                                              color: Colors.black,
                                              width: BoardTile.EDGE_WIDTH,
                                            ),
                                            color: Color.fromRGBO(109, 161, 198, 1)
                                        ),
                                        child: Center(
                                            child: buildTextWidget("R")
                                        )
                                    )
                                ),
                              ]
                          ),
                          GestureDetector(
                              onTap: () {
                                if (battle.yellowMoveNotifier.value != null) {
                                  return;
                                }
                                battle.moveCardNotifier.value = null;
                                battle.moveLocationNotifier.value = null;
                                battle.movePassNotifier.value = !battle.movePassNotifier.value;
                                battle.moveSpecialNotifier.value = false;
                              },
                              child: AnimatedBuilder(
                                  animation: battle.movePassNotifier,
                                  builder: (_, __) => Container(
                                      decoration: BoxDecoration(
                                        color: battle.movePassNotifier.value
                                            ? palette.buttonSelected
                                            : palette.buttonUnselected,
                                        borderRadius: BorderRadius.all(Radius.circular(4)),
                                        border: Border.all(
                                          width: BoardTile.EDGE_WIDTH,
                                          color: Colors.black,
                                        ),
                                      ),
                                      height: 80,
                                      width: 64,
                                      child: Scaffold(
                                        backgroundColor: Colors.transparent,
                                        body: Center(
                                            child: buildTextWidget("Pass")
                                        ),
                                      )
                                  )
                              )
                          ),
                          GestureDetector(
                              onTap: () {
                                if (battle.yellowMoveNotifier.value != null) {
                                  return;
                                }
                                battle.moveSpecialNotifier.value = !battle.moveSpecialNotifier.value;
                                battle.movePassNotifier.value = false;
                              },
                              child: AnimatedBuilder(
                                  animation: battle.moveSpecialNotifier,
                                  builder: (_, __) => Container(
                                      decoration: BoxDecoration(
                                        color: battle.moveSpecialNotifier.value
                                            ? Color.fromRGBO(216, 216, 0, 1)
                                            : Color.fromRGBO(109, 161, 198, 1),
                                        borderRadius: BorderRadius.all(Radius.circular(4)),
                                        border: Border.all(
                                          width: BoardTile.EDGE_WIDTH,
                                          color: Colors.black,
                                        ),
                                      ),
                                      height: 80,
                                      width: 64,
                                      child: buildTextWidget("Special"),
                                  )
                              )
                          ),
                          //Container(height: 1)
                        ]
                      ),
                      //const Spacer(),
                      //SpeenWidget(),
                      Container(
                        margin: EdgeInsets.only(left: 15),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            CardSelectionWidget(
                              battle: battle,
                              moveNotifier: battle.blueMoveNotifier,
                              tileColour: palette.tileBlue,
                              tileSpecialColour: palette.tileBlueSpecial,
                            ),
                            CardSelectionConfirmButton(
                              battle: battle
                            )
                          ]
                        ),
                      )
                    ]
                  ),
                ),
              ],
            ),
          ),
        ),
        /*
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => GoRouter.of(context).pop(),
              // onPressed: _drawAllMoves,
              child: const Text('Back'),
            ),
          ),
        ),
        */
        Container(
          height: 25,
        )
      ],
    );
  }
}

class BoardWidget extends StatelessWidget {
  final TableturfBattle battle;

  const BoardWidget(this.battle, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final boardState = battle.board;
    final boardTileStep = BoardTile.SIDE_LEN - BoardTile.EDGE_WIDTH;
    return Stack(
      children: boardState.asMap().entries.expand((entry) {
        int y = entry.key;
        var row = entry.value;
        return row.asMap().entries.map((entry) {
          int x = entry.key;
          var tile = entry.value;
          return Positioned(
            top: y * boardTileStep,
            left: x * boardTileStep,
            child: BoardTile(tile)
          );
        }).toList(growable: false);
      }).toList(growable: false)
    );
  }
}

class MoveOverlayWidget extends StatelessWidget {
  final TableturfBattle battle;

  const MoveOverlayWidget(this.battle);

  void _updateLocation(PointerEvent details) {
    if (battle.yellowMoveNotifier.value != null) {
      return;
    }
    final board = battle.board;
    final newLocation = details.localPosition;
    final boardTileStep = BoardTile.SIDE_LEN - BoardTile.EDGE_WIDTH;
    final newX = (newLocation.dx / boardTileStep).floor();
    final newY = (newLocation.dy / boardTileStep).floor();
    if (
      newY < 0 ||
        newY >= board.length ||
        newX < 0 ||
        newX >= board[0].length
    ) {
      battle.moveLocationNotifier.value = null;
    } else {
      battle.moveLocationNotifier.value = Coords(newX, newY);
    }
  }

  @override
  Widget build(BuildContext context) {
    final board = battle.board;
    final boardTileStep = BoardTile.SIDE_LEN - BoardTile.EDGE_WIDTH;
    final boardHeight = board.length * boardTileStep + BoardTile.EDGE_WIDTH;
    final boardWidth = board[0].length * boardTileStep + BoardTile.EDGE_WIDTH;

    final overlayWidget = ValueListenableBuilder(
      valueListenable: battle.moveCardNotifier,
      builder: (_, TableturfCard? card, __) {
        if (card == null) {
          return Container();
        }
        return ValueListenableBuilder(
          valueListenable: battle.moveRotationNotifier,
          builder: (_, int rot, __) {
            final pattern = rotatePattern(
              card.minPattern,
              rot
            );
            final selectPoint = rotatePatternPoint(
              card.selectPoint,
              card.minPattern.length,
              card.minPattern[0].length,
              rot
            );

            return ValueListenableBuilder(
              valueListenable: battle.moveLocationNotifier,
              child: ValueListenableBuilder(
                valueListenable: battle.moveHighlightNotifier,
                builder: (_, bool highlight, __) => ValueListenableBuilder(
                  valueListenable: battle.movePassNotifier,
                  builder: (_, bool isPassed, __) => ValueListenableBuilder(
                    valueListenable: battle.revealCardsNotifier,
                    builder: (_, bool isRevealed, __) {
                      if (isRevealed || isPassed) {
                        return Container();
                      }
                      return SizedBox(
                        height: pattern.length * boardTileStep + BoardTile.EDGE_WIDTH,
                        width: pattern[0].length * boardTileStep + BoardTile.EDGE_WIDTH,
                        child: Stack(
                            children: pattern.asMap().entries.expand((entry) {
                              int y = entry.key;
                              var row = entry.value;
                              return row.asMap().entries.map((entry) {
                                int x = entry.key;
                                var tile = entry.value;
                                late final colour;
                                if (battle.moveHighlightNotifier.value) {
                                  colour = tile == TileState.Yellow ? const Color.fromRGBO(255, 255, 17, 0.5)
                                      : tile == TileState.YellowSpecial ? const Color.fromRGBO(255, 159, 4, 0.5)
                                      : Color.fromRGBO(0, 0, 0, 0);
                                } else {
                                  colour = tile == TileState.Yellow ? const Color.fromRGBO(255, 255, 255, 0.5)
                                      : tile == TileState.YellowSpecial ? const Color.fromRGBO(192, 192, 192, 0.5)
                                      : Color.fromRGBO(0, 0, 0, 0);
                                }
                                return Positioned(
                                    top: y * boardTileStep,
                                    left: x * boardTileStep,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: colour,
                                        border: Border.all(
                                            width: BoardTile.EDGE_WIDTH,
                                            color: colour
                                        ),
                                      ),
                                      width: BoardTile.SIDE_LEN,
                                      height: BoardTile.SIDE_LEN,
                                    )
                                );
                              }).toList(growable: false);
                            }).toList(growable: false)
                        ),
                      );
                    }
                  )
                )
              ),
              builder: (ctx, Coords? location, child) {
                if (location == null) {
                  return Container();
                }
                final overlayY = clamp(location.y - selectPoint.y, 0, board.length - pattern.length);
                final overlayX = clamp(location.x - selectPoint.x, 0, board[0].length - pattern[0].length);

                return Container(
                  padding: EdgeInsets.fromLTRB(
                    overlayX * boardTileStep,
                    overlayY * boardTileStep,
                    0,
                    0
                  ),
                  child: child!,
                );
              }
            );
          }
        );
      }
    );

    return Listener(
      onPointerDown: _updateLocation,
      onPointerMove: _updateLocation,
      child: Container(
        decoration: BoxDecoration(
          color: Color.fromRGBO(0, 0, 0, 0)
        ),
        width: boardWidth,
        height: boardHeight,
        child: overlayWidget,
      ),
    );
  }
}

class BoardTile extends StatefulWidget {
  static const SIDE_LEN = 20.0;
  static const EDGE_WIDTH = 0.5;
  final TableturfTile tile;

  const BoardTile(this.tile, {super.key});

  @override
  State<BoardTile> createState() => _BoardTileState();
}

class _BoardTileState extends State<BoardTile>
    with SingleTickerProviderStateMixin {
  late AnimationController flashController;
  
  @override
  void initState() {
    flashController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this
    );
    widget.tile.addListener(_runFlash);
    super.initState();
  }

  void _runFlash() {
    flashController.reverse(from: 1.0);
    setState(() {});
  }

  @override
  void dispose() {
    widget.tile.removeListener(_runFlash);
    flashController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();
    final state = widget.tile.state;
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: state == TileState.Unfilled ? palette.tileUnfilled
                  : state == TileState.Wall ? palette.tileWall
                  : state == TileState.Yellow ? palette.tileYellow
                  : state == TileState.YellowSpecial ? palette.tileYellowSpecial
                  : state == TileState.Blue ? palette.tileBlue
                  : state == TileState.BlueSpecial ? palette.tileBlueSpecial
                  : Color.fromRGBO(0, 0, 0, 0),
            border: Border.all(
                width: BoardTile.EDGE_WIDTH,
                color: state == TileState.Empty
                    ? Color.fromRGBO(0, 0, 0, 0)
                    : palette.tileEdge
            ),
          ),
          width: BoardTile.SIDE_LEN,
          height: BoardTile.SIDE_LEN,
        ),
        FadeTransition(
          opacity: flashController,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
            ),
            height: BoardTile.SIDE_LEN + (BoardTile.EDGE_WIDTH * 2),
            width: BoardTile.SIDE_LEN + (BoardTile.EDGE_WIDTH * 2),
          )
        )
      ]
    );
  }
}

class CardPatternWidget extends StatelessWidget {
  static const TILE_SIZE = 8.0;
  static const TILE_EDGE = 0.5;

  final List<List<TileState>> pattern;
  final PlayerTraits traits;

  const CardPatternWidget(this.pattern, this.traits, {super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();
    final tileStep = TILE_SIZE - TILE_EDGE;

    return SizedBox(
      height: pattern.length * tileStep + TILE_EDGE,
      width: pattern[0].length * tileStep + TILE_EDGE,
      child: Stack(
        children: pattern.asMap().entries.expand((entry) {
          int y = entry.key;
          var row = entry.value;
          return row.asMap().entries.map((entry) {
            int x = entry.key;
            var tile = entry.value;
            return Positioned(
              top: y * tileStep,
              left: x * tileStep,
              child: Container(
                decoration: BoxDecoration(
                  color: tile == TileState.Unfilled ? palette.cardTileUnfilled
                         : tile == TileState.Yellow ? traits.normalColour
                         : tile == TileState.YellowSpecial ? traits.specialColour
                         : Colors.red,
                  border: Border.all(
                    width: TILE_EDGE,
                    color: palette.cardTileEdge,
                  ),
                ),
                width: TILE_SIZE,
                height: TILE_SIZE,
              )
            );
          }).toList(growable: false);
        }).toList(growable: false)
      ),
    );
  }
}

class SpeenWidget extends StatefulWidget {
  const SpeenWidget({super.key});

  @override
  State<SpeenWidget> createState() => _SpeenWidgetState();
}

class _SpeenWidgetState extends State<SpeenWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 1000)
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) {
        return Transform.rotate(
          angle: _controller.value * 2 * pi,
          child: child,
        );
      },
      child: Image.asset(
        "assets/images/loading.png",
        width: 48,
        height: 48,
      )
    );
  }
}

class CardWidget extends StatefulWidget {
  static final double CARD_HEIGHT = 110;
  static final double CARD_WIDTH = 80;
  final TableturfCard card;
  final TableturfBattle battle;

  const CardWidget({
    super.key,
    required this.card,
    required this.battle,
  });

  @override
  State<CardWidget> createState() => _CardWidgetState();
}

class _CardWidgetState extends State<CardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _transitionController;
  late Animation<double> transitionOutShrink, transitionOutFade, transitionInMove, transitionInFade;
  Widget _prevWidget = Container();

  @override
  void initState() {
    _transitionController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this
    );
    _transitionController.value = 1.0;
    transitionOutShrink = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(
      CurvedAnimation(
        parent: _transitionController,
        curve: Interval(
          0.0, 0.3,
          curve: Curves.linear,
        ),
      ),
    );
    transitionOutFade = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _transitionController,
        curve: Interval(
          0.0, 0.3,
          curve: Curves.linear,
        ),
      ),
    );
    transitionInFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _transitionController,
        curve: Interval(
          0.7, 1.0,
          curve: Curves.linear,
        ),
      ),
    );
    transitionInMove = Tween<double>(
      begin: 15,
      end: 0,
    ).animate(
      CurvedAnimation(
        parent: _transitionController,
        curve: Interval(
          0.7, 1.0,
          curve: Curves.linear,
        ),
      ),
    );
    super.initState();
  }

  @override
  void didUpdateWidget(CardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.card != widget.card
        && _transitionController.status == AnimationStatus.completed) {
      _runTransition(oldWidget);
    }
  }

  Future<void> _runTransition(CardWidget oldWidget) async {
    _prevWidget = oldWidget;
    try {
      await _transitionController
          .forward(from: 0.0)
          .orCancel;
    } catch (err) {

    }
    _prevWidget = Container();
  }

  @override
  void dispose() {
    _transitionController.dispose();
    super.dispose();
  }

  Widget _buildCard(BuildContext context, Color background) {
    final palette = context.watch<Palette>();
    final pattern = widget.card.pattern;

    return Container(
        decoration: BoxDecoration(
          color: background,
          border: Border.all(
            width: 1.0,
            color: palette.cardEdge,
          ),
        ),
        width: CardWidget.CARD_WIDTH,
        height: CardWidget.CARD_HEIGHT,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            CardPatternWidget(pattern, const YellowTraits()),
            Container(
              margin: EdgeInsets.only(left: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Material(
                    color: Colors.transparent,
                    child: Stack(
                      children: [
                        Container(
                            height: 24,
                            width: 24,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.all(Radius.circular(4)),
                            )
                        ),
                        SizedBox(
                            height: 24,
                            width: 24,
                            child: Center(
                                child: Text(
                                    widget.card.count.toString(),
                                    style: TextStyle(
                                        fontFamily: "Splatfont1",
                                        color: Colors.white,
                                        //fontStyle: FontStyle.italic,
                                        fontSize: 12,
                                        letterSpacing: 3.5
                                    )
                                )
                            )
                        )
                      ],
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(left: 3),
                    child: Row(
                        children: Iterable.generate(widget.card.special, (_) {
                          return Container(
                            margin: EdgeInsets.only(top: 4),
                            decoration: BoxDecoration(
                              color: palette.tileYellowSpecial,
                              border: Border.all(
                                width: CardPatternWidget.TILE_EDGE,
                                color: Colors.black,
                              ),
                            ),
                            width: CardPatternWidget.TILE_SIZE,
                            height: CardPatternWidget.TILE_SIZE,
                          );
                        }).toList(growable: false)
                    ),
                  )
                ],
              ),
            ),
          ],
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();
    final moveCardNotifier = widget.battle.moveCardNotifier;
    var reactiveCard = AnimatedBuilder(
      animation: moveCardNotifier,
      builder: (_, __) {
        return GestureDetector(
          child: moveCardNotifier.value == widget.card
            ? _buildCard(context, palette.cardBackgroundSelected)
            : _buildCard(context, palette.cardBackground),
          onTapDown: (details) {
            if (widget.battle.yellowMoveNotifier.value != null) {
              return;
            }
            moveCardNotifier.value = widget.card;
          }
        );
      }
    );
    return SizedBox(
      width: CardWidget.CARD_WIDTH,
      height: CardWidget.CARD_HEIGHT,
      child: AnimatedBuilder(
        animation: _transitionController,
        builder: (_, __) {
          return Stack(
            children: [
              Opacity(
                opacity: transitionOutFade.value,
                child: Transform.scale(
                  scale: transitionOutShrink.value,
                  child: _prevWidget,
                )
              ),
              Transform.translate(
                offset: Offset(0, transitionInMove.value),
                child: Opacity(
                  opacity: transitionInFade.value,
                  child: reactiveCard,
                )
              )
            ]
          );
        }
      ),
    );
  }
}

class CardSelectionWidget extends StatefulWidget {
  final ValueNotifier<TableturfMove?> moveNotifier;
  final TableturfBattle battle;
  final Color tileColour, tileSpecialColour;

  const CardSelectionWidget({
    super.key,
    required this.moveNotifier,
    required this.battle,
    required this.tileColour,
    required this.tileSpecialColour,
  });

  @override
  State<CardSelectionWidget> createState() => _CardSelectionWidgetState();
}

class _CardSelectionWidgetState extends State<CardSelectionWidget>
    with TickerProviderStateMixin {
  late AnimationController _confirmController;
  late AnimationController _flipController;
  late Animation<double> confirmMoveIn, confirmMoveOut, confirmFadeIn, confirmFadeOut;
  Widget _prevFront = Container();

  @override
  void initState() {
    super.initState();
    widget.moveNotifier.addListener(onMoveChange);
    widget.battle.revealCardsNotifier.addListener(onRevealCardsChange);
    _confirmController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    confirmMoveIn = Tween<double>(
      begin: -50,
      end: 0,
    ).animate(
        CurvedAnimation(
          parent: _confirmController,
          curve: Curves.easeInBack.flipped,
        )
    );
    confirmMoveOut = Tween<double>(
      begin: 50,
      end: 0,
    ).animate(
        CurvedAnimation(
          parent: _confirmController,
          curve: Curves.linear,
        )
    );
    confirmFadeIn = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _confirmController,
        curve: Curves.linear,
      ),
    );
    confirmFadeOut = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _confirmController,
        curve: Interval(
          0.4, 1.0,
          curve: Curves.linear,
        ),
      ),
    );
  }

  @override
  void dispose() {
    widget.moveNotifier.removeListener(onMoveChange);
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> onMoveChange() async {
    if (widget.moveNotifier.value == null) {
      try {
        final fut = _confirmController.reverse(from: 1.0).orCancel;
        setState(() {});
        await fut;
      } catch (err) {}
      _flipController.value = 0.0;
    } else {
      final fut = _confirmController.forward(from: 0.0);
      setState(() {});
      await fut;
    }
  }

  void onRevealCardsChange() {
    final isRevealed = widget.battle.revealCardsNotifier.value;
    if (isRevealed) {
      _flipController.forward(from: 0.0);
      //setState(() {});
    }
  }

  Widget _buildAwaiting(BuildContext context) {
    final palette = context.watch<Palette>();
    return Container(
      decoration: BoxDecoration(
        color: Color.fromRGBO(32, 32, 32, 0.8),
        border: Border.all(
          width: 1.0,
          color: palette.cardEdge,
        ),
      ),
      width: CardWidget.CARD_WIDTH,
      height: CardWidget.CARD_HEIGHT,
      child: Center(child: SpeenWidget()),
    );
  }

  Widget _buildCardBack(BuildContext context) {
    final palette = context.watch<Palette>();
    return Container(
      decoration: BoxDecoration(
        color: palette.cardBackgroundSelected,
        border: Border.all(
          width: 1.0,
          color: palette.cardEdge,
        ),
      ),
      width: CardWidget.CARD_WIDTH,
      height: CardWidget.CARD_HEIGHT,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: buildTextWidget("Selected"),
        ),
      ),
    );
  }

  Widget _buildCardFront(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: widget.moveNotifier,
      builder: (_, TableturfMove? move, __) {
        final palette = context.watch<Palette>();
        if (move == null) {
          return _prevFront;
        }
        final background = !move.special
            ? palette.cardBackgroundSelected
            : Colors.red; //Color.fromRGBO(229, 229, 57, 1);
        final card = move.card;
        var cardFront = Container(
          decoration: BoxDecoration(
            color: background,
            border: Border.all(
              width: 1.0,
              color: palette.cardEdge,
            ),
          ),
          width: CardWidget.CARD_WIDTH,
          height: CardWidget.CARD_HEIGHT,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              CardPatternWidget(card.pattern, move.traits),
              Container(
                margin: EdgeInsets.only(left: 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: Stack(
                        children: [
                          Container(
                              height: 24,
                              width: 24,
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.all(Radius.circular(4)),
                              )
                          ),
                          SizedBox(
                              height: 24,
                              width: 24,
                              child: Center(
                                  child: Text(
                                      card.count.toString(),
                                      style: TextStyle(
                                          fontFamily: "Splatfont1",
                                          color: Colors.white,
                                          //fontStyle: FontStyle.italic,
                                          fontSize: 12,
                                          letterSpacing: 3.5
                                      )
                                  )
                              )
                          )
                        ],
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(left: 3),
                      child: Row(
                          children: Iterable.generate(card.special, (_) {
                            return Container(
                              margin: EdgeInsets.only(top: 4),
                              decoration: BoxDecoration(
                                color: move.traits.specialColour,
                                border: Border.all(
                                  width: CardPatternWidget.TILE_EDGE,
                                  color: Colors.black,
                                ),
                              ),
                              width: CardPatternWidget.TILE_SIZE,
                              height: CardPatternWidget.TILE_SIZE,
                            );
                          }).toList(growable: false)
                      ),
                    )
                  ],
                ),
              ),
            ],
          )
        );
        late final newFront;
        if (move.pass) {
          newFront = Stack(
            children: [
              cardFront,
              Container(
                height: CardWidget.CARD_HEIGHT,
                width: CardWidget.CARD_WIDTH,
                decoration: BoxDecoration(
                  color: Color.fromRGBO(0, 0, 0, 0.4),
                ),
                child: Center(
                  child: buildTextWidget("Pass")
                )
              )
            ]
          );
        } else {
          newFront = cardFront;
        }
        _prevFront = newFront;
        return newFront;
      }
    );
  }

  Widget _buildCard(BuildContext context) {
    final front = _buildCardFront(context);
    final back = _buildCardBack(context);
    return AnimatedBuilder(
      animation: _flipController,
      builder: (_, __) => FlipCard(
        skew: (1 - _flipController.value),
        front: front,
        back: back,
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (_confirmController.status) {
      case AnimationStatus.dismissed:
        return _buildAwaiting(context);
      case AnimationStatus.completed:
        return _buildCard(context);
      case AnimationStatus.forward:
        return Stack(
          children: [
            _buildAwaiting(context),
            AnimatedBuilder(
              animation: _confirmController,
              child: _buildCard(context),
              builder: (_, child) => Opacity(
                opacity: confirmFadeIn.value,
                child: Transform.translate(
                  offset: Offset(0, confirmMoveIn.value),
                  child: child
                )
              )
            )
          ]
        );
      case AnimationStatus.reverse:
        return Stack(
          children: [
            _buildAwaiting(context),
            AnimatedBuilder(
              animation: _confirmController,
              child: _buildCard(context),
              builder: (_, child) => Opacity(
                opacity: confirmFadeOut.value,
                child: Transform.translate(
                    offset: Offset(confirmMoveOut.value, 0),
                    child: child
                )
              )
            )
          ]
        );
    }
  }
}

class CardSelectionConfirmButton extends StatefulWidget {
  final TableturfBattle battle;

  const CardSelectionConfirmButton({
    super.key,
    required this.battle,
  });

  @override
  State<CardSelectionConfirmButton> createState() => _CardSelectionConfirmButtonState();
}

class _CardSelectionConfirmButtonState extends State<CardSelectionConfirmButton> {
  bool active = true;

  @override
  void initState() {
    super.initState();
    widget.battle.yellowMoveNotifier.addListener(onMoveChange);
  }

  @override
  void dispose() {
    widget.battle.yellowMoveNotifier.removeListener(onMoveChange);
    super.dispose();
  }

  void onMoveChange() {
    setState(() {
      active = widget.battle.yellowMoveNotifier.value == null;
    });
  }

  void _confirmMove() {
    final battle = widget.battle;
    if (!battle.moveHighlightNotifier.value) {
      return;
    }
    final card = battle.moveCardNotifier.value!;
    if (battle.movePassNotifier.value) {
      battle.yellowMoveNotifier.value = TableturfMove(
        card: card,
        rotation: 0,
        x: 0,
        y: 0,
        pass: battle.movePassNotifier.value,
        special: battle.moveSpecialNotifier.value,
      );
      return;
    }

    final location = battle.moveLocationNotifier.value!;
    final rot = battle.moveRotationNotifier.value;
    final pattern = rotatePattern(card.minPattern, rot);
    final selectPoint = rotatePatternPoint(
      card.selectPoint,
      card.minPattern.length,
      card.minPattern[0].length,
      rot,
    );
    battle.yellowMoveNotifier.value = TableturfMove(
      card: card,
      rotation: rot,
      x: clamp(
        location.x - selectPoint.x,
        0,
        battle.board[0].length - pattern[0].length
      ),
      y: clamp(
        location.y - selectPoint.y,
        0,
        battle.board.length - pattern.length
      ),
      pass: battle.movePassNotifier.value,
      special: battle.moveSpecialNotifier.value,
    );
  }

  Widget _buildButton(BuildContext context) {
    final palette = context.watch<Palette>();
    return Container(
      decoration: BoxDecoration(
        color: palette.buttonSelected,
        border: Border.all(
          width: 1.0,
          color: palette.cardEdge,
        ),
      ),
      width: CardWidget.CARD_WIDTH,
      height: CardWidget.CARD_HEIGHT,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: buildTextWidget("Confirm"),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();
    final selectionWidget = CardSelectionWidget(
      battle: widget.battle,
      moveNotifier: widget.battle.yellowMoveNotifier,
      tileColour: palette.tileYellow,
      tileSpecialColour: palette.tileYellowSpecial,
    );
    return Stack(
      children: [
        selectionWidget,
        !active ? Container() : ValueListenableBuilder(
          valueListenable: widget.battle.moveHighlightNotifier,
          child: GestureDetector(
            onTap: _confirmMove,
            child: _buildButton(context),
          ),
          builder: (_, bool highlight, button) => AnimatedOpacity(
            opacity: highlight ? 1 : 0,
            duration: const Duration(milliseconds: 150),
            child: button,
          )
        )
      ]
    );
  }
}
