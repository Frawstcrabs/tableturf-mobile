// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:math';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:tableturf_mobile/src/style/constants.dart';

import '../audio/audio_controller.dart';
import '../audio/songs.dart';
import '../audio/sounds.dart';

import 'opponentAI.dart';
import 'card.dart';
import 'tile.dart';
import 'move.dart';
import 'player.dart';

abstract class BattleEvent {
  const BattleEvent();
  Duration get duration => Duration.zero;
}

class HandRedraw extends BattleEvent {
  final List<int> deckIndexes;
  const HandRedraw(this.deckIndexes);
}

class MoveConfirm extends BattleEvent {
  final PlayerID playerID;

  const MoveConfirm(this.playerID);
  Duration get duration => Duration.zero;
}

class Turn extends BattleEvent {
  final Map<PlayerID, TableturfMove> moves;
  final List<BattleEvent> events;
  const Turn(this.moves, this.events);
}

class TurnStart extends BattleEvent {
  final Map<PlayerID, TableturfMove> moves;
  const TurnStart(this.moves);
}

class RevealCards extends BattleEvent {
  const RevealCards();
  Duration get duration => const Duration(seconds: 1);
}

enum BoardTileUpdateType {
  normal,
  overlap,
  conflict,
  special,
  silent,
}

class BoardTilesUpdate extends BattleEvent {
  final Map<Coords, TileState> updates;
  final BoardTileUpdateType type;

  const BoardTilesUpdate(this.updates, this.type);
  Duration get duration => const Duration(seconds: 1);
}

class BoardSpecialUpdate extends BattleEvent {
  final Set<Coords> updates;

  const BoardSpecialUpdate(this.updates);
  Duration get duration => const Duration(seconds: 1);
}

class ScoreUpdate extends BattleEvent {
  final Map<PlayerID, int> newScores;
  const ScoreUpdate(this.newScores);
  Duration get duration => Durations.battleUpdateScores;
}

class PlayerSpecialUpdate extends BattleEvent {
  final Map<PlayerID, int> specialDiffs;

  const PlayerSpecialUpdate(this.specialDiffs);
}

class UpdateHand extends BattleEvent {
  final int handIndex;
  final int deckIndex;
  Duration get duration => const Duration(milliseconds: 200);
  const UpdateHand(this.handIndex, this.deckIndex);
}

class ClearMoves extends BattleEvent {
  Duration get duration => const Duration(milliseconds: 100);
  const ClearMoves();
}

class TurnCountTick extends BattleEvent {
  final int newTurnCount;
  const TurnCountTick(this.newTurnCount);
  Duration get duration => const Duration(seconds: 1);
}

class TurnEnd extends BattleEvent {
  const TurnEnd();
}

class NopEvent extends BattleEvent {
  const NopEvent();
  Duration get duration => const Duration(seconds: 1);
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

class TableturfBattleController {
  final ValueNotifier<TableturfCard?> moveCardNotifier = ValueNotifier(null);
  final ValueNotifier<Coords?> moveLocationNotifier = ValueNotifier(null);
  final ValueNotifier<int> moveRotationNotifier = ValueNotifier(0);
  final ValueNotifier<bool> moveSpecialNotifier = ValueNotifier(false);
  final ValueNotifier<bool> movePassNotifier = ValueNotifier(false);
  final ValueNotifier<bool> _moveIsValidNotifier = ValueNotifier(false);
  ValueListenable<bool> get moveIsValidNotifier => _moveIsValidNotifier;
  late final Listenable moveChangeNotifier = Listenable.merge([
    moveCardNotifier,
    moveLocationNotifier,
    moveRotationNotifier,
    moveSpecialNotifier,
    movePassNotifier,
  ]);

  final ValueNotifier<bool> playerControlIsLocked = ValueNotifier(true);

  final TileGrid board;
  final ValueNotifier<Set<Coords>> activatedSpecials = ValueNotifier(Set());
  final TableturfPlayer player;
  final List<TableturfCard> playerDeck;
  final List<ValueNotifier<TableturfCard?>> playerHand = List.generate(4, (_) => ValueNotifier(null));
  int playerSpecial = 0;
  TableturfMove? _playerMove = null;
  TableturfMove? get playerMove => _playerMove;
  final TableturfBattleModel _model;

