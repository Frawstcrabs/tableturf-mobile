import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tableturf_mobile/src/play_session/components/move_selection.dart';

import '../../audio/audio_controller.dart';
import '../../audio/sounds.dart';
import '../../style/palette.dart';

import '../../game_internals/battle.dart';
import '../../game_internals/tile.dart';

class BoardPainter extends CustomPainter {
  static const EDGE_WIDTH = 0.0;  // effectively 1 real pixel width

  final BoardGrid board;
  final double tileSideLength;

  BoardPainter(this.board, this.tileSideLength);

  @override
  void paint(Canvas canvas, Size size) {
    final palette = const Palette();
    final bodyPaint = Paint()
      ..style = PaintingStyle.fill
      ..strokeJoin = StrokeJoin.miter;
    final edgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.miter
      ..strokeWidth = EDGE_WIDTH
      ..color = palette.tileEdge;
    // draw
    for (var y = 0; y < board.length; y++) {
      for (var x = 0; x < board[0].length; x++) {
        final tile = board[y][x];
        final state = tile.state.value;
        if (state == TileState.empty) continue;

        bodyPaint.color = state == TileState.unfilled ? palette.tileUnfilled
            : state == TileState.wall ? palette.tileWall
            : state == TileState.yellow ? palette.tileYellow
            : state == TileState.yellowSpecial ? palette.tileYellowSpecial
            : state == TileState.blue ? palette.tileBlue
            : state == TileState.blueSpecial ? palette.tileBlueSpecial
            : Color.fromRGBO(0, 0, 0, 0);
        final tileRect = Rect.fromLTWH(
          x * tileSideLength,
          y * tileSideLength,
          tileSideLength,
          tileSideLength
        );
        canvas.drawRect(tileRect, bodyPaint);
        canvas.drawRect(tileRect, edgePaint);
        if (tile.specialIsActivated.value) {
          bodyPaint.color = state == TileState.yellowSpecial ? Color.fromRGBO(225, 255, 17, 1)
              : state == TileState.blueSpecial ? Color.fromRGBO(240, 255, 255, 1)
              : throw Exception("Invalid tile colour given for special: ${state}");
          canvas.drawCircle(
            Offset(
              (x + 0.5) * tileSideLength,
              (y + 0.5) * tileSideLength,
            ),
            tileSideLength / 3,
            bodyPaint
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }

}

class BoardWidget extends StatelessWidget {
  final double tileSize;

  const BoardWidget({
    super.key,
    required this.tileSize,
  });

  @override
  Widget build(BuildContext context) {
    final selection = MoveSelection.of(context);
    return RepaintBoundary(
      child: CustomPaint(
        painter: BoardPainter(selection.board, tileSize)
      ),
    );
  }
}