// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import 'card.dart';
import 'tile.dart';
import 'move.dart';
import 'player.dart';

TileGrid rotatePattern(TileGrid pattern, int rotation) {
  TileGrid ret = [];
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
      return Coords(height-point.y - 1, point.x);
    case 2:
      return Coords(width-point.x - 1, height-point.y - 1);
    case 3:
      return Coords(point.y, width-point.x - 1);
    default:
      throw Exception("invalid rotation value: $rot");
  }
}

int clamp(int x, int _min, int _max) {
  return min(_max, max(_min, x));
}

Iterable<TableturfMove> getMoves(BoardGrid board, TableturfCard card, {bool special = false}) sync* {
  for (var rot = 0; rot < 4; rot++) {
    var pattern = rotatePattern(card.minPattern, rot);
    for (var moveY = 0; moveY < board.length - pattern.length; moveY++) {
      for (var moveX = 0; moveX < board[0].length - pattern[0].length; moveX++) {
        final move = TableturfMove(
          card: card,
          rotation: rot,
          x: moveX,
          y: moveY,
          special: special,
        );
        if (moveIsValid(board, move)) {
          yield move;
        }
      }
    }
  }
}

bool moveIsValid(BoardGrid board, TableturfMove move) {
  if (!move.special) {
    return _normalMoveIsValid(board, move);
  } else {
    return _specialMoveIsValid(board, move);
  }
}

