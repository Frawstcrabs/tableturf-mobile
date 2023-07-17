// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
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

class BattleEvent {
  get duration => Duration.zero;
  const BattleEvent();
}

class BoardUpdate extends BattleEvent {
  get duration => const Duration(milliseconds: 1000);
  final Map<Coords, TileState> updates;
  final SfxType sfx;

  const BoardUpdate(this.updates, this.sfx);
}

class BoardSpecialUpdate extends BattleEvent {
  get duration => const Duration(milliseconds: 1000);
  final Set<Coords> updates;

  const BoardSpecialUpdate(this.updates);
}

class ScoreUpdate extends BattleEvent {
  get duration => const Duration(milliseconds: 1500);
  final int yellowScore, blueScore;

  const ScoreUpdate(this.yellowScore, this.blueScore);
}

class PlayerSpecialUpdate extends BattleEvent {
  final int yellowSpecial, blueSpecial;

  const PlayerSpecialUpdate(this.yellowSpecial, this.blueSpecial);
}

class EndTurn extends BattleEvent {
  const EndTurn();
}

class NopEvent extends BattleEvent {
  get duration => const Duration(milliseconds: 1000);
  const NopEvent();
}

class AsyncEvent {
  Completer<void> _completer = Completer();
  bool _flag = false;

  AsyncEvent();

  bool get flag => _flag;
  set flag(bool newFlag) {
    if (newFlag && !_flag) {
      _completer.complete();
    } else if (!newFlag && _flag) {
      _completer = Completer();
    }
    _flag = newFlag;
  }

  Future<void> wait() => _completer.future;
}

class TableturfBattle {
  static final _log = Logger('TableturfBattle');
  final ValueNotifier<TableturfCard?> moveCardNotifier = ValueNotifier(null);
  final ValueNotifier<Coords?> moveLocationNotifier = ValueNotifier(null);
  final ValueNotifier<int> moveRotationNotifier = ValueNotifier(0);
  final ValueNotifier<bool> moveSpecialNotifier = ValueNotifier(false);
  final ValueNotifier<bool> movePassNotifier = ValueNotifier(false);
  final ValueNotifier<bool> moveIsValidNotifier = ValueNotifier(false);

  final ValueNotifier<bool> revealCardsNotifier = ValueNotifier(false);
  final ValueNotifier<bool> playerControlLock = ValueNotifier(true);
  final ValueNotifier<Set<Coords>> boardChangeNotifier = ValueNotifier(Set());
  final ValueNotifier<Set<Coords>> activatedSpecialsNotifier = ValueNotifier(Set());
  final ChangeNotifier endOfGameNotifier = ChangeNotifier();
  final ChangeNotifier specialMoveNotifier = ChangeNotifier();
  bool stopAllProgress = false;
  AsyncEvent backgroundEvent = AsyncEvent();

  final ValueNotifier<TableturfMove?> blueMoveNotifier = ValueNotifier(null);
  final ValueNotifier<TableturfMove?> yellowMoveNotifier = ValueNotifier(null);

  final ValueNotifier<int> yellowCountNotifier = ValueNotifier(1);
  final ValueNotifier<int> blueCountNotifier = ValueNotifier(1);
  final ValueNotifier<int> turnCountNotifier = ValueNotifier(12);
  int _yellowSpecialCount = 0, _blueSpecialCount = 0;

  final TableturfPlayer yellow;
  final TableturfPlayer blue;
  final AILevel aiLevel;
  final AILevel? playerAI;

  final TileGrid board, origBoard;

  TableturfBattle({
    required this.yellow,
    required this.blue,
    required this.board,
    required this.aiLevel,
    this.playerAI,
  }): origBoard = board.copy() {
    backgroundEvent.flag = true;
    moveCardNotifier.addListener(_updateMoveHighlight);
    moveLocationNotifier.addListener(_updateMoveHighlight);
    moveRotationNotifier.addListener(_updateMoveHighlight);
    movePassNotifier.addListener(_updateMoveHighlight);
    moveSpecialNotifier.addListener(_updateMoveHighlight);
    yellowMoveNotifier.addListener(_checkMovesSet);
    blueMoveNotifier.addListener(_checkMovesSet);
    updateScores();
  }

