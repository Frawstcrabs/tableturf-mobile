import 'dart:math';

import 'package:flutter/material.dart';

import '../../game_internals/battle.dart';
import 'board_widget.dart';
import 'move_overlay.dart';

double getTileSize(double pixelSize, int tileCount, double edgeWidth) {
  final innerSize = (pixelSize - (edgeWidth * (tileCount + 1))) / tileCount;
  return innerSize + (edgeWidth * 2);
}

/**
 * Builds the widget representing the board and move overlay
 * Mostly just to keep all this in one place since this
 * needs to be built across 3 different pages
 */
Widget buildBoardWidget({required TableturfBattle battle, Key? key, void Function(double)? onTileSize}) {
  final boardBuilder = LayoutBuilder(
    builder: (context, constraints) {
      final mediaQuery = MediaQuery.of(context);
      final board = battle.board;
      final height = constraints.maxHeight.isFinite ? constraints.maxHeight : mediaQuery.size.height;
      final width = constraints.maxWidth.isFinite ? constraints.maxWidth : mediaQuery.size.width;
      final boardTileSize = min(
        min(
          getTileSize(height, board.length, BoardTile.EDGE_WIDTH),
          (mediaQuery.size.height * 0.95) / board.length,
        ),
        min(
          getTileSize(width, board[0].length, BoardTile.EDGE_WIDTH),
          (mediaQuery.size.width * 0.95) / board[0].length,
        )
      );

      onTileSize?.call(boardTileSize);

      return Center(
        child: SizedBox(
          key: key,
          height: board.length * (boardTileSize - BoardTile.EDGE_WIDTH) + BoardTile.EDGE_WIDTH,
          width: board[0].length * (boardTileSize - BoardTile.EDGE_WIDTH) + BoardTile.EDGE_WIDTH,
          child: Stack(
            children: [
              BoardWidget(
                battle,
                tileSize: boardTileSize,
              ),
              MoveOverlayWidget(
                battle,
                tileSize: boardTileSize,
              )
            ]
          ),
        )
      );
    }
  );
  return Hero(
    tag: "boardView",
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