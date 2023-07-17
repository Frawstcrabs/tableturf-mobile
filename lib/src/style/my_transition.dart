// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';

PageRouteBuilder<T> buildMyTransition<T>({
  required Widget child,
  required Color color,
  String? name,
  String? restorationId,
  Duration transitionDuration = const Duration(milliseconds: 400),
  Duration reverseTransitionDuration = const Duration(milliseconds: 400),
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
    transitionDuration: transitionDuration,
    reverseTransitionDuration: reverseTransitionDuration,
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
  static const _clearDecoration = BoxDecoration(color: Colors.transparent);
  static const _opaqueDecoration = BoxDecoration(color: Colors.black);
  final blackScreenTween = TweenSequence([
    TweenSequenceItem(
      tween: DecorationTween(begin: _clearDecoration, end: _opaqueDecoration),
      weight: 20,
    ),
    TweenSequenceItem(
      tween: ConstantTween(_opaqueDecoration),
      weight: 60,
    ),
    TweenSequenceItem(
      tween: DecorationTween(begin: _opaqueDecoration, end: _clearDecoration),
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
          child: DecoratedBoxTransition(
            decoration: blackScreenTween.animate(widget.animation),
            child: SizedBox.expand(),
          ),
        ),
      ],
    );
  }
}