  TableturfBattleController({
    required this.board,
    required this.player,
    required this.playerDeck,
    required TableturfBattleModel model,
  }) : _model = model {
    moveChangeNotifier.addListener(_updatePlayerMove);
  }

  void _updatePlayerMove() {
    final moveCard = moveCardNotifier.value;
    final moveLocation = moveLocationNotifier.value;
    final moveRotation = moveRotationNotifier.value;
    if (moveCard == null) {
      _playerMove = null;
      _moveIsValidNotifier.value = false;
      return;
    }
    if (movePassNotifier.value) {
      _playerMove = TableturfMove(
        card: moveCard,
        rotation: moveRotation,
        x: 0,
        y: 0,
        pass: movePassNotifier.value,
      );
      _moveIsValidNotifier.value = true;
      return;
    }
    if (moveLocation == null) {
      _playerMove = null;
      _moveIsValidNotifier.value = false;
      return;
    }
    final pattern = rotatePattern(
      moveCard.minPattern,
      moveRotation,
    );
    final selectPoint = rotatePatternPoint(
      moveCard.selectPoint,
      moveCard.minPattern.length,
      moveCard.minPattern[0].length,
      moveRotation,
    );
    final locationX = moveLocation.x - selectPoint.x;
    final locationY = moveLocation.y - selectPoint.y;
    if (!(
        locationY >= 0
            && locationY <= board.length - pattern.length
            && locationX >= 0
            && locationX <= board[0].length - pattern[0].length
    )) {
      _playerMove = null;
      _moveIsValidNotifier.value = false;
      return;
    }
    final newPlayerMove = TableturfMove(
      card: moveCard,
      rotation: moveRotation,
      x: locationX,
      y: locationY,
      special: moveSpecialNotifier.value,
    );
    _playerMove = newPlayerMove;
    _moveIsValidNotifier.value = _model.checkMoveValidity(board, newPlayerMove);
  }

  void rotateCounterClockwise() {
    var rot = moveRotationNotifier.value;
    rot -= 1;
    rot %= 4;
    moveRotationNotifier.value = rot;
  }

  void rotateClockwise() {
    var rot = moveRotationNotifier.value;
    rot += 1;
    rot %= 4;
    moveRotationNotifier.value = rot;
  }

  void confirmMove() {
    if (!_moveIsValidNotifier.value) {
      return;
    }
    _model.setPlayerMove(player.id, _playerMove!);
    playerControlIsLocked.value = true;
  }

  void reset() {
    for (final cardNotifier in playerHand) {
      final card = cardNotifier.value!;
      card.isPlayable = getMoves(board, card, special: false).isNotEmpty;
      card.isPlayableSpecial = card.special <= playerSpecial && getMoves(board, card, special: true).isNotEmpty;
    }
    moveCardNotifier.value = null;
    moveLocationNotifier.value = null;
    moveRotationNotifier.value = 0;
    moveSpecialNotifier.value = false;
    movePassNotifier.value = false;
    playerControlIsLocked.value = false;
  }
}

abstract interface class TableturfBattleModel {
  bool checkMoveValidity(TileGrid board, TableturfMove move);
  void setPlayerMove(PlayerID playerID, TableturfMove move);
  Stream<BattleEvent> get eventStream;
}

const kNormalBattleTurns = 12;

class LocalTableturfBattle implements TableturfBattleModel {
  static final _log = Logger('LocalTableturfBattle');

  final Map<PlayerID, TableturfMove> playerMoves = {};

  Map<PlayerID, int> playerScores = {};
  Map<PlayerID, int> playerSpecials = {};
  int turnCount = kNormalBattleTurns;

  final TableturfPlayer player, opponent;
  List<TableturfCard> playerDeck, opponentDeck;
  List<TableturfCard> playerHand = [], opponentHand = [];

  StreamController<BattleEvent> _eventStreamController = StreamController();
  Stream<BattleEvent> get eventStream => _eventStreamController.stream;

  int _yellowSpecialCount = 0, _blueSpecialCount = 0;

  final AILevel aiLevel;
  final AILevel? playerAI;

