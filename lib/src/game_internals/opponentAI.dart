import 'dart:math';
import 'package:collection/collection.dart';

import 'player.dart';
import 'card.dart';
import 'move.dart';
import 'tile.dart';

enum AILevel {
  level1(xpAmount: 100, cardBitReward: 1),
  level2(xpAmount: 115, cardBitReward: 2),
  level3(xpAmount: 130, cardBitReward: 3);

  final int xpAmount;
  final int cardBitReward;

  const AILevel({required this.xpAmount, required this.cardBitReward});

  int toJson() => index;
  factory AILevel.fromJson(dynamic json) => values[json];
}

TileGrid _flipBoard(TileGrid board) {
  TileGrid ret = [];
  for (var y = board.length - 1; y >= 0; y--) {
    ret.add([]);
    for (var x = board[0].length - 1; x >= 0; x--) {
      //print("Getting pattern[$y][$x]");
      ret.last.add({
        TileState.empty: TileState.empty,
        TileState.unfilled: TileState.unfilled,
        TileState.wall: TileState.wall,
        TileState.yellow: TileState.blue,
        TileState.yellowSpecial: TileState.blueSpecial,
        TileState.blue: TileState.yellow,
        TileState.blueSpecial: TileState.yellowSpecial,
      }[board[y][x]]!);
    }
  }
  return ret;
}

int _calcBoardCoverage({
  required TileGrid board,
  required bool Function(TileState) isMatched,
}) {
  return board.fold(0, (count, row) {
    return count + row.fold(0, (count, tile) {
      return count + (isMatched(tile) ? 1 : 0);
    });
  });
}

class DistanceStats {
  final double averageDistance;
  final int reachableArea;

  const DistanceStats(this.averageDistance, this.reachableArea);
}

DistanceStats _calcBoardDistances({
  required TileGrid board,
  required bool Function(TileState) isMatched,
}) {
  Set<Coords> edgeTiles = Set();
  Set<Coords> newEdgeTiles = Set();
  Set<Coords> searchedTiles = Set();

  void addEdgeTiles(Coords tileCoords, Set<Coords> newEdgeTiles) {
    for (var dY = -1; dY <= 1; dY++) {
      for (var dX = -1; dX <= 1; dX++) {
        final newY = tileCoords.y + dY;
        final newX = tileCoords.x + dX;
        if (newY < 0 || newY >= board.length || newX < 0 || newX >= board[0].length) {
          continue;
        }
        final edgeTile = board[newY][newX];
        if (!edgeTile.isFilled) {
          final coords = Coords(newX, newY);
          if (!newEdgeTiles.contains(coords) && !searchedTiles.contains(coords)) {
            searchedTiles.add(coords);
            newEdgeTiles.add(coords);
          }
        }
      }
    }
  }

  for (var y = 0; y < board.length; y++) {
    for (var x = 0; x < board[0].length; x++) {
      final tile = board[y][x];
      if (isMatched(tile)) {
        addEdgeTiles(Coords(x, y), newEdgeTiles);
      }
    }
  }

  int dist = 1;
  int distCount = 0;
  while (newEdgeTiles.length > 0) {
    distCount += dist * newEdgeTiles.length;
    edgeTiles = newEdgeTiles;
    newEdgeTiles = Set();
    for (final coords in edgeTiles) {
      addEdgeTiles(coords, newEdgeTiles);
    }
    dist += 1;
  }
  return DistanceStats(distCount / searchedTiles.length, searchedTiles.length);
}

class SpecialStats {
  final int fullSpecials;
  final double partialSpecials;
  const SpecialStats(this.fullSpecials, this.partialSpecials);
}

SpecialStats _calcSpecialStats({
  required TileGrid board,
  required TileState specialTile,
}) {
  var fullSpecial = 0;
  var partialSpecial = 0.0;

  for (var y = 0; y < board.length; y++) {
    for (var x = 0; x < board[y].length; x++) {
      if (board[y][x] == specialTile) {
        var surroundCount = 0;
        for (var dY = -1; dY <= 1; dY++) {
          for (var dX = -1; dX <= 1; dX++) {
            final newY = y + dY;
            final newX = x + dX;
            if (newY < 0 || newY >= board.length || newX < 0 ||
                newX >= board[0].length) {
              // tiles outside of the board count as filled
              surroundCount += 1;
              continue;
            }
            final edgeTile = board[newY][newX];
            if (edgeTile.isFilled) {
              surroundCount += 1;
            }
          }
        }
        // surroundCount will also include the special tile itself
        surroundCount -= 1;
        if (surroundCount == 8) {
          fullSpecial += 1;
        } else {
          partialSpecial += surroundCount / 8.0;
        }
      }
    }
  }

  return SpecialStats(fullSpecial, partialSpecial);
}

class BoardStats {
  final int yellowArea, blueArea;
  final int yellowSpecial, blueSpecial;
  final DistanceStats yellowDistance, blueDistance;
  final double yellowSpecialScore, blueSpecialScore;

  const BoardStats({
    required this.yellowArea,
    required this.yellowSpecial,
    required this.yellowDistance,
    required this.yellowSpecialScore,
    required this.blueArea,
    required this.blueSpecial,
    required this.blueDistance,
    required this.blueSpecialScore,
  });
}

