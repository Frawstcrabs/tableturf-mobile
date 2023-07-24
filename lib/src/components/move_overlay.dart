import 'dart:math';

import 'package:flutter/material.dart';

import 'package:tableturf_mobile/src/game_internals/battle.dart';
import 'package:tableturf_mobile/src/game_internals/card.dart';
import 'package:tableturf_mobile/src/game_internals/tile.dart';

class MoveOverlayPainter extends CustomPainter {
  final TableturfBattle battle;
  final Animation<double> animation;
  final double tileSideLength;

  static const drawComplex = true;
  static const STRIPE_RATIO = 0.5;

  static const DOT_ANGLE = 0.35204;
  static final DOT_OFFSET_X = Offset(
    cos(DOT_ANGLE),
    -sin(DOT_ANGLE),
  );
  static final DOT_OFFSET_Y = Offset(
    sin(DOT_ANGLE),
    cos(DOT_ANGLE),
  );

  MoveOverlayPainter(this.battle, this.animation, this.tileSideLength):
    super(
      repaint: Listenable.merge([
        animation,
        battle.moveCardNotifier,
        battle.moveRotationNotifier,
        battle.moveLocationNotifier,
        battle.moveIsValidNotifier,
        battle.movePassNotifier,
        battle.revealCardsNotifier,
      ])
    )
  ;

  void _paintBasic(Canvas canvas) {
    final card = battle.moveCardNotifier.value;
    final rot = battle.moveRotationNotifier.value;
    final location = battle.moveLocationNotifier.value;
    final isValid = battle.moveIsValidNotifier.value;
    final isPassed = battle.movePassNotifier.value;
    final isRevealed = battle.revealCardsNotifier.value;

    if (card == null || location == null || isRevealed || isPassed) {
      return;
    }

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
    final drawLocation = Coords(location.x - selectPoint.x, location.y - selectPoint.y);

    final bodyPaint = Paint()
      ..style = PaintingStyle.fill
      ..strokeJoin = StrokeJoin.miter;

    for (var y = 0; y < pattern.length; y++) {
      for (var x = 0; x < pattern[0].length; x++) {
        final tile = pattern[y][x];
        if (tile == TileState.unfilled) continue;

        if (isValid) {
          bodyPaint.color = tile == TileState.yellow ? const Color.fromRGBO(255, 255, 17, 0.5)
              : tile == TileState.yellowSpecial ? const Color.fromRGBO(255, 159, 4, 0.5)
              : Color.fromRGBO(0, 0, 0, 0);
        } else {
          bodyPaint.color = tile == TileState.yellow ? const Color.fromRGBO(255, 255, 255, 0.5)
              : tile == TileState.yellowSpecial ? const Color.fromRGBO(170, 170, 170, 0.5)
              : Color.fromRGBO(0, 0, 0, 0);
        }
        final tileRect = Rect.fromLTWH(
            (drawLocation.x + x) * tileSideLength,
            (drawLocation.y + y) * tileSideLength,
            tileSideLength,
            tileSideLength
        );
        canvas.drawRect(tileRect, bodyPaint);
        //canvas.drawRect(tileRect, edgePaint);
      }
    }
  }