  TileGrid _board;
  TileGrid get board => _board;
  final TileGrid origBoard;

  LocalTableturfBattle({
    required this.player,
    required this.playerDeck,
    required this.opponent,
    required this.opponentDeck,
    required TileGrid board,
    required this.aiLevel,
    this.playerAI,
  }):
      _board = board,
      origBoard = board.copy() {
    reset();
  }

  void dispose() {
    _eventStreamController.close();
  }

  Future<void> startGame() async {
    //initialise opponent hand
    opponentHand = opponentDeck.randomSample(4);
    for (final card in opponentHand) {
      card
        ..isHeld = true
        ..isPlayable = getMoves(board, card).isNotEmpty
        ..isPlayableSpecial = false;
    }

    final playerHandIndexes = List.generate(playerDeck.length, (index) => index).randomSample(4);
    playerHand = playerHandIndexes.map((i) => playerDeck[i]).toList();
    _eventStreamController.add(HandRedraw(playerHandIndexes));
  }

  void reset() {
    _board = origBoard.copy();
    _eventStreamController.close();
    _eventStreamController = StreamController();
    playerHand = [];
    for (final card in playerDeck) {
      card.isHeld = false;
      card.hasBeenPlayed = false;
      card.isPlayable = false;
      card.isPlayableSpecial = false;
    }
    opponentHand = [];
    for (final card in opponentDeck) {
      card.isHeld = false;
      card.hasBeenPlayed = false;
      card.isPlayable = false;
      card.isPlayableSpecial = false;
    }
    turnCount = kNormalBattleTurns;
    playerSpecials = {player.id: 0, opponent.id: 0};
    _yellowSpecialCount = 0;
    _blueSpecialCount = 0;
    updateScores();
  }

  Future<void> requestRedraw() async {
    final playerHandIndexes = List.generate(playerDeck.length, (index) => index).randomSample(4);
    playerHand = playerHandIndexes.map((i) => playerDeck[i]).toList();
    _eventStreamController.add(HandRedraw(playerHandIndexes));
  }

  bool checkMoveValidity(TileGrid board, TableturfMove move) {
    return checkMoveIsValid(board, move);
  }

  void setPlayerMove(PlayerID playerID, TableturfMove move) {
    playerMoves[playerID] = move;
    _eventStreamController.add(MoveConfirm(playerID));
    _checkMovesSet();
  }

  Future<void> _checkMovesSet() async {
    if (playerMoves.containsKey(player.id) && playerMoves.containsKey(opponent.id)) {
      _log.info("turn triggered");
      await Future<void>.delayed(const Duration(milliseconds: 1000));
      await runTurn();
    }
  }

  Future<void> runTurn() async {
    final yellowMove = playerMoves[player.id]!;
    final blueMove = playerMoves[opponent.id]!;

    yellowMove.card.hasBeenPlayed = true;
    blueMove.card.hasBeenPlayed = true;

    final List<BattleEvent> events = [];

    final specialDiffs = {
      player.id: yellowMove.special ? -yellowMove.card.special : 0,
      opponent.id: blueMove.special ? -blueMove.card.special : 0,
    };

    if (specialDiffs.values.any((s) => s != 0)) {
      events.add(PlayerSpecialUpdate(Map.of(specialDiffs)));
      for (final MapEntry(:key, :value) in specialDiffs.entries) {
        playerSpecials.update(
          key,
              (s) => s + value,
          ifAbsent: () => value,
        );
      }
    }
    events.add(const RevealCards());
    events.addAll(calculateEvents(yellowMove, blueMove));

    if (turnCount > 1) {
      events.add(const ClearMoves());
      for (var i = 0; i < opponentHand.length; i++) {
        final card = opponentHand[i];
        if (card.hasBeenPlayed) {
          final newCard = opponentDeck.where((card) =>
            !card.isHeld && !card.hasBeenPlayed).toList().random();
          card.isHeld = false;
          newCard.isHeld = true;
          opponentHand[i] = newCard;
        }
      }
      for (var i = 0; i < playerHand.length; i++) {
        final card = playerHand[i];
        if (card.hasBeenPlayed) {
          final newCardIndex = [
            for (final (i, card) in playerDeck.indexed)
              if (!card.isHeld && !card.hasBeenPlayed)
                i
          ].random();
          final newCard = playerDeck[newCardIndex];
          card.isHeld = false;
          newCard.isHeld = true;
          playerHand[i] = newCard;
          events.add(UpdateHand(i, newCardIndex));
        }
      }
    }

    turnCount -= 1;
    events.add(TurnCountTick(turnCount));
    _log.info(events);
    _eventStreamController.add(Turn(Map.of(playerMoves), events));
    playerMoves.clear();

    _log.info("turn complete");
  }

