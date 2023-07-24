import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/src/rendering/object.dart';

class FlipCard extends StatelessWidget {
  final Widget front;
  final Widget back;

  final double skew;

  final Axis axis;
  final AlignmentGeometry alignment;

  static final _rotation = TweenSequence(
    [
      TweenSequenceItem<double>(
        tween: Tween(begin: 0.0, end: pi / 2)
            .chain(CurveTween(curve: Curves.easeInSine)),
        weight: 50.0,
      ),
      TweenSequenceItem<double>(
        tween: Tween(begin: -pi / 2, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOutSine)),
        weight: 50.0,
      ),
    ],
  );

  FlipCard({
    super.key,
    required this.front,
    required this.back,
    required this.skew,
    this.axis = Axis.horizontal,
    this.alignment = Alignment.center,
  });

  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      fit: StackFit.passthrough,
      children: <Widget>[
        Visibility.maintain(
          visible: skew < 0.5,
          child: _buildContent(front)
        ),
        Visibility.maintain(
          visible: skew > 0.5,
          child: _buildContent(back)
        ),
      ],
    );
  }

  Widget _buildContent(Widget side) {
    var transform = Matrix4.identity();
    transform.setEntry(3, 2, 0.001);
    if (axis == Axis.vertical) {
      transform.rotateX(_rotation.transform(skew));
    } else {
      transform.rotateY(_rotation.transform(skew));
    }
    return Transform(
      transform: transform,
      alignment: alignment,
      child: side,
    );
  }
}

class FlipTransitionPainter extends SnapshotPainter {
  final Animation<double> skew;

  final Axis axis;
  final bool isFront;
  final Alignment alignment;
  FlipTransitionPainter({
    required this.skew,
    required this.axis,
    required this.isFront,
    this.alignment = Alignment.center,
  }) {
    skew.addListener(notifyListeners);
  }

  @override
  void dispose() {
    skew.removeListener(notifyListeners);
    super.dispose();
  }

  @override
  void paint(
      PaintingContext context,
      Offset offset,
      Size size,
      PaintingContextCallback painter) {
    final skew = this.skew.value;
    if (isFront ? (skew < 0.5) : (skew > 0.5)) {
      // currently viewing other side
      return;
    }
    final transform = Matrix4.identity();
    transform.setEntry(3, 2, 0.001);
    if (axis == Axis.vertical) {
      transform.rotateX(FlipCard._rotation.transform(skew));
    } else {
      transform.rotateY(FlipCard._rotation.transform(skew));
    }
    final alignmentOffset = alignment.alongSize(size);
    final result = Matrix4.identity();
    result.translate(alignmentOffset.dx, alignmentOffset.dy);
    result.multiply(transform);
    result.translate(-alignmentOffset.dx, -alignmentOffset.dy);

    context.canvas.save();
    context.canvas.transform(result.storage);
    painter(context, offset);
    context.canvas.restore();
  }

  @override
  void paintSnapshot(
      PaintingContext context,
      Offset offset,
      Size size,
      ui.Image image,
      Size sourceSize,
      double pixelRatio) {
    final skew = this.skew.value;
    if (isFront ? (skew < 0.5) : (skew > 0.5)) {
      // currently viewing other side
      return;
    }
    final transform = Matrix4.identity();
    transform.setEntry(3, 2, 0.001);
    if (axis == Axis.vertical) {
      transform.rotateX(FlipCard._rotation.transform(skew));
    } else {
      transform.rotateY(FlipCard._rotation.transform(skew));
    }
    final alignmentOffset = alignment.alongSize(size);
    final result = Matrix4.identity();
    result.translate(alignmentOffset.dx, alignmentOffset.dy);
    result.multiply(transform);
    result.translate(-alignmentOffset.dx, -alignmentOffset.dy);
    final Rect src = Offset.zero & sourceSize;
    final Rect dst = offset & size;
    final Paint paint = Paint()
      ..filterQuality = FilterQuality.low;

    context.canvas.save();
    context.canvas.transform(result.storage);
    context.canvas.drawImageRect(image, src, dst, paint);
    context.canvas.restore();
  }

  @override
  bool shouldRepaint(FlipTransitionPainter other) {
    return skew != other.skew
        || axis != other.axis
        || alignment != other.alignment
        || isFront != other.isFront;
  }

}

class FlipTransition extends StatefulWidget {
  final Widget front;
  final Widget back;

  final Animation<double> skew;

  final Axis axis;
  FlipTransition({
    super.key,
    required this.front,
    required this.back,
    required this.skew,
    this.axis = Axis.horizontal,
  });

  @override
  State<FlipTransition> createState() => _FlipTransitionState();
}

class _FlipTransitionState extends State<FlipTransition> {
  final SnapshotController snapshotController = SnapshotController();

  @override
  void initState() {
    super.initState();
    widget.skew.addStatusListener(_checkAnimStatus);
  }

  @override
  void dispose() {
    widget.skew.removeStatusListener(_checkAnimStatus);
    super.dispose();
  }

  void _checkAnimStatus(AnimationStatus status) {
    switch (status) {
      case AnimationStatus.dismissed:
      case AnimationStatus.completed:
        snapshotController.allowSnapshotting = false;
        break;
      default:
        snapshotController.allowSnapshotting = true;
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        alignment: Alignment.center,
        fit: StackFit.passthrough,
        children: [
          SnapshotWidget(
            controller: snapshotController,
            painter: FlipTransitionPainter(
              skew: widget.skew,
              axis: widget.axis,
              isFront: false,
            ),
            child: widget.back,
          ),
          SnapshotWidget(
            controller: snapshotController,
            painter: FlipTransitionPainter(
              skew: widget.skew,
              axis: widget.axis,
              isFront: true,
            ),
            child: widget.front,
          ),
        ]
      )
    );
  }
}
