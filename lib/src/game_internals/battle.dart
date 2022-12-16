// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import '../audio/audio_controller.dart';
import '../audio/songs.dart';
import '../audio/sounds.dart';

import 'opponentAI.dart';
import 'card.dart';
import 'tile.dart';
import 'move.dart';
import 'player.dart';

int clamp(int x, int _min, int _max) {
  return min(_max, max(_min, x));
}

class TableturfBattle {
  static final _log = Logger('TableturfBattle');

  final ValueNotifier<bool> revealCardsNotifier = ValueNotifier(false);
  final ChangeNotifier endOfGameNotifier = ChangeNotifier();
  final ChangeNotifier specialMoveNotifier = ChangeNotifier();

  final ValueNotifier<TableturfMove?> blueMoveNotifier = ValueNotifier(null);
  final ValueNotifier<TableturfMove?> yellowMoveNotifier = ValueNotifier(null);

  final ValueNotifier<int> yellowCountNotifier = ValueNotifier(1);
  final ValueNotifier<int> blueCountNotifier = ValueNotifier(1);
  final ValueNotifier<int> turnCountNotifier = ValueNotifier(12);
  int _yellowSpecialCount = 0, _blueSpecialCount = 0;

  final TableturfPlayer yellow;
  final TableturfPlayer blue;
  final AILevel aiLevel;

  final BoardGrid board;

  TableturfBattle({
    required this.yellow,
    required this.blue,
    required this.board,
    required this.aiLevel,
  }) {
    yellowMoveNotifier.addListener(_checkMovesSet);
    blueMoveNotifier.addListener(_checkMovesSet);
  }

  void dispose() {
    yellowMoveNotifier.removeListener(_checkMovesSet);
    blueMoveNotifier.removeListener(_checkMovesSet);
  }

  Future<void> _checkMovesSet() async {
    if (yellowMoveNotifier.value != null && blueMoveNotifier.value != null) {
      await Future<void>.delayed(const Duration(milliseconds: 1000));
      await runTurn();
    }
  }

  Future<void> runTurn() async {
    _log.info("turn triggered");
    final yellowMove = yellowMoveNotifier.value!;
    final blueMove = blueMoveNotifier.value!;
    final audioController = AudioController();

    if (yellowMove.special || blueMove.special) {
      audioController.playSfx(SfxType.specialCutIn);
      specialMoveNotifier.notifyListeners();
      await Future<void>.delayed(const Duration(milliseconds: 1600));
    }
    await audioController.playSfx(SfxType.cardFlip);
    revealCardsNotifier.value = true;
    yellowMove.card.hasBeenPlayed = true;
    blueMove.card.hasBeenPlayed = true;
    yellow.special.value -= yellowMove.special ? yellowMove.card.special : 0;
    blue.special.value -= blueMove.special ? blueMove.card.special : 0;
    await Future<void>.delayed(const Duration(milliseconds: 1000));


    // apply moves to board
    if (blueMove.pass && yellowMove.pass) {
      _log.info("no move");

    } else if (blueMove.pass && !yellowMove.pass) {
      _log.info("yellow move only");
      await audioController.playSfx(yellowMove.special ? SfxType.specialMove : SfxType.normalMove);
      applyMoveToBoard(board, yellowMove);

    } else if (!blueMove.pass && yellowMove.pass) {
      _log.info("blue move only");
      await audioController.playSfx(blueMove.special ? SfxType.specialMove : SfxType.normalMove);
      applyMoveToBoard(board, blueMove);

    } else if (!_checkOverlap(blueMove, yellowMove)) {
      _log.info("no overlap");
      await audioController.playSfx(yellowMove.special || blueMove.special ? SfxType.specialMove : SfxType.normalMove);
      applyMoveToBoard(board, blueMove);
      applyMoveToBoard(board, yellowMove);

    } else if (blueMove.special && !yellowMove.special) {
      _log.info("blue special over yellow");
      await _applyOverlap(below: yellowMove, above: blueMove);

    } else if (yellowMove.special && !blueMove.special) {
      _log.info("yellow special over blue");
      await _applyOverlap(below: blueMove, above: yellowMove);

    } else if (blueMove.card.count < yellowMove.card.count) {
      _log.info("blue normal over yellow");
      await _applyOverlap(below: yellowMove, above: blueMove);

    } else if (yellowMove.card.count < blueMove.card.count) {
      _log.info("yellow normal over blue");
      await _applyOverlap(below: blueMove, above: yellowMove);

    } else {
      _log.info("conflict");
      await _applyConflict(blueMove, yellowMove);
    }

    await Future<void>.delayed(const Duration(milliseconds: 1000));

    final prevYellowSpecialCount = _yellowSpecialCount;
    final prevBlueSpecialCount = _blueSpecialCount;
    _countSpecial();
    if (_yellowSpecialCount != prevYellowSpecialCount || _blueSpecialCount != prevBlueSpecialCount) {
      audioController.playSfx(SfxType.specialActivate);
      await Future<void>.delayed(const Duration(milliseconds: 1000));
    }
    final prevYellowSpecial = yellow.special.value;
    final prevBlueSpecial = blue.special.value;
    yellow.special.value += (_yellowSpecialCount - prevYellowSpecialCount) + (yellowMove.pass ? 1 : 0);
    blue.special.value += (_blueSpecialCount - prevBlueSpecialCount) + (blueMove.pass ? 1 : 0);

    if (turnCountNotifier.value == 1) {
      endOfGameNotifier.notifyListeners();
      return;
    }
    if (yellow.special.value != prevYellowSpecial || blue.special.value != prevBlueSpecial) {
      audioController.playSfx(SfxType.gainSpecial);
    }

    final prevYellowCount = yellowCountNotifier.value;
    final prevBlueCount = blueCountNotifier.value;
    countBoard();

    if (yellowCountNotifier.value != prevYellowCount || blueCountNotifier.value != prevBlueCount) {
      await audioController.playSfx(SfxType.counterUpdate);
    }
    if (turnCountNotifier.value == 4) {
      () async {
        await audioController.stopSong(fadeDuration: const Duration(milliseconds: 1800));
        await Future<void>.delayed(const Duration(milliseconds: 200));
        await audioController.playSong(SongType.last3Turns);
      }();
    }
    await Future<void>.delayed(const Duration(milliseconds: 1500));

    revealCardsNotifier.value = false;

    yellowMoveNotifier.value = null;
    blueMoveNotifier.value = null;
    await Future<void>.delayed(const Duration(milliseconds: 100));
    yellow.refreshHand();
    blue.refreshHand();
    await Future<void>.delayed(const Duration(milliseconds: 200));
    turnCountNotifier.value -= 1;
    await Future<void>.delayed(const Duration(milliseconds: 1000));

    for (final cardNotifier in yellow.hand) {
      final card = cardNotifier.value!;
      card.isPlayable = getMoves(board, card, special: false).isNotEmpty;
      card.isPlayableSpecial = card.special <= yellow.special.value && getMoves(board, card, special: true).isNotEmpty;
    }
    runBlueAI();
    //runYellowAI();
    _log.info("turn complete");
  }