  List<BattleEvent> calculateEvents(TableturfMove yellowMove, TableturfMove blueMove) {
    final List<BattleEvent> events = [];

    if (blueMove.pass && yellowMove.pass) {
      _log.info("no move");
      events.add(const NopEvent());

    } else if (blueMove.pass && !yellowMove.pass) {
      _log.info("yellow move only");
      final updates = yellowMove.boardChanges;
      if (yellowMove.special) {
        events.add(BoardTilesUpdate(updates, BoardTileUpdateType.special));
      } else {
        events.add(BoardTilesUpdate(updates, BoardTileUpdateType.normal));
      }
      applyMoveToBoard(board, yellowMove);

    } else if (!blueMove.pass && yellowMove.pass) {
      _log.info("blue move only");
      final updates = blueMove.boardChanges;
      if (blueMove.special) {
        events.add(BoardTilesUpdate(updates, BoardTileUpdateType.special));
      } else {
        events.add(BoardTilesUpdate(updates, BoardTileUpdateType.normal));
      }
      applyMoveToBoard(board, blueMove);

    } else if (!checkOverlap(blueMove, yellowMove)) {
      _log.info("no overlap");
      final updates = yellowMove.boardChanges;
      updates.addAll(blueMove.boardChanges);
      if (yellowMove.special || blueMove.special) {
        events.add(BoardTilesUpdate(updates, BoardTileUpdateType.special));
      } else {
        events.add(BoardTilesUpdate(updates, BoardTileUpdateType.normal));
      }
      for (final entry in updates.entries) {
        board[entry.key.y][entry.key.x] = entry.value;
      }

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
      events.addAll(applyOverlap(below: yellowMove, above: blueMove));

    } else if (yellowMove.card.count < blueMove.card.count) {
      _log.info("yellow over blue");
      events.addAll(applyOverlap(below: blueMove, above: yellowMove));

    } else {
      _log.info("conflict");
      events.addAll(applyConflict(blueMove, yellowMove));
    }

    final prevYellowSpecialCount = _yellowSpecialCount;
    final prevBlueSpecialCount = _blueSpecialCount;
    events.addAll(countSpecial());

    final specialDiffs = {
      player.id: (_yellowSpecialCount - prevYellowSpecialCount)
          + (yellowMove.pass ? 1 : 0),
      opponent.id: (_blueSpecialCount - prevBlueSpecialCount)
          + (blueMove.pass ? 1 : 0),
    };

    if (specialDiffs.values.any((s) => s > 0)) {
      events.add(PlayerSpecialUpdate(Map.of(specialDiffs)));
      for (final MapEntry(:key, :value) in specialDiffs.entries) {
        playerSpecials.update(
          key,
          (s) => s + value,
          ifAbsent: () => value,
        );
      }
    }
    if (turnCount > 1) {
      events.addAll(countBoard());
    }

    return events;
  }

