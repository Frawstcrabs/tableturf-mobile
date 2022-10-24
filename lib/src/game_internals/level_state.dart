// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';
import 'package:flutter/foundation.dart';

import 'card.dart';
import 'tile.dart';
import 'move.dart';
import 'player.dart';

List<List<TileState>> rotatePattern(List<List<TileState>> pattern, int rotation) {
  List<List<TileState>> ret = [];
  rotation %= 4;

  final lengthY = pattern.length;
  final lengthX = pattern[0].length;

  switch (rotation) {
    case 0:
      for (var y = 0; y < lengthY; y++) {
        ret.add([]);
        for (var x = 0; x < lengthX; x++) {
          //print("Getting pattern[$y][$x]");
          ret.last.add(pattern[y][x]);
        }
      }
      break;
    case 1:
      for (var y = 0; y < lengthX; y++) {
        ret.add([]);
        for (var x = lengthY - 1; x >= 0; x--) {
          //for (var x = lengthX - 1; x >= 0; x--) {
          //print("Getting pattern[$x][$y]");
          ret.last.add(pattern[x][y]);
        }
      }
      break;
    case 2:
      for (var y = lengthY - 1; y >= 0; y--) {
        ret.add([]);
        for (var x = lengthX - 1; x >= 0; x--) {
          //for (var x = lengthX - 1; x >= 0; x--) {
          //print("Getting pattern[$y][$x]");
          ret.last.add(pattern[y][x]);
        }
      }
      break;
    case 3:
      for (var y = lengthX - 1; y >= 0; y--) {
        ret.add([]);
        for (var x = 0; x < lengthY; x++) {
          //for (var x = lengthX - 1; x >= 0; x--) {
          //print("Getting pattern[$x][$y]");
          ret.last.add(pattern[x][y]);
        }
      }
      break;
  }
  return ret;
}

Coords rotatePatternPoint(Coords point, int height, int width, int rot) {
  switch (rot) {
    case 0:
      return point;
    case 1:
      return Coords(point.y + (width % 2 == 1 ? 1 : 0), width-point.x - 1 - (height % 2 == 1 ? 1 : 0));
    case 2:
      return Coords(width-point.x - 1, height-point.y - 1);
    case 3:
      return Coords(height-point.y - 1 - (width % 2 == 1 ? 1 : 0), point.x + (height % 2 == 1 ? 1 : 0));
    default:
      throw Exception("invalid rotation value: $rot");
  }
}

int clamp(int x, int _min, int _max) {
  return min(_max, max(_min, x));
}

class TableturfBattle {
  final ValueNotifier<TableturfCard?> moveCardNotifier = ValueNotifier(null);
  final ValueNotifier<Coords?> moveLocationNotifier = ValueNotifier(null);
  final ValueNotifier<int> moveRotationNotifier = ValueNotifier(0);
  final ValueNotifier<bool> moveHighlightNotifier = ValueNotifier(false);
  final ValueNotifier<bool> moveSpecialNotifier = ValueNotifier(false);
  final ValueNotifier<bool> movePassNotifier = ValueNotifier(false);

  final TableturfPlayer player1;
  final TableturfPlayer player2;

  final List<List<TableturfTile>> board;

  TableturfBattle({
    required this.player1,
    required this.player2,
    required this.board,
  }) {
    moveCardNotifier.addListener(_updateMoveHighlight);
    moveLocationNotifier.addListener(_updateMoveHighlight);
    moveRotationNotifier.addListener(_updateMoveHighlight);
    moveSpecialNotifier.addListener(_updateMoveHighlight);
  }

  void dispose() {
    moveCardNotifier.removeListener(_updateMoveHighlight);
    moveLocationNotifier.removeListener(_updateMoveHighlight);
    moveRotationNotifier.removeListener(_updateMoveHighlight);
    moveSpecialNotifier.removeListener(_updateMoveHighlight);
  }

