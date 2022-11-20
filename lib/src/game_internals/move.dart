import 'tile.dart';
import 'card.dart';
import 'player.dart';

class TableturfMove {
  final TableturfCard card;
  final int rotation;
  final int y, x;
  final bool special, pass;
  final PlayerTraits traits;

  const TableturfMove({
    required this.card,
    required this.rotation,
    required this.x,
    required this.y,
    this.traits = const YellowTraits(),
    this.special = false,
    this.pass = false,
  });
}

Iterable<TableturfMove> getMoves(BoardGrid board, TableturfCard card, {bool special = false}) sync* {
  for (var rot = 0; rot < 4; rot++) {
    var pattern = rotatePattern(card.minPattern, rot);
    for (var moveY = 0; moveY < board.length - pattern.length + 1; moveY++) {
      for (var moveX = 0; moveX < board[0].length - pattern[0].length + 1; moveX++) {
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
      if (cardTile.isFilled && board[moveY + y][moveX + x].state.value.isFilled) {
        return false;
      }
      if (!isTouchingYellow && cardTile.isFilled) {
        for (var modY = -1; modY <= 1; modY++) {
          for (var modX = -1; modX <= 1; modX++) {
            final boardY = moveY + y + modY;
            final boardX = moveX + x + modX;
            if (boardY < 0 || boardY >= board.length || boardX < 0 || boardX >= board[0].length) {
              continue;
            }
            final TileState edgeTile = board[boardY][boardX].state.value;
            if (edgeTile.isYellow) {
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
      final TileState boardTile = board[moveY + y][moveX + x].state.value;
      if (cardTile.isFilled
          && (boardTile == TileState.empty
              || boardTile == TileState.wall
              || boardTile == TileState.yellowSpecial
              || boardTile == TileState.blueSpecial)) {
        return false;
      }
      if (!isTouchingYellow && cardTile.isFilled) {
        for (var modY = -1; modY <= 1; modY++) {
          for (var modX = -1; modX <= 1; modX++) {
            final boardY = moveY + y + modY;
            final boardX = moveX + x + modX;
            if (boardY < 0 || boardY >= board.length || boardX < 0 || boardX >= board[0].length) {
              continue;
            }
            final TileState edgeTile = board[boardY][boardX].state.value;
            if (edgeTile == TileState.yellowSpecial) {
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



void applySquare(TableturfTile tile, TileState newState, PlayerTraits traits) {
  if (newState == TileState.yellow) {
    tile.state.value = traits.normalTile;
  } else if (newState == TileState.yellowSpecial) {
    tile.state.value = traits.specialTile;
  }
}

void applyMoveToBoard(BoardGrid board, TableturfMove move) {
  if (!move.pass) {
    var pattern = rotatePattern(
        move.card.minPattern, move.rotation);
    for (var y = 0; y < pattern.length; y++) {
      for (var x = 0; x < pattern[0].length; x++) {
        final cardTile = pattern[y][x];
        final boardTile = board[y + move.y][x + move.x];
        applySquare(boardTile, cardTile, move.traits);
      }
    }
  }
}