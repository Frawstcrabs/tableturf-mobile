// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';

PageRouteBuilder<T> buildMyTransition<T>({
  required Widget child,
  required Color color,
  String? name,
  Object? arguments,
  String? restorationId,
  LocalKey? key,
}) {
  return PageRouteBuilder<T>(
    pageBuilder: (_, __, ___) => child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeToBlackTransition(
        animation: animation,
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 400),
  );
}

class FadeToBlackTransition extends StatefulWidget {
  final Widget child;

  final Animation<double> animation;

  const FadeToBlackTransition({
    required this.child,
    required this.animation,
  });

  @override
  State<FadeToBlackTransition> createState() => _FadeToBlackTransitionState();
}

class _FadeToBlackTransitionState extends State<FadeToBlackTransition> {
  final blackScreenTween = TweenSequence([
    TweenSequenceItem(
      tween: Tween(begin: 0.0, end: 1.0),
      weight: 20,
    ),
    TweenSequenceItem(
      tween: ConstantTween(1.0),
      weight: 60,
    ),
    TweenSequenceItem(
      tween: Tween(begin: 1.0, end: 0.0),
      weight: 20,
    ),
  ]);

  final widgetScreenTween = TweenSequence([
    TweenSequenceItem(
      tween: ConstantTween(0.0),
      weight: 50,
    ),
    TweenSequenceItem(
      tween: ConstantTween(1.0),
      weight: 50,
    ),
  ]);

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        FadeTransition(
          opacity: widgetScreenTween.animate(widget.animation),
          child: widget.child,
        ),
        IgnorePointer(
          child: FadeTransition(
            opacity: blackScreenTween.animate(widget.animation),
            child: Container(color: Colors.black),
          ),
        ),
      ],
    );
  }
}
