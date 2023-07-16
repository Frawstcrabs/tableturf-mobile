

import 'dart:async';

import 'package:flutter/material.dart';
import 'selection_button.dart';


class SelectionBackgroundPainter extends CustomPainter {
  final Animation<double> waveAnimation;
  final Orientation orientation;

  static const WAVE_WIDTH = 1/8.5;
  static const WAVE_HEIGHT = 0.2;
  static const SCREEN_DIST = 0.7;

  SelectionBackgroundPainter({
    required this.waveAnimation,
    required this.orientation,
  }):
        super(repaint: waveAnimation)
  ;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(Colors.black38, BlendMode.srcOver);

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeJoin = StrokeJoin.miter
      ..color = Colors.black38;
    final waveWidth = size.height * WAVE_WIDTH;
    final waveHeight = waveWidth * WAVE_HEIGHT;
    final path = Path();

    var d = (waveWidth * -2) * (1 - waveAnimation.value);
    if (orientation == Orientation.landscape) {
      path.moveTo(size.width, size.height);
      path.lineTo(size.width, 0.0);
      path.lineTo(size.width * (1.0 - SCREEN_DIST), d);
      var outWave = true;

      for (; d < size.height; d += waveWidth) {
        path.relativeQuadraticBezierTo(
          outWave ? waveHeight : -waveHeight, waveWidth / 2,
          0.0, waveWidth,
        );
        outWave = !outWave;
      }
    } else {
      path.moveTo(size.width, 0.0);
      path.lineTo(0.0, 0.0);
      path.lineTo(d, size.height * SCREEN_DIST);
      //path.moveTo(size.width, size.height);
      //path.lineTo(size.width, 0.0);
      //path.lineTo(size.width * (1.0 - SCREEN_DIST), d);
      var outWave = true;

      for (; d < size.height; d += waveWidth) {
        path.relativeQuadraticBezierTo(
          waveWidth / 2, outWave ? waveHeight : -waveHeight,
          waveWidth, 0.0,
        );
        outWave = !outWave;
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(SelectionBackgroundPainter oldDelegate) {
    return this.orientation != oldDelegate.orientation;
  }
}

class _MultiChoiceOverlayController {
  late _MultiChoiceOverlayState state;
  Completer<void> stateLoaded = Completer();
}

class _MultiChoiceOverlay extends StatefulWidget {
  final String title;
  final List<String> options;
  final bool useWave;
  final _MultiChoiceOverlayController _controller;
  const _MultiChoiceOverlay({
    required this.title,
    required this.options,
    required this.useWave,
    required _MultiChoiceOverlayController controller
  }): _controller = controller;

  @override
  State<_MultiChoiceOverlay> createState() => _MultiChoiceOverlayState();
}

class _MultiChoiceOverlayState extends State<_MultiChoiceOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _redrawSelectionController;
  late final AnimationController _redrawSelectionWaveController;
  late final Animation<double> redrawSelectionOpacity, redrawSelectionScale, redrawSelectionRotate;
  late final Animation<Offset> redrawSelectionOffset;
  late final Completer<int> completer = Completer();

  @override
  void initState() {
    super.initState();
    _redrawSelectionController = AnimationController(
        duration: const Duration(milliseconds: 400),
        vsync: this
    );
    _redrawSelectionWaveController = AnimationController(
        duration: const Duration(milliseconds: 2500),
        vsync: this
    );
    if (widget.useWave) {
      _redrawSelectionWaveController.repeat();
    }
    redrawSelectionOpacity = TweenSequence([
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 1.0),
          weight: 50
      ),
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.0),
          weight: 35
      ),
      TweenSequenceItem(
          tween: ConstantTween(0.0),
          weight: 15
      ),
    ]).animate(_redrawSelectionController);
    redrawSelectionScale = TweenSequence([
      TweenSequenceItem(
          tween: ConstantTween(1.0),
          weight: 50
      ),
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.9),
          weight: 50
      ),
    ]).animate(_redrawSelectionController);
    redrawSelectionOffset = TweenSequence([
      TweenSequenceItem(
          tween: Tween(
            begin: Offset(0.0, -0.15),
            end: Offset(0.0, 0.03),
          ).chain(CurveTween(curve: Curves.easeOut)),
          weight: 42
      ),
      TweenSequenceItem(
          tween: Tween(
            begin: Offset(0.0, 0.03),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeIn)),
          weight: 8
      ),
      TweenSequenceItem(
          tween: ConstantTween(Offset.zero),
          weight: 50
      ),
    ]).animate(_redrawSelectionController);
    const defaultRotate = -0.0025;
    redrawSelectionRotate = TweenSequence([
      TweenSequenceItem(
          tween: Tween(begin: -(defaultRotate * 2), end: defaultRotate),
          weight: 50
      ),
      TweenSequenceItem(
          tween: ConstantTween(defaultRotate),
          weight: 50
      ),
    ]).animate(_redrawSelectionController);

    widget._controller.state = this;
    widget._controller.stateLoaded.complete();
  }

  Future<void> Function() _createTapCallback(int ret) {
    return () async {
      await _redrawSelectionController.forward();
      _redrawSelectionWaveController.stop();
      _redrawSelectionWaveController.value = 0.0;
      completer.complete(ret);
    };
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;

    final promptBox = FractionallySizedBox(
      heightFactor: isLandscape ? 0.5 : null,
      widthFactor: isLandscape ? null : 0.8,
      child: AspectRatio(
        aspectRatio: 4/3,
        child: LayoutBuilder(
            builder: (context, constraints) {
              const designWidth = 646;
              final designRatio = constraints.maxWidth / designWidth;
              return DefaultTextStyle(
                style: TextStyle(
                  fontFamily: "Splatfont2",
                  color: Colors.white,
                  fontSize: 25 * designRatio,
                ),
                child: SlideTransition(
                  position: redrawSelectionOffset,
                  child: ScaleTransition(
                    scale: redrawSelectionScale,
                    child: RotationTransition(
                      turns: redrawSelectionRotate,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.grey[850],
                          borderRadius: BorderRadius.circular(60 * designRatio),
                        ),
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Expanded(
                                  flex: 2,
                                  child: Center(
                                      child: Text(
                                        widget.title,
                                        style: TextStyle(
                                          fontSize: 35 * designRatio,
                                        ),
                                      )
                                  )
                              ),
                              Expanded(
                                  flex: 1,
                                  child: FractionallySizedBox(
                                    heightFactor: 0.7,
                                    child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: [
                                          for (var i = 0; i < widget.options.length; i++)
                                            Expanded(
                                              child: Padding(
                                                padding: EdgeInsets.all(5 * designRatio),
                                                child: Center(
                                                  child: SelectionButton(
                                                      onPressEnd: _createTapCallback(i),
                                                      designRatio: designRatio,
                                                      child: Text(widget.options[i])
                                                  ),
                                                ),
                                              ),
                                            )
                                        ]
                                    ),
                                  )
                              )
                            ]
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }
        ),
      ),
    );
    if (widget.useWave) {
      return FadeTransition(
        opacity: redrawSelectionOpacity,
        child: CustomPaint(
          painter: SelectionBackgroundPainter(
            waveAnimation: _redrawSelectionWaveController,
            orientation: mediaQuery.orientation,
          ),
          child: Align(
            alignment: isLandscape ? Alignment(0.4, 0.0) : Alignment(0.0, -0.4),
            child: promptBox,
          )
        )
      );
    } else {
      return FadeTransition(
        opacity: redrawSelectionOpacity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                Colors.black38,
                Colors.black54,
              ],
              radius: 1.3,
            )
          ),
          child: Align(
            alignment: Alignment.center,
            child: promptBox,
          )
        )
      );
    }
  }
}


Future<int> showMultiChoicePrompt(BuildContext context, {
  required String title,
  required List<String> options,
  bool useWave = false,
}) async {
  final controller = _MultiChoiceOverlayController();
  final overlayState = Overlay.of(context);
  final selectionLayer = OverlayEntry(builder: (context) {
    return _MultiChoiceOverlay(
      title: title,
      options: options,
      useWave: useWave,
      controller: controller
    );
  });
  overlayState.insert(selectionLayer);
  await controller.stateLoaded.future;
  await controller.state._redrawSelectionController.animateTo(0.5);

  final ret = await controller.state.completer.future;
  selectionLayer.remove();
  return ret;
}