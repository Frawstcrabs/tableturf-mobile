import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../audio/audio_controller.dart';
import '../../audio/sounds.dart';
import '../../game_internals/card.dart';
import '../../style/palette.dart';

import '../../game_internals/battle.dart';
import '../../game_internals/tile.dart';

class BoardPainter extends CustomPainter {
  static const EDGE_WIDTH = 0.0;  // effectively 1 real pixel width

  final TileGrid board;
  final Set<Coords> activatedSpecials;
  final double tileSideLength;
  final ValueListenable<bool> specialButtonOn;

  BoardPainter({
    required this.board,
    required this.activatedSpecials,
    required this.specialButtonOn,
    required this.tileSideLength,
  }): super(repaint: specialButtonOn);

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
        final state = board[y][x];
        if (state == TileState.empty) continue;

        bodyPaint.color = state == TileState.unfilled ? palette.tileUnfilled
            : state == TileState.wall ? palette.tileWall
            : state == TileState.yellow ? palette.tileYellow
            : state == TileState.yellowSpecial ? palette.tileYellowSpecial
            : state == TileState.blue ? palette.tileBlue
            : state == TileState.blueSpecial ? palette.tileBlueSpecial
            : Color.fromRGBO(0, 0, 0, 0);
        if (specialButtonOn.value && !state.isSpecial && state != TileState.empty) {
          bodyPaint.color = Color.alphaBlend(
            const Color.fromRGBO(0, 0, 0, 0.4),
            bodyPaint.color,
          );
        }
        final tileRect = Rect.fromLTWH(
          x * tileSideLength,
          y * tileSideLength,
          tileSideLength,
          tileSideLength
        );
        canvas.drawRect(tileRect, bodyPaint);
        canvas.drawRect(tileRect, edgePaint);
        if (activatedSpecials.contains(Coords(x, y))) {
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
  bool shouldRepaint(BoardPainter oldDelegate) {
    return (
      this.board != oldDelegate.board
        || this.tileSideLength != oldDelegate.tileSideLength
        || this.activatedSpecials != oldDelegate.activatedSpecials
    );
  }
}

class BoardFlashPainter extends CustomPainter {
  final Animation<double> flashAnimation;
  final Set<Coords> flashTiles;
  final double tileSideLength;

  BoardFlashPainter(this.flashAnimation, this.flashTiles, this.tileSideLength):
    super(repaint: flashAnimation)
  ;

  @override
  void paint(Canvas canvas, Size size) {
    if (flashAnimation.value == 0.0) return;

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeJoin = StrokeJoin.miter
      ..color = Colors.white.withOpacity(flashAnimation.value);
    for (final coords in flashTiles) {
      final tileRect = Rect.fromLTWH(
        coords.x * tileSideLength,
        coords.y * tileSideLength,
        tileSideLength,
        tileSideLength
      );
      canvas.drawRect(tileRect, paint);
    }
  }

  @override
  bool shouldRepaint(BoardFlashPainter oldDelegate) {
    return (
      this.tileSideLength != oldDelegate.tileSideLength
        || this.flashTiles != oldDelegate.flashTiles
    );
  }
}

class BoardWidget extends StatefulWidget {
  final TableturfBattle battle;
  final double tileSize;

  const BoardWidget(this.battle, {
    super.key,
    required this.tileSize,
  });

  @override
  State<BoardWidget> createState() => _BoardWidgetState();
}

class _BoardWidgetState extends State<BoardWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flashController;
  late final Animation<double> flashOpacity;
  final ValueNotifier<bool> showSpecialDarken = ValueNotifier(false);

  @override
  void initState() {
    _flashController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this
    );
    _flashController.value = 1.0;
    flashOpacity = Tween(
      begin: 1.0,
      end: 0.0
    ).animate(_flashController);

    widget.battle.boardChangeNotifier.addListener(_runFlash);
    widget.battle.moveSpecialNotifier.addListener(_checkSpecialDarken);
    widget.battle.revealCardsNotifier.addListener(_clearSpecialDarken);
    super.initState();
  }

  void _runFlash() {
    _flashController.forward(from: 0.0);
  }

  void _checkSpecialDarken() {
    showSpecialDarken.value = widget.battle.moveSpecialNotifier.value;
  }

  void _clearSpecialDarken() {
    showSpecialDarken.value = false;
  }

  @override
  void dispose() {
    widget.battle.boardChangeNotifier.removeListener(_runFlash);
    _flashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: Listenable.merge([
              widget.battle.boardChangeNotifier,
              widget.battle.activatedSpecialsNotifier,
            ]),
            builder: (context, child) {
              return CustomPaint(
                painter: BoardPainter(
                  board: widget.battle.board,
                  activatedSpecials: widget.battle.activatedSpecialsNotifier.value,
                  tileSideLength: widget.tileSize,
                  specialButtonOn: showSpecialDarken,
                ),
                child: Container(),
                isComplex: true,
              );
            }
          ),
          AnimatedBuilder(
            animation: widget.battle.boardChangeNotifier,
            builder: (context, child) {
              return CustomPaint(
                painter: BoardFlashPainter(
                  flashOpacity,
                  widget.battle.boardChangeNotifier.value,
                  widget.tileSize
                ),
                child: Container(),
              );
            }
          ),
        ],
      )
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