  bool _checkOverlap(TableturfMove move1, TableturfMove move2) {
    final relativePoint = Coords(
        move1.x - move2.x,
        move1.y - move2.y
    );
    final fromPattern = rotatePattern(move1.card.minPattern, move1.rotation);
    final toPattern = rotatePattern(move2.card.minPattern, move2.rotation);
    for (var y = 0; y < fromPattern.length; y++) {
      for (var x = 0; x < fromPattern[0].length; x++) {
        final fromTile = fromPattern[y][x];
        final relativeX = relativePoint.x + x;
        final relativeY = relativePoint.y + y;
        if (relativeY >= 0
            && relativeY < toPattern.length
            && relativeX >= 0
            && relativeX < toPattern[0].length) {
          final toTile = toPattern[relativeY][relativeX];
          if (fromTile != TileState.unfilled && toTile != TileState.unfilled) {
            return true;
          }
        }
      }
    }
    return false;
  }

  Future<void> _applyOverlap({required TableturfMove below, required TableturfMove above}) async {
    final audioController = AudioController();
    await audioController.playSfx(below.special ? SfxType.specialMove : SfxType.normalMove);
    applyMoveToBoard(board, below);
    await Future<void>.delayed(const Duration(milliseconds: 1000));
    await audioController.playSfx(above.special ? SfxType.specialMove : SfxType.normalMoveOverlap);

    final relativePoint = Coords(
        above.x - below.x,
        above.y - below.y
    );
    final abovePattern = rotatePattern(above.card.minPattern, above.rotation);
    final belowPattern = rotatePattern(below.card.minPattern, below.rotation);
    for (var y = 0; y < abovePattern.length; y++) {
      for (var x = 0; x < abovePattern[0].length; x++) {
        final aboveTile = abovePattern[y][x];
        if (aboveTile == TileState.unfilled) {
          continue;
        }
        final boardTile = board[above.y + y][above.x + x];
        final relativeX = relativePoint.x + x;
        final relativeY = relativePoint.y + y;
        if (relativeY >= 0
            && relativeY < belowPattern.length
            && relativeX >= 0
            && relativeX < belowPattern[0].length) {
          final belowTile = belowPattern[relativeY][relativeX];
          if (belowTile == TileState.unfilled) {
            applySquare(boardTile, aboveTile, above.traits);
            continue;
          }
          final newTile = {
            TileState.yellow: {
              TileState.yellow: above.traits.normalTile,
              TileState.yellowSpecial: below.traits.specialTile,
            }[belowTile]!,
            TileState.yellowSpecial: above.traits.specialTile,
          }[aboveTile]!;
          if (boardTile.state.value != newTile) {
            boardTile.state.value = newTile;
          }
        } else {
          applySquare(boardTile, aboveTile, above.traits);
        }
      }
    }
  }

