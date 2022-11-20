import 'dart:math';

import 'player.dart';
import 'card.dart';
import 'move.dart';
import 'tile.dart';

enum AILevel {
  level1,
  level2,
  level3;

  double get ratingError => {
    level1: 1.0,
    level2: 0.5,
    level3: 0.0,
  }[this]!;
}

BoardGrid _flipBoard(BoardGrid board) {
  BoardGrid ret = [];
  for (var y = board.length - 1; y >= 0; y--) {
    ret.add([]);
    for (var x = board[0].length - 1; x >= 0; x--) {
      //print("Getting pattern[$y][$x]");
      ret.last.add(TableturfTile({
        TileState.empty: TileState.empty,
        TileState.unfilled: TileState.unfilled,
        TileState.wall: TileState.wall,
        TileState.yellow: TileState.blue,
        TileState.yellowSpecial: TileState.blueSpecial,
        TileState.blue: TileState.yellow,
        TileState.blueSpecial: TileState.yellowSpecial,
      }[board[y][x].state.value]!));
    }
  }
  return ret;
}

int _calcBoardCoverage({
  required BoardGrid board,
  required bool Function(TileState) isMatched,
}) {
  return board.fold(0, (count, row) {
    return count + row.fold(0, (count, tile) {
      return count + (isMatched(tile.state.value) ? 1 : 0);
    });
  });
}

double _calcBoardDistances({
  required BoardGrid board,
  required bool Function(TileState) isMatched,
}) {
  Set<Coords> edgeTiles = Set();
  Set<Coords> newEdgeTiles = Set();
  Set<Coords> searchedTiles = Set();

  void addEdgeTiles(Coords tileCoords) {
    for (var dY = -1; dY <= 1; dY++) {
      for (var dX = -1; dX <= 1; dX++) {
        final newY = tileCoords.y + dY;
        final newX = tileCoords.x + dX;
        if (newY < 0 || newY >= board.length || newX < 0 || newX >= board[0].length) {
          continue;
        }
        final edgeTile = board[newY][newX].state.value;
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
    for (var x = 0; x < board[y].length; x++) {
      final tile = board[y][x].state.value;
      if (isMatched(tile)) {
        addEdgeTiles(Coords(y, x));
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
      addEdgeTiles(coords);
    }
    dist += 1;
  }
  return distCount / searchedTiles.length;
}

class SpecialStats {
  final int fullSpecials;
  final double partialSpecials;
  const SpecialStats(this.fullSpecials, this.partialSpecials);
}

SpecialStats _calcSpecialStats({
  required BoardGrid board,
  required TileState specialTile,
}) {
  var fullSpecial = 0;
  var partialSpecial = 0.0;

  for (var y = 0; y < board.length; y++) {
    for (var x = 0; x < board[y].length; x++) {
      if (board[y][x].state.value == specialTile) {
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
            final edgeTile = board[newY][newX].state.value;
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
  final double yellowDistance, blueDistance;
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

BoardStats _calcBoardStats(BoardGrid board) {
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

  return BoardStats(
    yellowArea: _calcBoardCoverage(
      board: board,
      isMatched: (tile) => tile.isYellow,
    ),
    yellowDistance: _calcBoardDistances(
      board: board,
      isMatched: (tile) => tile.isYellow,
    ),
    yellowSpecial: yellowSpecialStats.fullSpecials,
    yellowSpecialScore: (
      (yellowSpecialStats.fullSpecials * fullSpecialScore)
        + (yellowSpecialStats.partialSpecials * partialSpecialScore)
    ),
    blueArea: _calcBoardCoverage(
      board: board,
      isMatched: (tile) => tile.isBlue,
    ),
    blueDistance: _calcBoardDistances(
      board: board,
      isMatched: (tile) => tile.isBlue,
    ),
    blueSpecial: blueSpecialStats.fullSpecials,
    blueSpecialScore: (
        (blueSpecialStats.fullSpecials * fullSpecialScore)
          + (blueSpecialStats.partialSpecials * partialSpecialScore)
    ),
  );
}

double _rateMove({
  required TableturfMove move,
  required BoardGrid board,
  required List<TableturfCard> hand,
  required int special,
  required int turnsLeft,
  required AILevel aiLevel,
  BoardStats? boardStats,
}) {
  boardStats ??= _calcBoardStats(board);
  final newBoard = board.map(
    (row) => row.map(
      (tile) => TableturfTile(tile.state.value)
    ).toList()
  ).toList();
  applyMoveToBoard(newBoard, move);
  final afterBoardStats = _calcBoardStats(newBoard);

  final areaScore = (
    (afterBoardStats.yellowArea - afterBoardStats.blueArea)
      - (boardStats.yellowArea - boardStats.blueArea)
  ).toDouble();

  final distanceScore = (
    (afterBoardStats.yellowDistance - afterBoardStats.blueDistance)
      - (boardStats.yellowDistance - boardStats.blueDistance)
  );

  final specialScore = (
    (afterBoardStats.yellowSpecialScore - afterBoardStats.blueSpecialScore)
      - (boardStats.yellowSpecialScore - boardStats.blueSpecialScore)
  );

  double moveScore;
  if (turnsLeft == 1) {
    moveScore = areaScore;
  } else if (move.special) {
    moveScore = (areaScore * 0.8) + (distanceScore * 1.5) + (specialScore * 0.5);
  } else {
    moveScore = areaScore + distanceScore + specialScore;
  }

  final ratingError = aiLevel.ratingError;
  moveScore += (Random().nextDouble() * ratingError * 2) - ratingError;

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

  return moveScore;
}

class BestMove {
  final TableturfMove move;
  final double score;

  const BestMove(this.move, this.score);
}

BestMove findBestMove({
  required BoardGrid board,
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
  ).iterator;

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
    );
    if (nextMoveRating > bestMoveRating) {
      bestMove = nextMove;
      bestMoveRating = nextMoveRating;
    }
  }
  return BestMove(bestMove, bestMoveRating);
}

TableturfMove findBestBlueMove(List<dynamic> args) {
  print("${DateTime.now()}: rating moves...");
  final TileGrid plainBoard = args[0];
  final board = _flipBoard(plainBoard.map((row) => row.map(TableturfTile.new).toList()).toList());
  final List<TableturfCard> hand = args[1];
  final int special = args[2];
  final int turnsLeft = args[3];
  final AILevel aiLevel = args[4];

  final startTime = DateTime.now().microsecondsSinceEpoch;
  final bestMove = findBestMove(
    board: board,
    hand: hand,
    special: special,
    turnsLeft: turnsLeft,
    aiLevel: aiLevel,
  ).move;
  final endTime = DateTime.now().microsecondsSinceEpoch;
  print("Calculated best move in ${(endTime - startTime) / 1000000} seconds");

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