BoardStats _calcBoardStats(TileGrid board) {
  const fullSpecialScore = 2.0;
  const partialSpecialScore = 1.0;

  final yellowSpecialStats = _calcSpecialStats(
    board: board,
    specialTile: TileState.yellowSpecial,
  );
  final blueSpecialStats = _calcSpecialStats(
    board: board,
    specialTile: TileState.blueSpecial,
  );

  var yellowDistance = _calcBoardDistances(
    board: board,
    isMatched: (tile) => tile.isYellow,
  );
  var blueDistance = _calcBoardDistances(
    board: board,
    isMatched: (tile) => tile.isBlue,
  );

  return BoardStats(
    yellowArea: _calcBoardCoverage(
      board: board,
      isMatched: (tile) => tile.isYellow,
    ),
    yellowDistance: yellowDistance,
    yellowSpecial: yellowSpecialStats.fullSpecials,
    yellowSpecialScore: (
      (yellowSpecialStats.fullSpecials * fullSpecialScore)
        + (yellowSpecialStats.partialSpecials * partialSpecialScore)
    ),
    blueArea: _calcBoardCoverage(
      board: board,
      isMatched: (tile) => tile.isBlue,
    ),
    blueDistance: blueDistance,
    blueSpecial: blueSpecialStats.fullSpecials,
    blueSpecialScore: (
        (blueSpecialStats.fullSpecials * fullSpecialScore)
          + (blueSpecialStats.partialSpecials * partialSpecialScore)
    ),
  );
}

double _rateMove({
  required TableturfMove move,
  required TileGrid board,
  required List<TableturfCard> hand,
  required int special,
  required int turnsLeft,
  required AILevel aiLevel,
  BoardStats? boardStats,
}) {
  if (move.pass) {
    return 2.0;
  }
  boardStats ??= _calcBoardStats(board);
  final newBoard = board.copy();
  applyMoveToBoard(newBoard, move);
  final afterBoardStats = _calcBoardStats(newBoard);

  final areaScore = (
    (afterBoardStats.yellowArea - boardStats.yellowArea)
      - (afterBoardStats.blueArea - boardStats.blueArea)
  ).toDouble();

  final distanceScore = -(
    (afterBoardStats.yellowDistance.averageDistance - boardStats.yellowDistance.averageDistance)
      - (afterBoardStats.blueDistance.averageDistance - boardStats.blueDistance.averageDistance)
  );

  final reachabilityScore = (
    (afterBoardStats.yellowDistance.reachableArea - boardStats.yellowDistance.reachableArea)
      - (afterBoardStats.blueDistance.reachableArea - boardStats.blueDistance.reachableArea)
  ) / 5;

  final specialScore = (
    (afterBoardStats.yellowSpecialScore - boardStats.yellowSpecialScore)
      - (afterBoardStats.blueSpecialScore - boardStats.blueSpecialScore)
      - (move.special ? move.card.special : 0)
  );

  double moveScore;

  switch (aiLevel) {
    case AILevel.level1:
      /*
      moveScore = (
        (areaScore * 1.0)
          + (distanceScore * 0.5)
          + (reachabilityScore * 0.4)
          + (specialScore * 0.8)
      );
      break;
        */
    case AILevel.level2:
      /*
      final specialScoreDesire = 1.0 + ((12 - turnsLeft) / 8);
      if (move.special) {
        moveScore = (
            (areaScore * 1.0)
                + (distanceScore * 0.6)
                + (reachabilityScore * 0.6)
                + (specialScore * max(0.0, specialScoreDesire + 0.3))
        );
      } else {
        moveScore = (
            (areaScore * 1.0)
                + (distanceScore * 0.5)
                + (reachabilityScore * 0.7)
                + (specialScore * max(0.0, specialScoreDesire))
        );
      }
      break;
       */
    case AILevel.level3:
      final specialScoreDesire = 1.0 + ((12 - turnsLeft) / 8);
      if (turnsLeft == 1) {
        moveScore = areaScore;
      } else if (move.special) {
        moveScore = (
            (areaScore * 0.8)
                + (distanceScore * 1.5)
                + (reachabilityScore * 0.8)
                + (specialScore * max(0.0, specialScoreDesire - 0.4))
        );
      } else {
        moveScore = (
            (areaScore * 1.0)
                + (distanceScore * 1.0)
                + (reachabilityScore * 1.0)
                + (specialScore * max(0.0, specialScoreDesire))
        );
      }
      break;
  }

  // add some variance to the AI results
  // hopefully to prevent the exact same moves being played in the exact same scenarios
  // without hindering its ability
  const ratingError = 0.1;
  moveScore += (Random().nextDouble() * ratingError * 2) - ratingError;

  // adds lookahead to the scoring
  // needs optimising tho, this takes way too fucking long to search
  /*
  if (turnsLeft > 1 && hand.length > 1) {
    const discountFactor = 0.7;
    special += (afterBoardStats.yellowSpecial - boardStats.yellowSpecial)
        - (move.special ? move.card.special : 0);
    final newHand = hand.where((card) => card.data != move.card.data).toList();
    moveScore += discountFactor * findBestMove(
      board: newBoard,
      hand: newHand,
      special: special,
      turnsLeft: turnsLeft - 1,
      aiLevel: aiLevel,
      boardStats: afterBoardStats,
    ).score;
  }
  */

  return moveScore;
}