  void dispose() {
    moveCardNotifier.removeListener(_updateMoveHighlight);
    moveLocationNotifier.removeListener(_updateMoveHighlight);
    moveRotationNotifier.removeListener(_updateMoveHighlight);
    movePassNotifier.addListener(_updateMoveHighlight);
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
      moveIsValidNotifier.value = card != null;
    } else if (location != null
        && card != null) {
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
      final locationX = location.x - selectPoint.x;
      final locationY = location.y - selectPoint.y;
      if (!(
          locationY >= 0
              && locationY <= board.length - pattern.length
              && locationX >= 0
              && locationX <= board[0].length - pattern[0].length
      )) {
        moveIsValidNotifier.value = false;
        return;
      }
      final move = TableturfMove(
          card: card,
          rotation: rot,
          x: locationX,
          y: locationY,
          special: special
      );
      moveIsValidNotifier.value = moveIsValid(board, move);
    }
  }

  Future<void> _checkMovesSet() async {
    if (yellowMoveNotifier.value != null && blueMoveNotifier.value != null) {
      print("waiting on background lock");
      await backgroundEvent.wait();
      _log.info("turn triggered");
      await Future<void>.delayed(const Duration(milliseconds: 1000));
      await runTurn();
    }
  }

  void rotateLeft() {
    final audioController = AudioController();
    audioController.playSfx(SfxType.cursorRotate);
    int rot = moveRotationNotifier.value;
    rot -= 1;
    rot %= 4;
    moveRotationNotifier.value = rot;
  }

  void rotateRight() {
    final audioController = AudioController();
    audioController.playSfx(SfxType.cursorRotate);
    int rot = moveRotationNotifier.value;
    rot += 1;
    rot %= 4;
    moveRotationNotifier.value = rot;
  }

  void confirmMove() {
    if (!moveIsValidNotifier.value) {
      return;
    }
    final card = moveCardNotifier.value!;
    final audioController = AudioController();
    if (movePassNotifier.value) {
      audioController.playSfx(SfxType.confirmMovePass);
      yellowMoveNotifier.value = TableturfMove(
        card: card,
        rotation: 0,
        x: 0,
        y: 0,
        pass: movePassNotifier.value,
        special: moveSpecialNotifier.value,
      );
      playerControlLock.value = false;
      return;
    }

    final location = moveLocationNotifier.value;
    if (location == null) {
      return;
    }
    final rot = moveRotationNotifier.value;
    final pattern = rotatePattern(card.minPattern, rot);
    final selectPoint = rotatePatternPoint(
      card.selectPoint,
      card.minPattern.length,
      card.minPattern[0].length,
      rot,
    );
    final locationX = location.x - selectPoint.x;
    final locationY = location.y - selectPoint.y;
    _log.info("trying location $locationX, $locationY");
    if (!(
      locationY >= 0
        && locationY <= board.length - pattern.length
        && locationX >= 0
        && locationX <= board[0].length - pattern[0].length
    )) {
      return;
    }
    audioController.playSfx(SfxType.confirmMoveSucceed);
    yellowMoveNotifier.value = TableturfMove(
      card: card,
      rotation: rot,
      x: locationX,
      y: locationY,
      pass: movePassNotifier.value,
      special: moveSpecialNotifier.value,
    );
    playerControlLock.value = false;
  }

  Future<void> runTurn() async {
    if (stopAllProgress) return;
    final yellowMove = yellowMoveNotifier.value!;
    final blueMove = blueMoveNotifier.value!;
    final audioController = AudioController();

    if (yellowMove.special || blueMove.special) {
      audioController.playSfx(SfxType.specialCutIn);
      specialMoveNotifier.notifyListeners();
      await Future<void>.delayed(const Duration(milliseconds: 1600));
    }
    if (stopAllProgress) return;
    await audioController.playSfx(SfxType.cardFlip);
    revealCardsNotifier.value = true;
    yellowMove.card.hasBeenPlayed = true;
    blueMove.card.hasBeenPlayed = true;
    yellow.special.value -= yellowMove.special ? yellowMove.card.special : 0;
    blue.special.value -= blueMove.special ? blueMove.card.special : 0;
    final List<BattleEvent> events = _populateEvents();
    const cardRevealTime = const Duration(milliseconds: 1000);
    print(events);

    if (stopAllProgress) return;
    if (turnCountNotifier.value == 4) {
      () async {
        const endTurnWaitTime = const Duration(milliseconds: 500);
        final eventsDuration = events.fold(
          cardRevealTime + endTurnWaitTime,
          (Duration d, e) => d + e.duration
        );
        const musicFadeTime = Duration(milliseconds: 1300);
        const musicSilenceTime = Duration(milliseconds: 200);

        await Future<void>.delayed(eventsDuration - (musicFadeTime + musicSilenceTime));
        await audioController.stopSong(fadeDuration: musicFadeTime);
        await Future<void>.delayed(musicSilenceTime);
        await audioController.playSong(SongType.last3Turns);
      }();
    }

    await Future<void>.delayed(cardRevealTime);
    for (final event in events) {
      if (stopAllProgress) return;
      if (event is BoardUpdate) {
        for (final entry in event.updates.entries) {
          board[entry.key.y][entry.key.x] = entry.value;
        }
        boardChangeNotifier.value = event.updates.keys.toSet();
        audioController.playSfx(event.sfx);
      } else if (event is BoardSpecialUpdate) {
        activatedSpecialsNotifier.value = event.updates;
        await audioController.playSfx(SfxType.specialActivate);
      } else if (event is PlayerSpecialUpdate) {
        yellow.special.value = event.yellowSpecial;
        blue.special.value = event.blueSpecial;
        if (turnCountNotifier.value > 1) {
          await audioController.playSfx(SfxType.gainSpecial);
        }
      } else if (event is ScoreUpdate) {
        yellowCountNotifier.value = event.yellowScore;
        blueCountNotifier.value = event.blueScore;
        await audioController.playSfx(SfxType.counterUpdate);
      } else if (event is EndTurn) {
        if (turnCountNotifier.value == 1) {
          endOfGameNotifier.notifyListeners();
          return;
        }
      }
      await Future<void>.delayed(event.duration);
    }

    if (stopAllProgress) return;
    moveLocationNotifier.value = null;
    moveCardNotifier.value = null;
    moveRotationNotifier.value = 0;
    movePassNotifier.value = false;
    moveSpecialNotifier.value = false;
    moveIsValidNotifier.value = false;
    revealCardsNotifier.value = false;

    yellowMoveNotifier.value = null;
    blueMoveNotifier.value = null;
    await Future<void>.delayed(const Duration(milliseconds: 100));
    yellow.refreshHand();
    blue.refreshHand();
    await Future<void>.delayed(const Duration(milliseconds: 200));
    turnCountNotifier.value -= 1;
    await Future<void>.delayed(const Duration(milliseconds: 1000));
    if (stopAllProgress) return;

    for (final cardNotifier in yellow.hand) {
      final card = cardNotifier.value!;
      card.isPlayable = getMoves(board, card, special: false).isNotEmpty;
      card.isPlayableSpecial = card.special <= yellow.special.value && getMoves(board, card, special: true).isNotEmpty;
    }
    playerControlLock.value = true;
    if (stopAllProgress) return;
    runBlueAI();
    if (playerAI != null) {
      runYellowAI();
    }
    _log.info("turn complete");
  }

  List<BattleEvent> _populateEvents() {
    final yellowMove = yellowMoveNotifier.value!;
    final blueMove = blueMoveNotifier.value!;
    final List<BattleEvent> events = [];

    if (blueMove.pass && yellowMove.pass) {
      _log.info("no move");
      events.add(const NopEvent());

    } else if (blueMove.pass && !yellowMove.pass) {
      _log.info("yellow move only");
      events.add(BoardUpdate(
        yellowMove.boardChanges,
        yellowMove.special ? SfxType.specialMove : SfxType.normalMove
      ));

    } else if (!blueMove.pass && yellowMove.pass) {
      _log.info("blue move only");
      events.add(BoardUpdate(
          blueMove.boardChanges,
          blueMove.special ? SfxType.specialMove : SfxType.normalMove
      ));

    } else if (!_checkOverlap(blueMove, yellowMove)) {
      _log.info("no overlap");
      final boardChanges = yellowMove.boardChanges;
      boardChanges.addAll(blueMove.boardChanges);
      events.add(BoardUpdate(
          boardChanges,
          yellowMove.special || blueMove.special ? SfxType.specialMove : SfxType.normalMove
      ));

      /*
    } else if (blueMove.special && !yellowMove.special) {
      _log.info("blue special over yellow");
      await _applyOverlap(below: yellowMove, above: blueMove);

    } else if (yellowMove.special && !blueMove.special) {
      _log.info("yellow special over blue");
      await _applyOverlap(below: blueMove, above: yellowMove);
    */

    } else if (blueMove.card.count < yellowMove.card.count) {
      _log.info("blue over yellow");
      events.addAll(_applyOverlap(below: yellowMove, above: blueMove));

    } else if (yellowMove.card.count < blueMove.card.count) {
      _log.info("yellow over blue");
      events.addAll(_applyOverlap(below: blueMove, above: yellowMove));

    } else {
      _log.info("conflict");
      events.addAll(_applyConflict(blueMove, yellowMove));
    }

    final newBoard = events.fold<TileGrid>(board.copy(), (newBoard, event) {
      if (event is BoardUpdate) {
        for (final entry in event.updates.entries) {
          newBoard[entry.key.y][entry.key.x] = entry.value;
        }
      }
      return newBoard;
    });

    final prevYellowSpecialCount = _yellowSpecialCount;
    final prevBlueSpecialCount = _blueSpecialCount;
    events.addAll(_countSpecial(newBoard));

    final newYellowSpecial = (
        yellow.special.value
            + (_yellowSpecialCount - prevYellowSpecialCount)
            + (yellowMove.pass ? 1 : 0)
    );
    final newBlueSpecial = (
        blue.special.value
            + (_blueSpecialCount - prevBlueSpecialCount)
            + (blueMove.pass ? 1 : 0)
    );

    if (yellow.special.value != newYellowSpecial || blue.special.value != newBlueSpecial) {
      events.add(PlayerSpecialUpdate(newYellowSpecial, newBlueSpecial));
    }
    if (turnCountNotifier.value == 1) {
      events.add(const EndTurn());
      return events;
    }

    events.addAll(_countBoard(newBoard));

    events.add(const EndTurn());
    return events;
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

  Iterable<BattleEvent> _applyOverlap({required TableturfMove below, required TableturfMove above}) sync* {
    final belowChanges = below.boardChanges;
    yield BoardUpdate(
      belowChanges,
      below.special ? SfxType.specialMove : SfxType.normalMove
    );

    final relativePoint = Coords(
        above.x - below.x,
        above.y - below.y
    );
    final abovePattern = rotatePattern(above.card.minPattern, above.rotation);
    final belowPattern = rotatePattern(below.card.minPattern, below.rotation);
    final Map<Coords, TileState> overlapChanges = {};
    for (var y = 0; y < abovePattern.length; y++) {
      for (var x = 0; x < abovePattern[0].length; x++) {
        final aboveTile = abovePattern[y][x];
        if (aboveTile == TileState.unfilled) {
          continue;
        }
        final boardTile = board[above.y + y][above.x + x];
        final tileCoords = Coords(above.x + x, above.y + y);
        final relativeX = relativePoint.x + x;
        final relativeY = relativePoint.y + y;
        if (relativeY >= 0
            && relativeY < belowPattern.length
            && relativeX >= 0
            && relativeX < belowPattern[0].length) {
          final belowTile = belowPattern[relativeY][relativeX];
          if (belowTile == TileState.unfilled) {
            overlapChanges[tileCoords] = above.traits.mapCardTile(aboveTile);
            continue;
          }
          final newTile = {
            TileState.yellow: {
              TileState.yellow: above.traits.normalTile,
              TileState.yellowSpecial: below.traits.specialTile,
            }[belowTile]!,
            TileState.yellowSpecial: above.traits.specialTile,
          }[aboveTile]!;
          if (boardTile != newTile && belowChanges[tileCoords] != newTile) {
            overlapChanges[tileCoords] = newTile;
          }
        } else {
          overlapChanges[tileCoords] = above.traits.mapCardTile(aboveTile);
        }
      }
    }
    yield BoardUpdate(
      overlapChanges,
      above.special ? SfxType.specialMove : SfxType.normalMoveOverlap
    );
  }

  Iterable<BattleEvent> _applyConflict(TableturfMove move1, TableturfMove move2) sync* {
    var wallsGenerated = false;
    final Map<Coords, TileState> overlapChanges = {};
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
          final tileCoords = Coords(above.x + x, above.y + y);
          final relativeX = relativePoint.x + x;
          final relativeY = relativePoint.y + y;
          if (relativeY >= 0
              && relativeY < belowPattern.length
              && relativeX >= 0
              && relativeX < belowPattern[0].length) {
            final belowTile = belowPattern[relativeY][relativeX];
            if (aboveTile == TileState.unfilled) {
              if (belowTile != TileState.unfilled) {
                overlapChanges[tileCoords] = below.traits.mapCardTile(belowTile);
              }
              continue;
            }
            if (belowTile == TileState.unfilled) {
              if (aboveTile != TileState.unfilled) {
                overlapChanges[tileCoords] = above.traits.mapCardTile(aboveTile);
              }
              continue;
            }
            final newTile = {
              TileState.yellow: {
                TileState.yellow: TileState.wall,
                TileState.yellowSpecial: below.traits.specialTile,
              }[belowTile]!,
              TileState.yellowSpecial: {
                TileState.yellow: above.traits.specialTile,
                TileState.yellowSpecial: TileState.wall,
              }[belowTile]!,
            }[aboveTile]!;
            overlapChanges[tileCoords] = newTile;
            if (newTile == TileState.wall) {
              wallsGenerated = true;
            }
          } else {
            if (aboveTile != TileState.unfilled) {
              overlapChanges[tileCoords] = above.traits.mapCardTile(aboveTile);
            }
          }
        }
      }
    }
    applyOneWay(move1, move2);
    applyOneWay(move2, move1);
    yield BoardUpdate(
      overlapChanges,
      wallsGenerated ? SfxType.normalMoveConflict :
      move1.special || move2.special ? SfxType.specialMove : SfxType.normalMove
    );
  }

  Iterable<BattleEvent> _countBoard(TileGrid newBoard) sync* {
    var yellowCount = 0;
    var blueCount = 0;
    for (var y = 0; y < newBoard.length; y++) {
      for (var x = 0; x < newBoard[0].length; x++) {
        final boardTile = newBoard[y][x];
        if (boardTile.isYellow) {
          yellowCount += 1;
        }
        if (boardTile.isBlue) {
          blueCount += 1;
        }
      }
    }
    if (yellowCountNotifier.value != yellowCount || blueCountNotifier.value != blueCount) {
      yield ScoreUpdate(yellowCount, blueCount);
    }
  }

  void updateScores() {
    final newCountsIterator = _countBoard(board);
    if (newCountsIterator.isNotEmpty) {
      final newCounts = newCountsIterator.first as ScoreUpdate;
      yellowCountNotifier.value = newCounts.yellowScore;
      blueCountNotifier.value = newCounts.blueScore;
    }
  }

  Iterable<BattleEvent> _countSpecial(TileGrid newBoard) sync* {
    final prevYellowSpecialCount = _yellowSpecialCount;
    final prevBlueSpecialCount = _blueSpecialCount;
    _yellowSpecialCount = 0;
    _blueSpecialCount = 0;
    final activatedCoordsSet = Set<Coords>();
    for (var y = 0; y < newBoard.length; y++) {
      for (var x = 0; x < newBoard[0].length; x++) {
        final boardTile = newBoard[y][x];
        if (boardTile.isSpecial) {
          bool surrounded = true;
          for (var dy = -1; dy <= 1; dy++) {
            for (var dx = -1; dx <= 1; dx++) {
              final newY = y + dy;
              final newX = x + dx;
              if (newY < 0 || newY >= newBoard.length || newX < 0 || newX >= newBoard[0].length) {
                continue;
              }
              final adjacentTile = newBoard[newY][newX];
              if (!adjacentTile.isFilled) {
                surrounded = false;
                continue;
              }
            }
          }
          if (surrounded) {
            activatedCoordsSet.add(Coords(x, y));
            if (boardTile == TileState.yellowSpecial) {
              _yellowSpecialCount += 1;
            } else {
              _blueSpecialCount += 1;
            }
          }
        }
      }
    }
    if (_yellowSpecialCount != prevYellowSpecialCount
        || _blueSpecialCount != prevBlueSpecialCount) {
      yield BoardSpecialUpdate(activatedCoordsSet);
    }
  }

  Future<void> runBlueAI() async {
    final TableturfMove blueMove = (await Future.wait([
      compute(findBestBlueMove, [
        board,
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
    assert(playerAI != null);
    final TableturfMove yellowMove = (await Future.wait([
      compute(findBestBlueMove, [
        board,
        yellow.hand.map((v) => v.value!).toList(),
        yellow.special.value,
        turnCountNotifier.value,
        playerAI,
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
