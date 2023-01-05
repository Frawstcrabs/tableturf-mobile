import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:tableturf_mobile/src/audio/audio_controller.dart';
import 'package:tableturf_mobile/src/audio/sounds.dart';
import 'package:tableturf_mobile/src/game_internals/battle.dart';

class CircularArcOffsetTween extends Tween<Offset> {
  bool _clockwise;
  double _angle;

  bool _dirty = true;
  Offset? _center;
  double? _beginAngle;
  double? _radius;

  CircularArcOffsetTween({
    super.begin,
    super.end,
    required angle,
    clockwise = true,
  }): _angle = angle, _clockwise = clockwise;

  void _initialise() {
    assert(this.begin != null);
    assert(this.end != null);
    assert(this._angle >= 0.0);
    assert(this._angle <= (2*pi));

    final begin = this.begin!;
    final end = this.end!;

    final pointAngle = (end - begin).direction;
    final midpoint = (end + begin) / 2;
    final distanceToMid = (end - begin).distance / 2;
    late final double distMidToCenter;
    late final double newRadius;
    bool effectiveClockwise = this._clockwise;
    if (this._angle > pi) {
      effectiveClockwise = !effectiveClockwise;
      final tempAngle = (2*pi) - this._angle;
      distMidToCenter = distanceToMid / tan(tempAngle / 2);
      newRadius = distanceToMid / sin(tempAngle / 2);
    } else {
      distMidToCenter = distanceToMid / tan(this._angle / 2);
      newRadius = distanceToMid / sin(this._angle / 2);
    }
    final toCenterOffset = Offset(
      distMidToCenter * cos(pointAngle + (pi/2)),
      distMidToCenter * sin(pointAngle + (pi/2)),
    ) * (effectiveClockwise ? 1 : -1);
    final newCenter = midpoint + toCenterOffset;
    _beginAngle = (begin - newCenter).direction;
    _center = newCenter;
    _radius = newRadius;

    print("begin $begin, end $end\ndistanceToMid $distanceToMid\npointAngle $pointAngle\nangle $_angle\ndistMidToCenter $distMidToCenter, newRadius $newRadius\ncenter $_center");

    _dirty = false;
  }

  @override
  set begin(Offset? value) {
    if (value != begin) {
      super.begin = value;
      _dirty = true;
    }
  }

  @override
  set end(Offset? value) {
    if (value != end) {
      super.end = value;
      _dirty = true;
    }
  }

  double get angle => _angle;

  set angle(double value) {
    if (value != _angle) {
      this._angle = value;
      _dirty = true;
    }
  }

  bool get clockwise => _clockwise;

  set clockwise(bool value) {
    if (value != _clockwise) {
      this._clockwise = _clockwise;
      _dirty = true;
    }
  }

  @override
  Offset lerp(double t) {
    if (_dirty) {
      _initialise();
    }
    final beginAngle = _beginAngle!;
    final endAngle = beginAngle + _angle * (_clockwise ? 1 : -1);
    final curAngle = lerpDouble(beginAngle, endAngle, t)!;
    final x = cos(curAngle) * _radius!;
    final y = sin(curAngle) * _radius!;
    return _center! + Offset(x, y);
  }
}

class AnimationSwitcher<T> extends Animatable<T> {
  final double switchPoint;
  final Animatable<T> first, second;

  const AnimationSwitcher({
    required this.switchPoint,
    required this.first,
    required this.second,
  });

  @override
  T transform(double t) {
    if (t < switchPoint) {
      return first.transform(t);
    } else {
      return second.transform(t);
    }
  }
}

class CardDeck extends StatefulWidget {
  final TableturfBattle battle;
  const CardDeck({super.key, required this.battle});

  @override
  State<CardDeck> createState() => _CardDeckState();
}