class RatedMove {
  final TableturfMove move;
  final double score;

  const RatedMove(this.move, this.score);
}

extension IterableZip<T> on Iterable<T> {
  Iterable<S> zip<U, S>(Iterable<U> other, S Function(T, U) combine) sync* {
    final iteratorA = this.iterator;
    final iteratorB = other.iterator;
    while (iteratorA.moveNext() && iteratorB.moveNext()) {
      yield combine(iteratorA.current, iteratorB.current);
    }
  }
}

RatedMove findBestMove({
  required TileGrid board,
  required List<TableturfCard> hand,
  required int special,
  required int turnsLeft,
  required AILevel aiLevel,
  BoardStats? boardStats,
}) {
  boardStats ??= _calcBoardStats(board);
  final moves = hand.map((card) =>
    TableturfMove(
      card: card,
      rotation: 0,
      x: 0,
      y: 0,
      pass: true,
      traits: const YellowTraits(),
    )
  ).followedBy(
    hand.expand((card) => getMoves(board, card, special: false))
  ).followedBy(
    hand
      .where((card) => card.special <= special)
      .expand((card) => getMoves(board, card, special: true))
  );

  final List<RatedMove> ratedMoves = [];
  for (final move in moves) {
    final moveRating = _rateMove(
      move: move,
      board: board,
      hand: hand,
      special: special,
      turnsLeft: turnsLeft,
      aiLevel: aiLevel,
      boardStats: boardStats,
    );
    final ratedMove = RatedMove(move, moveRating);

    final insertLocation = lowerBound(
      ratedMoves,
      ratedMove,
      compare: (RatedMove a, RatedMove b) => a.score.compareTo(b.score)
    );
    ratedMoves.insert(insertLocation, ratedMove);
  }

  switch (aiLevel) {
    case AILevel.level1:
      const lowerBound = 0.7;
      const upperBound = 1.0;
      final selection = lowerBound + (Random().nextDouble() * (upperBound - lowerBound));
      return ratedMoves[(ratedMoves.length * selection).floor()];

    case AILevel.level2:
      const lowerBound = 0.9;
      const upperBound = 1.0;
      final selection = lowerBound + (Random().nextDouble() * (upperBound - lowerBound));
      return ratedMoves[(ratedMoves.length * selection).floor()];

    case AILevel.level3:
      /*
      const lowerBound = 0.98;
      const upperBound = 1.0;
      final selection = lowerBound + (Random().nextDouble() * (upperBound - lowerBound));
      return ratedMoves[(ratedMoves.length * selection).floor()];
      */
      return ratedMoves.last;
  }

  /*
  moves.moveNext();
  var bestMove = moves.current;
  var bestMoveRating = _rateMove(
    move: bestMove,
    board: board,
    hand: hand,
    special: special,
    turnsLeft: turnsLeft,
    aiLevel: aiLevel,
    boardStats: boardStats,
  );
  while (moves.moveNext()) {
    var nextMove = moves.current;
    var nextMoveRating = _rateMove(
      move: nextMove,
      board: board,
      hand: hand,
      special: special,
      turnsLeft: turnsLeft,
      aiLevel: aiLevel,
      boardStats: boardStats,
    );
    if (nextMoveRating > bestMoveRating) {
      bestMove = nextMove;
      bestMoveRating = nextMoveRating;
    }
  }
  return RatedMove(bestMove, bestMoveRating);
  */
}

TableturfMove findBestBlueMove(List<dynamic> args) {
  print("${DateTime.now()}: rating moves...");
  final TileGrid rawBoard = args[0];
  final List<TableturfCard> hand = args[1];
  final int special = args[2];
  final int turnsLeft = args[3];
  final AILevel aiLevel = args[4];
  final bool flipBoard = args.length >= 6 ? args[5] : true;

  final startTime = DateTime.now().microsecondsSinceEpoch;
  final board = flipBoard ? _flipBoard(rawBoard) : rawBoard;
  final bestMove = findBestMove(
    board: board,
    hand: hand,
    special: special,
    turnsLeft: turnsLeft,
    aiLevel: aiLevel,
  ).move;
  final endTime = DateTime.now().microsecondsSinceEpoch;
  print("Calculated best move in ${(endTime - startTime) / 1000000} seconds");

  if (!flipBoard) {
    return bestMove;
  }

  final newRot = const [2, 3, 0, 1][bestMove.rotation];
  final pattern = rotatePattern(bestMove.card.minPattern, newRot);
  return TableturfMove(
    card: bestMove.card,
    rotation: newRot,
    x: board[0].length - bestMove.x - pattern[0].length,
    y: board.length - bestMove.y - pattern.length,
    pass: bestMove.pass,
    special: bestMove.special,
    traits: const BlueTraits(),
  );
}