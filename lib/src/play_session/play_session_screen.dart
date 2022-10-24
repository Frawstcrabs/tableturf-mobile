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
import '../games_services/games_services.dart';
import '../games_services/score.dart';
import '../in_app_purchase/in_app_purchase.dart';
import '../level_selection/levels.dart';
import '../player_progress/player_progress.dart';
import '../style/confetti.dart';
import '../style/palette.dart';

import '../game_internals/card.dart';
import '../game_internals/tile.dart';


class PlaySessionScreen extends StatefulWidget {
  final TableturfBattle battle;

  const PlaySessionScreen(this.battle, {super.key});

  @override
  State<PlaySessionScreen> createState() => _PlaySessionScreenState();
}

class _PlaySessionScreenState extends State<PlaySessionScreen> {
  static final _log = Logger('PlaySessionScreenState');

  @override
  Widget build(BuildContext context) {
    final battle = widget.battle;
    final boardState = battle.board;
    final boardTileStep = BoardTile.SIDE_LEN - BoardTile.EDGE_WIDTH;
    final boardHeight = boardState.length * boardTileStep + BoardTile.EDGE_WIDTH;
    final boardWidth = boardState[0].length * boardTileStep + BoardTile.EDGE_WIDTH;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
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
        const Spacer(),
        SizedBox(
          height: 40,
          width: 40,
          child: SpeenWidget()
        ),
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
                    var randY;
                    var randX;
                    do {
                      randY = Random().nextInt(boardState.length);
                      randX = Random().nextInt(boardState[0].length);
                    } while (boardState[randY][randX].state == TileState.Empty);
                    final newState = ([
                      TileState.Yellow,
                      TileState.YellowSpecial,
                      TileState.Blue,
                      TileState.BlueSpecial,
                      TileState.Unfilled,
                    ]..remove(boardState[randY][randX]))[Random().nextInt(4)];
                    boardState[randY][randX].state = newState;
                  });
                },
                child: const Text('Change Tile'),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: battle.player1.hand.map((card) =>
            CardWidget(
              card: card,
              rotation: 0,
              moveCardNotifier: battle.moveCardNotifier,
            )
          ).toList(growable: false)
        ),
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

    final overlayWidget = AnimatedBuilder(
      animation: battle.moveCardNotifier,
      builder: (_, __) {
        final card = battle.moveCardNotifier.value;
        if (card == null) {
          return Container();
        }
        return AnimatedBuilder(
          animation: battle.moveRotationNotifier,
          builder: (_, __) {
            final rot = battle.moveRotationNotifier.value;
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
            //print("rot $rot: select point is $selectPoint");

            return AnimatedBuilder(
              animation: battle.moveLocationNotifier,
              child: AnimatedBuilder(
                animation: battle.moveHighlightNotifier,
                builder: (_, __) => SizedBox(
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
                )
              ),
              builder: (ctx, child) {
                final location = battle.moveLocationNotifier.value;
                if (location == null) {
                  return Container();
                }
                //print("select point is $selectPoint");
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

  const CardPatternWidget(this.pattern, {super.key});

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
                         : tile == TileState.Yellow ? palette.tileYellow
                         : tile == TileState.YellowSpecial ? palette.tileYellowSpecial
                         : Color.fromRGBO(0, 0, 0, 0),
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
    duration: Duration(seconds: 2)
  )..repeat();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, child) {
            return Transform.rotate(
              angle: _controller.value * 2 * pi,
              child: child,
            );
          },
          child: FlutterLogo(size: 40),
        ),
      ),
    );
  }
}


class CardWidget extends StatelessWidget {
  final TableturfCard card;
  final int rotation;
  final ValueNotifier<TableturfCard?> moveCardNotifier;

  const CardWidget({
    super.key,
    required this.card,
    required this.rotation,
    required this.moveCardNotifier,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();
    final pattern = rotatePattern(card.pattern, rotation);

    var cardWidget = Container(
      decoration: BoxDecoration(
        color: palette.cardBackground,
        border: Border.all(
          width: 1.0,
          color: palette.cardEdge,
        ),
      ),
      width: 80,
      height: 110,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          CardPatternWidget(pattern),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Material(
                color: Colors.transparent,
                child: Container(
                  height: 24,
                  width: 24,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                  ),
                  child: Center(
                    child: Text(
                      card.count.toString(),
                      style: TextStyle(
                        fontFamily: "Splatfont1",
                        color: Colors.white,
                        //fontStyle: FontStyle.italic,
                        fontSize: 12
                      )
                    )
                  )
                ),
              ),
              Row(
                children: Iterable<int>.generate(card.special).map((_) {
                  return Container(
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
              )
            ],
          ),
        ],
      )
    );
    var inactiveWidget = Stack(
      children: [
        cardWidget,
        Container(
          width: 80,
          height: 110,
          decoration: BoxDecoration(
              color: Color.fromRGBO(0, 0, 0, 0.4)
          ),
        )
      ]
    );
    return AnimatedBuilder(
      animation: moveCardNotifier,
      builder: (_, __) {
        return GestureDetector(
          child: moveCardNotifier.value == card ? inactiveWidget : cardWidget,
          onTapDown: (details) {
            moveCardNotifier.value = card;
          }
        );
      }
    );
  }
}