  Future<void> _applyConflict(TableturfMove move1, TableturfMove move2) async {
    void applyOneWay(TableturfMove above, TableturfMove below) {
      final relativePoint = Coords(
          above.x - below.x,
          above.y - below.y
      );
      final abovePattern = rotatePattern(above.card.minPattern, above.rotation);
      final belowPattern = rotatePattern(below.card.minPattern, below.rotation);
      for (var y = 0; y < abovePattern.length; y++) {
        for (var x = 0; x < abovePattern[0].length; x++) {
          final aboveTile = abovePattern[y][x];
          final boardTile = board[above.y + y][above.x + x];
          final relativeX = relativePoint.x + x;
          final relativeY = relativePoint.y + y;
          if (relativeY >= 0
              && relativeY < belowPattern.length
              && relativeX >= 0
              && relativeX < belowPattern[0].length) {
            final belowTile = belowPattern[relativeY][relativeX];
            if (aboveTile == TileState.unfilled) {
              applySquare(boardTile, belowTile, below.traits);
              continue;
            }
            if (belowTile == TileState.unfilled) {
              applySquare(boardTile, aboveTile, above.traits);
              continue;
            }
            boardTile.state.value = {
              TileState.yellow: {
                TileState.yellow: TileState.wall,
                TileState.yellowSpecial: below.traits.specialTile,
              }[belowTile]!,
              TileState.yellowSpecial: {
                TileState.yellow: above.traits.specialTile,
                TileState.yellowSpecial: TileState.wall,
              }[belowTile]!,
            }[aboveTile]!;
          } else {
            applySquare(boardTile, aboveTile, above.traits);
          }
        }
      }
    }
    final audioController = AudioController();
    await audioController.playSfx(SfxType.normalMoveConflict);
    applyOneWay(move1, move2);
    applyOneWay(move2, move1);
  }

  void countBoard() {
    var yellowCount = 0;
    var blueCount = 0;
    for (var y = 0; y < board.length; y++) {
      for (var x = 0; x < board[0].length; x++) {
        final boardTile = board[y][x].state.value;
        if (boardTile == TileState.yellow || boardTile == TileState.yellowSpecial) {
          yellowCount += 1;
        }if (boardTile == TileState.blue || boardTile == TileState.blueSpecial) {
          blueCount += 1;
        }
      }
    }
    yellowCountNotifier.value = yellowCount;
    blueCountNotifier.value = blueCount;
  }

  void _countSpecial() {
    _yellowSpecialCount = 0;
    _blueSpecialCount = 0;
    for (var y = 0; y < board.length; y++) {
      for (var x = 0; x < board[0].length; x++) {
        final boardTile = board[y][x];
        final boardTileState = boardTile.state.value;
        if (boardTileState.isSpecial) {
          bool surrounded = true;
          for (var dy = -1; dy <= 1; dy++) {
            for (var dx = -1; dx <= 1; dx++) {
              final newY = y + dy;
              final newX = x + dx;
              if (newY < 0 || newY >= board.length || newX < 0 || newX >= board[0].length) {
                continue;
              }
              final adjacentTile = board[newY][newX].state.value;
              if (!adjacentTile.isFilled) {
                surrounded = false;
                continue;
              }
            }
          }
          if (surrounded) {
            boardTile.specialIsActivated.value = true;
            if (boardTileState == TileState.yellowSpecial) {
              _yellowSpecialCount += 1;
            } else {
              _blueSpecialCount += 1;
            }
          }
        }
      }
    }
  }

  Future<void> runBlueAI() async {
    final TileGrid plainBoard = board.map((row) => row.map((t) => t.state.value).toList()).toList();
    final TableturfMove blueMove = (await Future.wait([
      compute(findBestBlueMove, [
        plainBoard,
        blue.hand.map((v) => v.value!).toList(),
        blue.special.value,
        turnCountNotifier.value,
        aiLevel,
        true,
      ]),
      Future.delayed(Duration(milliseconds: 1500 + Random().nextInt(500)))
    ]))[0];

    final audioController = AudioController();
    await audioController.playSfx(SfxType.confirmMoveSucceed);
    blueMoveNotifier.value = TableturfMove(
      card: blue.hand.firstWhere((card) => card.value!.data == blueMove.card.data).value!,
      rotation: blueMove.rotation,
      x: blueMove.x,
      y: blueMove.y,
      pass: blueMove.pass,
      special: blueMove.special,
      traits: blueMove.traits,
    );
  }

  Future<void> runYellowAI() async {
    final TileGrid plainBoard = board.map((row) => row.map((t) => t.state.value).toList()).toList();
    final TableturfMove yellowMove = (await Future.wait([
      compute(findBestBlueMove, [
        plainBoard,
        yellow.hand.map((v) => v.value!).toList(),
        yellow.special.value,
        turnCountNotifier.value,
        AILevel.level4,
        false,
      ]),
      Future.delayed(Duration(milliseconds: 1500 + Random().nextInt(500)))
    ]))[0];

    final audioController = AudioController();
    await audioController.playSfx(SfxType.confirmMoveSucceed);
    yellowMoveNotifier.value = TableturfMove(
      card: yellow.hand.firstWhere((card) => card.value!.data == yellowMove.card.data).value!,
      rotation: yellowMove.rotation,
      x: yellowMove.x,
      y: yellowMove.y,
      pass: yellowMove.pass,
      special: yellowMove.special,
      traits: yellowMove.traits,
    );
  }
}
