import 'dart:math';

import 'package:flutter/material.dart';

import '../game_internals/battle.dart';
import 'board_widget.dart';
import 'move_overlay.dart';

/**
 * Builds the widget representing the board and move overlay
 * Mostly just to keep all this in one place since this
 * needs to be built across 3 different pages
 */
Widget buildBoardWidget({
  required TableturfBattle battle,
  Key? key,
  void Function(double)? onTileSize,
  required bool loopAnimation,
  required String boardHeroTag,
}) {
  final boardBuilder = LayoutBuilder(
    builder: (context, constraints) {
      final mediaQuery = MediaQuery.of(context);
      final board = battle.board;
      final height = constraints.maxHeight.isFinite ? constraints.maxHeight : mediaQuery.size.height;
      final width = constraints.maxWidth.isFinite ? constraints.maxWidth : mediaQuery.size.width;
      final boardTileSize = min(
        min(
          height / board.length,
          (mediaQuery.size.height * 0.95) / board.length,
        ),
        min(
          width / board[0].length,
          (mediaQuery.size.width * 0.95) / board[0].length,
        )
      );

      onTileSize?.call(boardTileSize);

      return Center(
        child: SizedBox(
          key: key,
          height: board.length * boardTileSize,
          width: board[0].length * boardTileSize,
          child: Stack(
            children: [
              BoardWidget(
                battle,
                tileSize: boardTileSize,
              ),
              MoveOverlayWidget(
                battle,
                tileSize: boardTileSize,
                loopAnimation: loopAnimation,
              ),
            ],
          ),
        ),
      );
    },
  );
  return Hero(
    tag: boardHeroTag,
    createRectTween: (begin, end) => RectTween(begin: begin, end: end),
    flightShuttleBuilder: (flightContext, animation, direction, srcContext, destContext) {
      // by default hero just uses the child in the destination context, but that means
      // the board won't change in size as it moves between pages, which we want
      // this makes it so the in-flight board is in the flight context, which does
      // change size between page
      //print("Building flight of screen $flightIdentifier");
      return boardBuilder;
    },
    child: boardBuilder,
  );
}