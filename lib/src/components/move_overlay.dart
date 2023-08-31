import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:tableturf_mobile/src/game_internals/battle.dart';
import 'package:tableturf_mobile/src/game_internals/card.dart';
import 'package:tableturf_mobile/src/game_internals/tile.dart';

import 'tableturf_battle.dart';

class MoveOverlayPainter extends CustomPainter {
  final TableturfBattleController controller;
  final Animation<double> animation;
  final ValueListenable<bool> isRevealed;
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

  MoveOverlayPainter(this.controller, this.animation, this.isRevealed, this.tileSideLength):
    super(
      repaint: Listenable.merge([
        animation,
        controller.moveCardNotifier,
        controller.moveRotationNotifier,
        controller.moveLocationNotifier,
        controller.moveIsValidNotifier,
        controller.movePassNotifier,
        isRevealed,
      ])
    )
  ;

  void _paintBasic(Canvas canvas) {
    final card = controller.moveCardNotifier.value;
    final rot = controller.moveRotationNotifier.value;
    final location = controller.moveLocationNotifier.value;
    final isValid = controller.moveIsValidNotifier.value;
    final isPassed = controller.movePassNotifier.value;
    final isRevealed = this.isRevealed.value;

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
    final card = controller.moveCardNotifier.value;
    final rot = controller.moveRotationNotifier.value;
    final location = controller.moveLocationNotifier.value;
    final isValid = controller.moveIsValidNotifier.value;
    final isPassed = controller.movePassNotifier.value;
    final isRevealed = this.isRevealed.value;

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
  final double tileSize;
  final bool loopAnimation;

  const MoveOverlayWidget({required this.tileSize, required this.loopAnimation});

  @override
  State<MoveOverlayWidget> createState() => _MoveOverlayWidgetState();
}

class _MoveOverlayWidgetState extends State<MoveOverlayWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final TableturfBattleController controller;
  late final StreamSubscription<BattleEvent> battleSubscription;
  final ValueNotifier<bool> isRevealed = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    controller = TableturfBattle.getControllerOf(context);
    battleSubscription = TableturfBattle.listen(context, _onBattleEvent);
    controller.moveChangeNotifier.addListener(_checkHasMove);
    isRevealed.addListener(_checkHasMove);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
  }

  Future<void> _onBattleEvent(BattleEvent event) async {
    switch (event) {
      case TurnStart():
        isRevealed.value = true;
      case TurnEnd():
        isRevealed.value = false;
    }
  }

  void _checkHasMove() {
    final card = controller.moveCardNotifier.value;
    final location = controller.moveLocationNotifier.value;
    final isPassed = controller.movePassNotifier.value;
    final isRevealed = this.isRevealed.value;

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
    controller.moveChangeNotifier.removeListener(_checkHasMove);
    isRevealed.removeListener(_checkHasMove);
    battleSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: IgnorePointer(
        child: CustomPaint(
          painter: MoveOverlayPainter(
            controller,
            _animationController,
            isRevealed,
            widget.tileSize
          ),
          child: Container(),
          willChange: true,
        )
      ),
    );
  }
}