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

  final _rotation = TweenSequence(
    [
      TweenSequenceItem<double>(
        tween: Tween(begin: 0.0, end: pi / 2)
            .chain(CurveTween(curve: Curves.easeIn)),
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
        Opacity(
          opacity: skew < 0.5 ? 1.0 : 0.0,
          child: _buildContent(front)
        ),
        Opacity(
          opacity: skew < 0.5 ? 0.0 : 1.0,
          child: _buildContent(back)
        ),
      ],
    );
  }

  Widget _buildContent(Widget side) {
    var transform = Matrix4.identity();
    transform.setEntry(3, 2, 0.001);
    if (direction == FlipDirection.VERTICAL) {
      transform.rotateX(_rotation.transform(skew));
    } else {
      transform.rotateY(_rotation.transform(skew));
    }
    return Transform(
      transform: transform,
      alignment: Alignment.center,
      child: side,
    );
  }
}
