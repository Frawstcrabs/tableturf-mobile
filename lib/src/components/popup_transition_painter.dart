import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class PopupTransitionPainter extends SnapshotPainter {
  final Animation<double> popupScale, popupOpacity;
  PopupTransitionPainter({
    required this.popupScale,
    required this.popupOpacity
  }) {
    popupScale.addListener(notifyListeners);
    popupOpacity.addListener(notifyListeners);
  }

  @override
  void dispose() {
    popupScale.removeListener(notifyListeners);
    popupOpacity.removeListener(notifyListeners);
    super.dispose();
  }

  @override
  void paint(
      PaintingContext context,
      Offset offset,
      Size size,
      PaintingContextCallback painter) {
    if (popupScale.value == 1.0 && popupOpacity.value == 1.0) {
      painter(context, offset);
      return;
    }
    //final scaledSize = size * popupScale.value;
    final scaledOffsetFactor = ((1 - popupScale.value) / 2);
    final scaledOffset = Offset(size.width * scaledOffsetFactor, size.height * scaledOffsetFactor);
    context.canvas.saveLayer(
        offset & size,
        Paint()..color = Color.fromRGBO(0, 0, 0, popupOpacity.value)
    );
    context.canvas.scale(popupScale.value);
    context.canvas.translate(scaledOffset.dx, scaledOffset.dy);
    painter(context, offset + scaledOffset);
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
    final scaledSize = size * popupScale.value;
    final scaledOffsetFactor = ((1 - popupScale.value) / 2);
    final scaledOffset = Offset(size.width * scaledOffsetFactor, size.height * scaledOffsetFactor);

    final Rect src = Offset.zero & sourceSize;
    final Rect dst = (offset + scaledOffset) & scaledSize;
    final Paint paint = Paint()
      ..filterQuality = FilterQuality.low
      ..color = Color.fromRGBO(0, 0, 0, popupOpacity.value);
    context.canvas.drawImageRect(image, src, dst, paint);
  }

  @override
  bool shouldRepaint(PopupTransitionPainter other) {
    return popupScale != other.popupScale
        || popupOpacity != other.popupOpacity;
  }

}
