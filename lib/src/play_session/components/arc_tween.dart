import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

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
    required double angle,
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