bool _normalMoveIsValid(BoardGrid board, TableturfMove move) {
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

bool _specialMoveIsValid(BoardGrid board, TableturfMove move) {
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

BoardGrid _flipBoard(BoardGrid board) {
  BoardGrid ret = [];
  for (var y = board.length - 1; y >= 0; y--) {
    ret.add([]);
    for (var x = board[0].length - 1; x >= 0; x--) {
      //print("Getting pattern[$y][$x]");
      ret.last.add(TableturfTile({
        TileState.Empty: TileState.Empty,
        TileState.Unfilled: TileState.Unfilled,
        TileState.Wall: TileState.Wall,
        TileState.Yellow: TileState.Blue,
        TileState.YellowSpecial: TileState.BlueSpecial,
        TileState.Blue: TileState.Yellow,
        TileState.BlueSpecial: TileState.YellowSpecial,
      }[board[y][x].state]!));
    }
  }
  return ret;
}

Iterable<T> joinIterators<T>(Iterable<Iterable<T>> iters) {
  Iterable<T> ret = Iterable.empty();
  for (final iter in iters) {
    ret = ret.followedBy(iter);
  }
  return ret;
}

double _rateMove(BoardGrid board, TableturfMove move) {
  return Random().nextDouble();
}

TableturfMove _runBlueAI(List<dynamic> args) {
  print("${DateTime.now()}: rating moves...");
  final TileGrid plainBoard = args[0];
  final board = _flipBoard(plainBoard.map((row) => row.map((t) => TableturfTile(t)).toList()).toList());
  final TableturfPlayer player = args[1];
  final moves = Iterable.generate(4, (i) =>
    TableturfMove(
      card: player.hand[i],
      rotation: 0,
      x: 0,
      y: 0,
      pass: true,
      traits: YellowTraits(),
    )
  ).followedBy(
    joinIterators(
      player.hand
        .map((card) => getMoves(board, card, special: false))
    )
  ).followedBy(
    joinIterators(
      player.hand
        .where((card) => card.special <= player.special.value)
        .map((card) => getMoves(board, card, special: true))
    )
  ).iterator;
  var moveCount = 1;
  moves.moveNext();
  var bestMove = moves.current;
  var bestMoveRating = _rateMove(board, bestMove);
  while (moves.moveNext()) {
    moveCount += 1;
    var nextMove = moves.current;
    var nextMoveRating = _rateMove(board, nextMove);
    if (nextMoveRating > bestMoveRating) {
      bestMove = nextMove;
      bestMoveRating = nextMoveRating;
    }
  }
  print("${DateTime.now()}: went through $moveCount moves");
  final newRot = const [2, 3, 0, 1][bestMove.rotation];
  final pattern = rotatePattern(bestMove.card.minPattern, newRot);
  return TableturfMove(
    card: bestMove.card,
    rotation: newRot,
    x: (board[0].length - 1) - bestMove.x - pattern[0].length + 1,
    y: (board.length - 1) - bestMove.y - pattern.length + 1,
    pass: bestMove.pass,
    special: bestMove.special,
    traits: const BlueTraits(),
  );
}

class TableturfBattle {
  static final _log = Logger('TableturfBattle');
  final ValueNotifier<TableturfCard?> moveCardNotifier = ValueNotifier(null);
  final ValueNotifier<Coords?> moveLocationNotifier = ValueNotifier(null);
  final ValueNotifier<int> moveRotationNotifier = ValueNotifier(0);
  final ValueNotifier<bool> moveSpecialNotifier = ValueNotifier(false);
  final ValueNotifier<bool> movePassNotifier = ValueNotifier(false);
  final ValueNotifier<bool> moveHighlightNotifier = ValueNotifier(false);

  final ValueNotifier<bool> revealCardsNotifier = ValueNotifier(false);
  final ValueNotifier<bool> playerControlLock = ValueNotifier(true);

  final ValueNotifier<TableturfMove?> blueMoveNotifier = ValueNotifier(null);
  final ValueNotifier<TableturfMove?> yellowMoveNotifier = ValueNotifier(null);

  final ValueNotifier<int> yellowCountNotifier = ValueNotifier(1);
  final ValueNotifier<int> blueCountNotifier = ValueNotifier(1);
  final ValueNotifier<int> turnCountNotifier = ValueNotifier(12);

  final TableturfPlayer player1;
  final TableturfPlayer player2;

  final BoardGrid board;

  TableturfBattle({
    required this.player1,
    required this.player2,
    required this.board,
  }) {
    moveCardNotifier.addListener(_updateMoveHighlight);
    moveLocationNotifier.addListener(_updateMoveHighlight);
    moveRotationNotifier.addListener(_updateMoveHighlight);
    movePassNotifier.addListener(_updateMoveHighlight);
    moveSpecialNotifier.addListener(_updateMoveHighlight);
    yellowMoveNotifier.addListener(_checkMovesSet);
    blueMoveNotifier.addListener(_checkMovesSet);
  }

  void dispose() {
    moveCardNotifier.removeListener(_updateMoveHighlight);
    moveLocationNotifier.removeListener(_updateMoveHighlight);
    moveRotationNotifier.removeListener(_updateMoveHighlight);
    moveSpecialNotifier.removeListener(_updateMoveHighlight);
    yellowMoveNotifier.removeListener(_checkMovesSet);
    blueMoveNotifier.removeListener(_checkMovesSet);
  }

  void _updateMoveHighlight() {
    final card = moveCardNotifier.value;
    final rot = moveRotationNotifier.value;
    final location = moveLocationNotifier.value;
    final special = moveSpecialNotifier.value;
    final pass = movePassNotifier.value;
    if (pass) {
      moveHighlightNotifier.value = card != null;
    }
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
      moveHighlightNotifier.value = moveIsValid(board, move);
    }
  }

  Future<void> _checkMovesSet() async {
    if (yellowMoveNotifier.value != null && blueMoveNotifier.value != null) {
      await Future<void>.delayed(const Duration(milliseconds: 1000));
      await runTurn();
    }
  }

  Future<void> runTurn() async {
    print("turn triggered");
    revealCardsNotifier.value = true;
    await Future<void>.delayed(const Duration(milliseconds: 1000));

    // apply moves to board
    final blueMove = blueMoveNotifier.value!;
    final yellowMove = yellowMoveNotifier.value!;

    _applyMoveToBoard(blueMove);
    _applyMoveToBoard(yellowMove);

    if (!(blueMove.pass && yellowMove.pass)) {
      await Future<void>.delayed(const Duration(milliseconds: 1000));
    }

    moveLocationNotifier.value = null;
    moveCardNotifier.value = null;
    moveRotationNotifier.value = 0;
    movePassNotifier.value = false;
    moveSpecialNotifier.value = false;
    moveHighlightNotifier.value = false;
    yellowMoveNotifier.value = null;
    blueMoveNotifier.value = null;
    revealCardsNotifier.value = false;
    runBlueAI();
  }

  void _applyMoveToBoard(TableturfMove move) {
    if (!move.pass) {
      var pattern = rotatePattern(
          move.card.minPattern, move.rotation);
      for (var y = 0; y < pattern.length; y++) {
        for (var x = 0; x < pattern[0].length; x++) {
          final cardTile = pattern[y][x];
          final boardTile = board[y + move.y][x + move.x];
          if (cardTile == TileState.Yellow) {
            boardTile.state = move.traits.normalTile;
          } else if (cardTile == TileState.YellowSpecial) {
            boardTile.state = move.traits.specialTile;
          }
        }
      }
    }
  }

  Future<void> runBlueAI() async {
    final plainBoard = board.map((row) => row.map((t) => t.state).toList()).toList();
    final TableturfMove blueMove = (await Future.wait([
      compute(_runBlueAI, [plainBoard, player2]),
      Future.delayed(Duration(milliseconds: 1500 + Random().nextInt(500)))
    ]))[0];
    blueMoveNotifier.value = blueMove;
  }
}
