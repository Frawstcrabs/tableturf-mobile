import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game_internals/battle.dart';
import '../game_internals/card.dart';
import '../game_internals/tile.dart';

import 'boardwidget.dart';

class MoveOverlayWidget extends StatelessWidget {
  final TableturfBattle battle;
  final double tileSize;

  const MoveOverlayWidget(this.battle, {required this.tileSize});

  @override
  Widget build(BuildContext context) {
    final board = battle.board;
    final boardTileStep = tileSize - BoardTile.EDGE_WIDTH;
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
                                                  width: tileSize,
                                                  height: tileSize,
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
                      final overlayY = location.y - selectPoint.y;
                      final overlayX = location.x - selectPoint.x;

                      return Transform.translate(
                        offset: Offset(
                          overlayX * boardTileStep,
                          overlayY * boardTileStep
                        ),
                        child: child,
                      );
                    }
                );
              }
          );
        }
    );

    return IgnorePointer(
      child: overlayWidget
    );
  }
}