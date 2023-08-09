import 'dart:async';

import 'package:flutter/material.dart';



class AlertPopup extends StatefulWidget {
  final Widget Function(BuildContext, double) builder;
  const AlertPopup({
    super.key,
    required this.builder,
  });

  @override
  State<AlertPopup> createState() => _AlertPopupState();
}

class _AlertPopupState extends State<AlertPopup>
    with TickerProviderStateMixin {
  bool finishedAnimation = false;

  late final AnimationController transitionController;
  late final Animation<double> transitionOpacity, transitionScale, transitionRotate;
  late final Animation<Offset> transitionOffset;

  @override
  void initState() {
    super.initState();
    transitionController = AnimationController(
        duration: const Duration(milliseconds: 400),
        vsync: this
    );
    transitionOpacity = TweenSequence([
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 1.0),
          weight: 50
      ),
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.0),
          weight: 50
      ),
    ]).animate(transitionController);
    transitionScale = TweenSequence([
      TweenSequenceItem(
          tween: Tween(begin: 0.9, end: 1.0),
          weight: 50
      ),
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.9),
          weight: 50
      ),
    ]).animate(transitionController);
    transitionOffset = ConstantTween(Offset.zero).animate(transitionController);
    const defaultRotate = -0.0025;
    transitionRotate = ConstantTween(defaultRotate).animate(transitionController);

    transitionController.animateTo(0.5);
  }

  @override
  void dispose() {
    transitionController..stop()..dispose();
    super.dispose();
  }

  Future<void> onExit() async {
    await transitionController.forward();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;

    final promptBox = FractionallySizedBox(
      heightFactor: isLandscape ? 0.5 : null,
      widthFactor: isLandscape ? null : 0.8,
      child: AspectRatio(
        aspectRatio: 3/2,
        child: LayoutBuilder(
            builder: (context, constraints) {
              const designWidth = 646;
              final designRatio = constraints.maxWidth / designWidth;
              final content = widget.builder(context, designRatio);
              return DefaultTextStyle(
                style: TextStyle(
                  fontFamily: "Splatfont2",
                  color: Colors.white,
                  fontSize: 25 * designRatio,
                ),
                child: SlideTransition(
                  position: transitionOffset,
                  child: ScaleTransition(
                    scale: transitionScale,
                    child: RotationTransition(
                      turns: transitionRotate,
                      child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.grey[850],
                            borderRadius: BorderRadius.circular(60 * designRatio),
                          ),
                          child: Center(
                            child: content,
                          )
                      ),
                    ),
                  ),
                ),
              );
            },
        ),
      ),
    );
    return WillPopScope(
      onWillPop: () async {
        onExit();
        return false;
      },
      child: GestureDetector(
        onTap: onExit,
        child: FadeTransition(
          opacity: transitionOpacity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  Colors.black38,
                  Colors.black54,
                ],
                radius: 1.3,
              ),
            ),
            child: Align(
              alignment: Alignment.center,
              child: promptBox,
            ),
          ),
        ),
      ),
    );
  }
}


Future<void> showAlert(BuildContext context, {
  required Widget Function(BuildContext, double) builder,
}) async {
  await Navigator.of(context).push(PageRouteBuilder(
    opaque: false,
    pageBuilder: (_, __, ___) {
      return AlertPopup(
        builder: builder,
      );
    }
  ));
}