import 'dart:math';

import 'package:flutter/material.dart';

enum FlipDirection {
  VERTICAL,
  HORIZONTAL,
}

class FlipCard extends StatelessWidget {
  final Widget front;
  final Widget back;

  final double skew;

  final FlipDirection direction;
  final Alignment alignment;

  final _frontRotation = TweenSequence(
    [
      TweenSequenceItem<double>(
        tween: Tween(begin: 0.0, end: pi / 2)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50.0,
      ),
      TweenSequenceItem<double>(
        tween: ConstantTween<double>(pi / 2),
        weight: 50.0,
      ),
    ],
  );
  final _backRotation = TweenSequence(
    [
      TweenSequenceItem<double>(
        tween: ConstantTween<double>(pi / 2),
        weight: 50.0,
      ),
      TweenSequenceItem<double>(
        tween: Tween(begin: -pi / 2, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50.0,
      ),
    ],
  );

  FlipCard({
    super.key,
    required this.front,
    required this.back,
    required this.skew,
    this.alignment = Alignment.center,
    this.direction = FlipDirection.HORIZONTAL,
  });

  Widget build(BuildContext context) {
    return Stack(
      alignment: alignment,
      fit: StackFit.passthrough,
      children: <Widget>[
        _buildContent(true),
        _buildContent(false),
      ],
    );
  }

  Widget _buildContent(bool viewFront) {
    final animation = viewFront ? _frontRotation : _backRotation;
    var transform = Matrix4.identity();
    transform.setEntry(3, 2, 0.001);
    if (direction == FlipDirection.VERTICAL) {
      transform.rotateX(animation.transform(skew));
    } else {
      transform.rotateY(animation.transform(skew));
    }
    return Transform(
      transform: transform,
      alignment: Alignment.center,
      child: viewFront ? front : back,
    );
  }
}