class _CardDeckState extends State<CardDeck>
    with TickerProviderStateMixin {
  late final AnimationController _shuffleController;
  late final Animation<Offset> shuffleTopCardMove, shuffleBottomCardMove;

  late final AnimationController _dealController;
  late final Animation<Offset> dealCardOffset;
  late final Animation<double> dealCardRotate;

  late final AnimationController _scaleController;
  late final Animation<double> scaleDeckValue;
  late final Animation<Color?> scaleDeckColour;

  static const DECK_SPACING = Offset(0, -0.05);

  @override
  void initState() {
    super.initState();
    _shuffleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this
    );
    final startOffset = DECK_SPACING * 2;
    final endOffset = DECK_SPACING * -2;
    final topTween = CircularArcOffsetTween(
      begin: startOffset,
      end: endOffset,
      clockwise: false,
      angle: pi*1.4
    ).chain(CurveTween(curve: Curves.ease));
    final bottomTween = Tween(
      begin: endOffset,
      end: startOffset,
    ).chain(CurveTween(curve: Curves.easeInOutBack));

    const switchPoint = 0.4;
    shuffleTopCardMove = AnimationSwitcher(
      switchPoint: switchPoint,
      first: topTween,
      second: bottomTween,
    ).animate(_shuffleController);
    shuffleBottomCardMove = AnimationSwitcher(
      switchPoint: switchPoint,
      first: bottomTween,
      second: topTween,
    ).animate(_shuffleController);

    _dealController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    dealCardOffset = TweenSequence([
      TweenSequenceItem(
        tween: ConstantTween(Offset.zero),
        weight: 1
      ),
      TweenSequenceItem(
        tween: ConstantTween(Offset(0.03, -0.09)),
        weight: 99
      ),
    ]).animate(_dealController);
    const defaultRotation = -0.025;
    dealCardRotate = Tween(
      begin: defaultRotation,
      end: defaultRotation * 2.5,
    )
      .chain(CurveTween(curve: Curves.decelerate))
      .animate(_dealController);

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    scaleDeckValue = Tween(
      begin: 0.6,
      end: 1.0,
    ).animate(_scaleController);
    scaleDeckColour = ColorTween(
      begin: const Color.fromRGBO(0, 0, 0, 0.3),
      end: const Color.fromRGBO(0, 0, 0, 0.0),
    )
        .chain(CurveTween(curve: Curves.easeOut))
        .animate(_scaleController);
  }

  @override
  void dispose() {
    _shuffleController.dispose();
    _dealController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _playDealAnimation() async {
    final audioController = AudioController();
    await _scaleController.forward(from: 0.0);
    await Future<void>.delayed(const Duration(milliseconds: 200));
    audioController.playSfx(SfxType.dealHand);
    await _shuffleController.forward(from: 0.0);
    await _shuffleController.forward(from: 0.0);
    await _shuffleController.forward(from: 0.0);
    await Future<void>.delayed(const Duration(milliseconds: 200));
    await _dealController.forward(from: 0.0);
    await _dealController.reverse(from: 1.0);
    await Future<void>.delayed(const Duration(milliseconds: 1000));
    await _scaleController.reverse(from: 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: GestureDetector(
        onTap: _playDealAnimation,
        child: RepaintBoundary(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              print(constraints);
              return Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.4),
                ),
                child: Center(
                  child: AnimatedBuilder(
                    animation: _scaleController,
                    builder: (_, __) => Transform.scale(
                      scale: scaleDeckValue.value,
                      child: Stack(
                        children: [
                          AnimatedBuilder(
                            animation: Listenable.merge([
                              _shuffleController,
                              _dealController,
                              _scaleController,
                            ]),
                            child: Stack(
                              children: [
                                Transform.translate(
                                  offset: (DECK_SPACING * -1) * width,
                                  child: Image.asset(widget.battle.yellow.cardSleeve),
                                ),
                                Transform.translate(
                                  offset: (DECK_SPACING * 1) * width,
                                  child: Image.asset(widget.battle.yellow.cardSleeve),
                                ),
                              ]
                            ),
                            builder: (_, child) => Transform.rotate(
                              angle: dealCardRotate.value * 2 * pi,
                              child: ColorFiltered(
                                colorFilter: ColorFilter.mode(
                                  scaleDeckColour.value!,
                                  BlendMode.srcATop,
                                ),
                                child: Stack(
                                  children: [
                                    Transform.translate(
                                      offset: shuffleBottomCardMove.value * width,
                                      child: ColorFiltered(
                                        colorFilter: ColorFilter.mode(
                                          const Color.fromRGBO(0, 0, 0, 0.5),
                                          BlendMode.srcATop,
                                        ),
                                        child: child,
                                      ),
                                    ),
                                    Transform.translate(
                                      offset: (shuffleTopCardMove.value + dealCardOffset.value) * width,
                                      child: child,
                                    ),
                                  ]
                                ),
                              ),
                            )
                          ),
                          FractionallySizedBox(
                            heightFactor: 0.3,
                            widthFactor: 0.4,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.black54
                              ),
                              child: Text("15"),
                            )
                          )
                        ],
                      ),
                    )
                  ),
                )
              );
            }
          ),
        )
      ),
    );
  }
}
