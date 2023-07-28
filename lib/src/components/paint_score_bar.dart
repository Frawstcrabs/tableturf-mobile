import 'package:flutter/material.dart';

void paintScoreBar({
  required Canvas canvas,
  required Size size,
  required Animation<double> length,
  required Animation<double> waveAnimation,
  required AxisDirection direction,
  required Paint paint,
  double waveWidth = 0.3,
  double waveHeight = 0.4,
}) {
  const OVERPAINT = 5.0;

  waveWidth *= (direction == AxisDirection.up || direction == AxisDirection.down ? size.width : size.height);
  waveHeight *= waveWidth;
  final overpaint_offset = OVERPAINT + waveHeight;
  final path = Path();

  switch (direction) {
    case AxisDirection.up:
      var d = size.width + (waveWidth * 2) * (1 - waveAnimation.value) + overpaint_offset;
      path.moveTo(-overpaint_offset, size.height + overpaint_offset);
      path.lineTo(size.width + overpaint_offset, size.height + overpaint_offset);
      path.lineTo(d, size.height * (1.0 - length.value));
      var outWave = true;

      for (; d > -overpaint_offset; d -= waveWidth) {
        path.relativeQuadraticBezierTo(
          -waveWidth/2, outWave ? waveHeight : -waveHeight,
          -waveWidth, 0.0,
        );
        outWave = !outWave;
      }
      break;
    case AxisDirection.right:
      var d = (waveWidth * -2) * (1 - waveAnimation.value) - overpaint_offset;
      path.moveTo(size.width + overpaint_offset, size.height + overpaint_offset);
      path.lineTo(size.width + overpaint_offset, -overpaint_offset);
      path.lineTo(size.width * (1.0 - length.value), d);
      var outWave = true;

      for (; d < size.height + overpaint_offset; d += waveWidth) {
        path.relativeQuadraticBezierTo(
          outWave ? waveHeight : -waveHeight, waveWidth/2,
          0.0, waveWidth,
        );
        outWave = !outWave;
      }
      break;
    case AxisDirection.down:
      var d = size.width + (waveWidth * 2) * (1 - waveAnimation.value) + overpaint_offset;
      path.moveTo(-overpaint_offset,-overpaint_offset);
      path.lineTo(size.width + overpaint_offset, -overpaint_offset);
      path.lineTo(d, size.height * length.value);
      var outWave = true;

      for (; d > - overpaint_offset; d -= waveWidth) {
        path.relativeQuadraticBezierTo(
          -waveWidth/2, outWave ? waveHeight : -waveHeight,
          -waveWidth, 0.0,
        );
        outWave = !outWave;
      }
      break;
    case AxisDirection.left:
      var d = (waveWidth * -2) * (1 - waveAnimation.value) - overpaint_offset;
      path.moveTo(-overpaint_offset, -overpaint_offset);
      path.lineTo(size.width * length.value, d);
      var outWave = true;

      for (; d < size.height + overpaint_offset; d += waveWidth) {
        path.relativeQuadraticBezierTo(
          outWave ? waveHeight : -waveHeight, waveWidth/2,
          0.0, waveWidth,
        );
        outWave = !outWave;
      }
      path.lineTo(-overpaint_offset, size.height + overpaint_offset);
      break;
  }
  path.close();
  canvas.drawPath(path, paint);
}