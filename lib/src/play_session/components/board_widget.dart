import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
  final TableturfBattle battle;
  final double tileSize;

  const BoardWidget(this.battle, {
    super.key,
    required this.tileSize,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: BoardPainter(battle.board, tileSize)
    );
  }
}

class BoardTile extends StatefulWidget {
  static const EDGE_WIDTH = 0.5;
  final TableturfTile tile;
  final double tileSize;
  final TableturfBattle battle;

  const BoardTile(this.tile, {
    super.key,
    required this.tileSize,
    required this.battle,
  });

  @override
  State<BoardTile> createState() => _BoardTileState();
}

class _BoardTileState extends State<BoardTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flashController;
  late final Animation<Decoration> _flashAnimation;

  @override
  void initState() {
    _flashController = AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this
    );
    _flashController.value = 1.0;
    _flashAnimation = DecorationTween(
      begin: BoxDecoration(
        color: Colors.white
      ),
      end: BoxDecoration(
        color: const Color.fromRGBO(255, 255, 255, 0)
      )
    ).animate(_flashController);

    widget.tile.state.addListener(_runFlash);
    super.initState();
  }

  void _runFlash() {
    _flashController.forward(from: 0.0);
    setState(() {});
  }

  @override
  void dispose() {
    widget.tile.state.removeListener(_runFlash);
    _flashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();
    final state = widget.tile.state.value;
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: state == TileState.unfilled ? palette.tileUnfilled
                : state == TileState.wall ? palette.tileWall
                : state == TileState.yellow ? palette.tileYellow
                : state == TileState.yellowSpecial ? palette.tileYellowSpecial
                : state == TileState.blue ? palette.tileBlue
                : state == TileState.blueSpecial ? palette.tileBlueSpecial
                : Color.fromRGBO(0, 0, 0, 0),
            border: Border.all(
                width: BoardTile.EDGE_WIDTH,
                color: state == TileState.empty
                    ? Color.fromRGBO(0, 0, 0, 0)
                    : palette.tileEdge
            ),
          ),
          width: widget.tileSize,
          height: widget.tileSize,
        ),
        AnimatedBuilder(
          animation: widget.tile.specialIsActivated,
          builder: (_, __) {
            if (!widget.tile.specialIsActivated.value) {
              return Container();
            }
            return SizedBox(
              width: widget.tileSize,
              height: widget.tileSize,
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: state == TileState.yellowSpecial ? Color.fromRGBO(225, 255, 17, 1)
                        : state == TileState.blueSpecial ? Color.fromRGBO(240, 255, 255, 1)
                        : throw Exception("Invalid tile colour given for special: ${state}"),
                    borderRadius: BorderRadius.circular(999)
                  ),
                  width: widget.tileSize * (2/3),
                  height: widget.tileSize * (2/3),
                ),
              ),
            );
          }
        ),
        AnimatedBuilder(
          animation: Listenable.merge([
            widget.battle.moveSpecialNotifier,
            widget.battle.yellowMoveNotifier,
          ]),
          child: Container(
            width: widget.tileSize,
            height: widget.tileSize,
            color: const Color.fromRGBO(0, 0, 0, 0.4),
          ),
          builder: (_, child) {
            final specialDarken = (
              widget.battle.yellowMoveNotifier.value == null
                && widget.battle.moveSpecialNotifier.value
                && !state.isSpecial
                && state != TileState.empty
            );
            if (!specialDarken) {
              return Container();
            }
            return child!;
          }
        ),
        AnimatedBuilder(
          animation: _flashController,
          builder: (_, __) => Container(
            width: widget.tileSize,
            height: widget.tileSize,
            decoration: _flashAnimation.value,
          )
        ),
      ]
    );
  }
}