  void _updateMoveHighlight() {
    final card = moveCardNotifier.value;
    final rot = moveRotationNotifier.value;
    final location = moveLocationNotifier.value;
    final special = moveSpecialNotifier.value;
    if (location != null
        && card != null
        && moveCardNotifier.value != null) {
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
      final overlayY = clamp(
        location.y - selectPoint.y,
        0,
        board.length - pattern.length
      );
      final overlayX = clamp(
        location.x - selectPoint.x,
        0,
        board[0].length - pattern[0].length
      );
      final move = TableturfMove(
          card: card,
          rotation: rot,
          x: overlayX,
          y: overlayY,
          special: special
      );
      moveHighlightNotifier.value = moveIsValid(move);
    }
  }

  Iterable<TableturfMove> getMoves(TableturfCard card, {bool special = false}) sync* {
    for (var rot = 0; rot < 4; rot++) {
      var pattern = rotatePattern(card.minPattern, rot);
      for (var moveY = 0; moveY < board.length - pattern.length; moveY++) {
        for (var moveX = 0; moveX < board[0].length - pattern.length; moveX++) {
          final move = TableturfMove(
            card: card,
            rotation: rot,
            x: moveX,
            y: moveY,
            special: special,
          );
          if (moveIsValid(move)) {
            yield move;
          }
        }
      }
    }
  }

  bool moveIsValid(TableturfMove move) {
    if (!move.special) {
      return _normalMoveIsValid(move);
    } else {
      return _specialMoveIsValid(move);
    }
  }

  bool _normalMoveIsValid(TableturfMove move) {
    final pattern = rotatePattern(move.card.minPattern, move.rotation);
    final moveY = move.y;
    final moveX = move.x;

    bool isTouchingYellow = false;
    for (var y = 0; y < pattern.length; y++) {
      for (var x = 0; x < pattern[y].length; x++) {
        final TileState cardTile = pattern[y][x];
        if (cardTile != TileState.Unfilled && board[moveY + y][moveX + x].state != TileState.Unfilled) {
          return false;
        }
        if (!isTouchingYellow && cardTile != TileState.Unfilled) {
          for (var modY = -1; modY <= 1; modY++) {
            for (var modX = -1; modX <= 1; modX++) {
              final boardY = moveY + y + modY;
              final boardX = moveX + x + modX;
              if (boardY < 0 || boardY >= board.length || boardX < 0 || boardX >= board[0].length) {
                continue;
              }
              final TileState edgeTile = board[boardY][boardX].state;
              if (edgeTile == TileState.Yellow || edgeTile == TileState.YellowSpecial) {
                isTouchingYellow = true;
                break;
              }
            }
            if (isTouchingYellow) {
              break;
            }
          }
        }
      }
    }
    return isTouchingYellow;
  }

  bool _specialMoveIsValid(TableturfMove move) {
    final pattern = rotatePattern(move.card.minPattern, move.rotation);
    final moveY = move.y;
    final moveX = move.x;

    bool isTouchingYellow = false;
    for (var y = 0; y < pattern.length; y++) {
      for (var x = 0; x < pattern[y].length; x++) {
        final TileState cardTile = pattern[y][x];
        final TileState boardTile = board[moveY + y][moveX + x].state;
        if (cardTile != TileState.Unfilled
            && (boardTile == TileState.Empty
                || boardTile == TileState.Wall
                || boardTile == TileState.YellowSpecial
                || boardTile == TileState.BlueSpecial)) {
          return false;
        }
        if (!isTouchingYellow && cardTile != TileState.Unfilled) {
          for (var modY = -1; modY <= 1; modY++) {
            for (var modX = -1; modX <= 1; modX++) {
              final boardY = moveY + y + modY;
              final boardX = moveX + x + modX;
              if (boardY < 0 || boardY >= board.length || boardX < 0 || boardX >= board[0].length) {
                continue;
              }
              final TileState edgeTile = board[boardY][boardX].state;
              if (edgeTile == TileState.YellowSpecial) {
                isTouchingYellow = true;
                break;
              }
            }
            if (isTouchingYellow) {
              break;
            }
          }
        }
      }
    }
    return isTouchingYellow;
  }
}