  void _paintComplex(Canvas canvas) {
    final card = battle.moveCardNotifier.value;
    final rot = battle.moveRotationNotifier.value;
    final location = battle.moveLocationNotifier.value;
    final isValid = battle.moveIsValidNotifier.value;
    final isPassed = battle.movePassNotifier.value;
    final isRevealed = battle.revealCardsNotifier.value;

    if (card == null || location == null || isRevealed || isPassed) {
      return;
    }

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
    final drawLocation = Coords(location.x - selectPoint.x, location.y - selectPoint.y);

    final bodyPaint = Paint()
      ..style = PaintingStyle.fill
      ..strokeJoin = StrokeJoin.miter;

    final normalColour = isValid
        ? const Color.fromRGBO(255, 255, 17, 0.8)
        : const Color.fromRGBO(255, 255, 255, 0.8);
    final specialColour = isValid
        ? const Color.fromRGBO(255, 159, 4, 0.8)
        : const Color.fromRGBO(255, 255, 255, 0.8);

    /*
    final patternClipPath = Path();

    for (var y = 0; y < pattern.length; y++) {
      for (var x = 0; x < pattern[0].length; x++) {
        final tile = pattern[y][x];
        if (tile == TileState.unfilled) continue;
        final tileRect = Rect.fromLTWH(
            (drawLocation.x + x) * tileSideLength,
            (drawLocation.y + y) * tileSideLength,
            tileSideLength,
            tileSideLength
        );
        patternClipPath.addRect(tileRect);
      }
    }
    canvas.clipPath(patternClipPath);
    */
    canvas.save();

    final normalClipPath = Path();

    for (var y = 0; y < pattern.length; y++) {
      for (var x = 0; x < pattern[0].length; x++) {
        final tile = pattern[y][x];
        if (tile != TileState.yellow) continue;
        final tileRect = Rect.fromLTWH(
            (drawLocation.x + x) * tileSideLength,
            (drawLocation.y + y) * tileSideLength,
            tileSideLength,
            tileSideLength
        );
        normalClipPath.addRect(tileRect);
      }
    }
    canvas.clipPath(normalClipPath);

    final colourStripeWidth = tileSideLength * (1/2.25);
    final stripeWidth = pattern[0].length * tileSideLength;
    final allStripesPath = Path();
    var stripePath = Path()
      ..moveTo(0.0, 0.0)
      ..lineTo(stripeWidth, -stripeWidth)
      ..lineTo(stripeWidth, -stripeWidth + (colourStripeWidth * STRIPE_RATIO))
      ..lineTo(0.0, colourStripeWidth * STRIPE_RATIO)
      ..close();
    stripePath = stripePath.shift(
        Offset(
            drawLocation.x * tileSideLength,
            drawLocation.y * tileSideLength + (colourStripeWidth * (animation.value - 1))
        )
    );
    bodyPaint.color = normalColour;
    var stripeHeight = (pattern.length + pattern[0].length) * tileSideLength;
    for (var d = -colourStripeWidth; d <= stripeHeight; d += colourStripeWidth) {
      allStripesPath.addPath(stripePath, Offset.zero);
      stripePath = stripePath.shift(Offset(0, colourStripeWidth));
    }
    canvas.drawPath(allStripesPath, bodyPaint);
    canvas.restore();

    bodyPaint.color = specialColour;
    const sideDotCount = 4.0;
    final dotWidth = tileSideLength * (1/(sideDotCount * 4));
    for (var y = 0; y < pattern.length; y++) {
      for (var x = 0; x < pattern[0].length; x++) {
        final tile = pattern[y][x];
        if (tile != TileState.yellowSpecial) continue;
        canvas.save();
        canvas.clipRect(Rect.fromLTWH(
          (drawLocation.x + x) * tileSideLength,
          (drawLocation.y + y) * tileSideLength,
          tileSideLength,
          tileSideLength
        ));
        final dotCenter = Offset(
          (drawLocation.x + x + 0.5),
          (drawLocation.y + y + 0.5),
        );
        for (var dy = -3; dy <= 2; dy++) {
          for (var dx = -3; dx <= 2; dx++) {
            final dotLocation = (
                dotCenter
                    + (DOT_OFFSET_X * ((dx + animation.value) / sideDotCount))
                    + (DOT_OFFSET_Y * ((dy + animation.value) / sideDotCount))
            ) * tileSideLength;
            canvas.drawCircle(dotLocation, dotWidth, bodyPaint);
          }
        }
        canvas.restore();
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (drawComplex) {
      _paintComplex(canvas);
    } else {
      _paintBasic(canvas);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }

}

class MoveOverlayWidget extends StatefulWidget {
  final TableturfBattle battle;
  final double tileSize;
  final bool loopAnimation;

  const MoveOverlayWidget(this.battle, {required this.tileSize, required this.loopAnimation});

  @override
  State<MoveOverlayWidget> createState() => _MoveOverlayWidgetState();
}

class _MoveOverlayWidgetState extends State<MoveOverlayWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this
    );
    widget.battle.moveCardNotifier.addListener(_checkHasMove);
    widget.battle.moveRotationNotifier.addListener(_checkHasMove);
    widget.battle.moveLocationNotifier.addListener(_checkHasMove);
    widget.battle.moveIsValidNotifier.addListener(_checkHasMove);
    widget.battle.movePassNotifier.addListener(_checkHasMove);
    widget.battle.revealCardsNotifier.addListener(_checkHasMove);
  }

  void _checkHasMove() {
    final card = widget.battle.moveCardNotifier.value;
    final location = widget.battle.moveLocationNotifier.value;
    final isPassed = widget.battle.movePassNotifier.value;
    final isRevealed = widget.battle.revealCardsNotifier.value;

    if (card == null || location == null || isRevealed || isPassed) {
      if (_animationController.status != AnimationStatus.dismissed) {
        _animationController.stop();
        _animationController.value = 0.0;
      }
    } else {
      if (_animationController.status != AnimationStatus.forward && widget.loopAnimation) {
        _animationController.value = 0.0;
        _animationController.repeat();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    widget.battle.moveCardNotifier.removeListener(_checkHasMove);
    widget.battle.moveRotationNotifier.removeListener(_checkHasMove);
    widget.battle.moveLocationNotifier.removeListener(_checkHasMove);
    widget.battle.moveIsValidNotifier.removeListener(_checkHasMove);
    widget.battle.movePassNotifier.removeListener(_checkHasMove);
    widget.battle.revealCardsNotifier.removeListener(_checkHasMove);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: IgnorePointer(
        child: CustomPaint(
          painter: MoveOverlayPainter(
            widget.battle,
            _animationController,
            widget.tileSize
          ),
          child: Container(),
          willChange: true,
        )
      ),
    );
  }
}