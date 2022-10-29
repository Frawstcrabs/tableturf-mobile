import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game_internals/battle.dart';
import '../game_internals/card.dart';
import '../game_internals/tile.dart';

import 'boardwidget.dart';

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

  void _onPointerHover(PointerEvent details) {
    if (details.kind == PointerDeviceKind.mouse) {
      _updateLocation(details);
    }
  }

  void _onPointerMove(PointerEvent details) {
    _updateLocation(details);
  }

  void _onPointerDown(PointerEvent details) {
    if (details.kind == PointerDeviceKind.mouse) {
      battle.confirmMove();
    } else {
      _updateLocation(details);
    }
  }

  KeyEventResult _handleKeyPress(FocusNode node, RawKeyEvent event) {
    print("handle key");
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.keyQ) {
        battle.rotateLeft();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyE) {
        battle.rotateRight();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
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
                        valueListenable: battle.moveIsValidNotifier,
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
                                            if (battle.moveIsValidNotifier.value) {
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
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerHover: _onPointerHover,
      child: Container(
        decoration: BoxDecoration(
            color: Color.fromRGBO(0, 0, 0, 0)
        ),
        width: boardWidth,
        height: boardHeight,
        child: Focus(
          autofocus: true,
          onKey: _handleKeyPress,
          onFocusChange: (bool isFocused) {
            print("focus change: $isFocused");
            if (!isFocused) {
              FocusScope.of(context).requestFocus();
            }
          },
          child: overlayWidget,
        ),
      ),
    );
  }
}