  bool checkOverlap(TableturfMove move1, TableturfMove move2) {
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

  Iterable<BattleEvent> applyOverlap({required TableturfMove below, required TableturfMove above}) sync* {
    final belowChanges = below.boardChanges;
    if (below.special) {
      yield BoardTilesUpdate(
        belowChanges,
        BoardTileUpdateType.special,
      );
    } else {
      yield BoardTilesUpdate(
        belowChanges,
        BoardTileUpdateType.normal,
      );
    }

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
    if (above.special) {
      yield BoardTilesUpdate(
        overlapChanges,
        BoardTileUpdateType.special,
      );
    } else {
      yield BoardTilesUpdate(
        overlapChanges,
        BoardTileUpdateType.overlap,
      );
    }
    for (final entry in belowChanges.entries) {
      board[entry.key.y][entry.key.x] = entry.value;
    }
    for (final entry in overlapChanges.entries) {
      board[entry.key.y][entry.key.x] = entry.value;
    }
  }

  Iterable<BattleEvent> applyConflict(TableturfMove move1, TableturfMove move2) sync* {
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
    for (final entry in overlapChanges.entries) {
      board[entry.key.y][entry.key.x] = entry.value;
    }
    if (wallsGenerated) {
      yield BoardTilesUpdate(
        overlapChanges,
        BoardTileUpdateType.conflict,
      );
    } else if (move1.special || move2.special) {
      yield BoardTilesUpdate(
        overlapChanges,
        BoardTileUpdateType.special,
      );
    } else {
      yield BoardTilesUpdate(
        overlapChanges,
        BoardTileUpdateType.normal,
      );
    }
  }

  Iterable<BattleEvent> countBoard() sync* {
    var yellowCount = 0;
    var blueCount = 0;
    for (var y = 0; y < board.length; y++) {
      for (var x = 0; x < board[0].length; x++) {
        final boardTile = board[y][x];
        if (boardTile.isYellow) {
          yellowCount += 1;
        }
        if (boardTile.isBlue) {
          blueCount += 1;
        }
      }
    }
    final newScores = {
      player.id: yellowCount,
      opponent.id: blueCount,
    };
    playerScores.putIfAbsent(player.id, () => yellowCount);
    playerScores.putIfAbsent(opponent.id, () => blueCount);
    if (!const MapEquality<PlayerID, int>().equals(playerScores, newScores)) {
      yield ScoreUpdate(Map.of(newScores));
    }
    playerScores = Map.of(newScores);
  }

  void updateScores() {
    countBoard().forEach((e) {print(e);});
  }

  Iterable<BattleEvent> countSpecial() sync* {
    final prevYellowSpecialCount = _yellowSpecialCount;
    final prevBlueSpecialCount = _blueSpecialCount;
    _yellowSpecialCount = 0;
    _blueSpecialCount = 0;
    final activatedCoordsSet = Set<Coords>();
    for (var y = 0; y < board.length; y++) {
      for (var x = 0; x < board[0].length; x++) {
        final boardTile = board[y][x];
        if (boardTile.isSpecial) {
          bool surrounded = true;
          for (var dy = -1; dy <= 1; dy++) {
            for (var dx = -1; dx <= 1; dx++) {
              final newY = y + dy;
              final newX = x + dx;
              if (newY < 0 || newY >= board.length || newX < 0 || newX >= board[0].length) {
                continue;
              }
              final adjacentTile = board[newY][newX];
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
        opponentHand,
        playerSpecials[opponent.id]!,
        turnCount,
        aiLevel,
        true,
      ]),
      Future.delayed(Duration(milliseconds: 1500 + Random().nextInt(500)))
    ]))[0];

    final ret = TableturfMove(
      card: opponentHand.firstWhere((card) => card.ident == blueMove.card.ident),
      rotation: blueMove.rotation,
      x: blueMove.x,
      y: blueMove.y,
      pass: blueMove.pass,
      special: blueMove.special,
      traits: blueMove.traits,
    );
    setPlayerMove(opponent.id, ret);
  }

  Future<void> runYellowAI() async {
    assert(playerAI != null);
    final TableturfMove yellowMove = (await Future.wait([
      compute(findBestBlueMove, [
        board,
        playerHand,
        playerSpecials[player.id]!,
        turnCount,
        playerAI,
        false,
      ]),
      Future.delayed(Duration(milliseconds: 1500 + Random().nextInt(500)))
    ]))[0];

    final ret = TableturfMove(
      card: playerHand.firstWhere((card) => card.ident == yellowMove.card.ident),
      rotation: yellowMove.rotation,
      x: yellowMove.x,
      y: yellowMove.y,
      pass: yellowMove.pass,
      special: yellowMove.special,
      traits: yellowMove.traits,
    );
    setPlayerMove(player.id, ret);
  }

  Future<void> runAI() async {
    await Future.wait([
      runBlueAI(),
      if (playerAI != null)
        runYellowAI(),
    ]);
  }
}
