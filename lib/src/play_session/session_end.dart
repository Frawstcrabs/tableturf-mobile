import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:logging/logging.dart' hide Level;
import 'package:provider/provider.dart';

import 'package:tableturf_mobile/src/audio/audio_controller.dart';
import 'package:tableturf_mobile/src/audio/songs.dart';
import 'package:tableturf_mobile/src/audio/sounds.dart';
import 'package:tableturf_mobile/src/game_internals/battle.dart';
import 'package:tableturf_mobile/src/game_internals/player.dart';
import 'package:tableturf_mobile/src/style/palette.dart';

import 'components/build_board_widget.dart';
import 'components/score_counter.dart';

enum ScoreBarSide {
  blue,
  yellow,
}

class ScoreBarPainter extends CustomPainter {
  final Animation<double> yellowLength, blueLength, waveAnimation, opacity;
  final Orientation orientation;

  static const WAVE_WIDTH = 0.3;
  static const WAVE_HEIGHT = 0.4;

  ScoreBarPainter({
    required this.yellowLength,
    required this.blueLength,
    required this.waveAnimation,
    required this.orientation,
    required this.opacity,
  }):
    super(repaint: Listenable.merge([
      yellowLength,
      blueLength,
      waveAnimation,
      opacity,
    ]))
  ;

  @override
  void paint(Canvas canvas, Size size) {
    final palette = const Palette();
    if (opacity.value == 0.0) return;
    canvas.clipRRect(
        RRect.fromRectAndRadius(
            Offset.zero & size,
            Radius.circular(size.width)
        )
    );

    canvas.drawColor(Colors.black38, BlendMode.srcOver);

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeJoin = StrokeJoin.miter;
    final waveWidth = (orientation == Orientation.landscape ? size.width : size.height) * WAVE_WIDTH;
    final waveHeight = waveWidth * WAVE_HEIGHT;
    final yellowPath = Path();
    final bluePath = Path();

    if (orientation == Orientation.portrait) {
      var d = (waveWidth * -2) * (1 - waveAnimation.value);
      yellowPath.moveTo(size.width, size.height);
      yellowPath.lineTo(size.width, 0.0);
      yellowPath.lineTo(size.width * (1.0 - yellowLength.value), d);
      var outWave = true;

      for (; d < size.height; d += waveWidth) {
        yellowPath.relativeQuadraticBezierTo(
          outWave ? waveHeight : -waveHeight, waveWidth/2,
          0.0, waveWidth,
        );
        outWave = !outWave;
      }
      yellowPath.close();

      d = (waveWidth * -2) * (1 - waveAnimation.value);
      bluePath.moveTo(0.0, 0.0);
      bluePath.lineTo(size.width * blueLength.value, d);
      outWave = true;

      for (; d < size.height; d += waveWidth) {
        bluePath.relativeQuadraticBezierTo(
          outWave ? waveHeight : -waveHeight, waveWidth/2,
          0.0, waveWidth,
        );
        outWave = !outWave;
      }
      bluePath.lineTo(0.0, size.height);
      bluePath.close();
    } else {
      var d = size.width + (waveWidth * 2) * (1 - waveAnimation.value);
      yellowPath.moveTo(0.0, size.height);
      yellowPath.lineTo(size.width, size.height);
      yellowPath.lineTo(d, size.height * (1.0 - yellowLength.value));
      var outWave = true;

      for (; d > 0.0; d -= waveWidth) {
        yellowPath.relativeQuadraticBezierTo(
          -waveWidth/2, outWave ? waveHeight : -waveHeight,
          -waveWidth, 0.0,
        );
        outWave = !outWave;
      }
      yellowPath.close();

      d = size.width + (waveWidth * 2) * (1 - waveAnimation.value);
      bluePath.moveTo(0.0, 0.0);
      bluePath.lineTo(size.width, 0.0);
      bluePath.lineTo(d, size.height * blueLength.value);
      outWave = true;

      for (; d > 0.0; d -= waveWidth) {
        bluePath.relativeQuadraticBezierTo(
          -waveWidth/2, outWave ? waveHeight : -waveHeight,
          -waveWidth, 0.0,
        );
        outWave = !outWave;
      }
      bluePath.close();
    }
    canvas.drawPath(bluePath, paint..color = palette.tileBlue.withOpacity(opacity.value));
    canvas.drawPath(yellowPath, paint..color = palette.tileYellow.withOpacity(opacity.value));
  }

  @override
  bool shouldRepaint(ScoreBarPainter oldDelegate) {
    return this.orientation != oldDelegate.orientation;
  }
}

void paintScoreBar({
  required Canvas canvas,
  required Size size,
  required Animation<double> length,
  required Animation<double> waveAnimation,
  required Animation<double> opacity,
  required AxisDirection direction,
  required Color color,
}) {
  const WAVE_WIDTH = 0.3;
  const WAVE_HEIGHT = 0.4;
  const OVERPAINT = 5.0;
  if (opacity.value == 0.0) return;

  canvas.drawColor(Colors.black38, BlendMode.srcOver);

  final paint = Paint()
    ..style = PaintingStyle.fill
    ..strokeJoin = StrokeJoin.miter;
  final waveWidth = (direction == AxisDirection.up || direction == AxisDirection.down ? size.width : size.height) * WAVE_WIDTH;
  final waveHeight = waveWidth * WAVE_HEIGHT;
  final path = Path();

  switch (direction) {
    case AxisDirection.up:
      var d = size.width + (waveWidth * 2) * (1 - waveAnimation.value) + OVERPAINT;
      path.moveTo(-OVERPAINT, size.height + OVERPAINT);
      path.lineTo(size.width + OVERPAINT, size.height + OVERPAINT);
      path.lineTo(d, size.height * (1.0 - length.value));
      var outWave = true;

      for (; d > -OVERPAINT; d -= waveWidth) {
        path.relativeQuadraticBezierTo(
          -waveWidth/2, outWave ? waveHeight : -waveHeight,
          -waveWidth, 0.0,
        );
        outWave = !outWave;
      }
      break;
    case AxisDirection.right:
      var d = (waveWidth * -2) * (1 - waveAnimation.value) - OVERPAINT;
      path.moveTo(size.width + OVERPAINT, size.height + OVERPAINT);
      path.lineTo(size.width + OVERPAINT, -OVERPAINT);
      path.lineTo(size.width * (1.0 - length.value), d);
      var outWave = true;

      for (; d < size.height + OVERPAINT; d += waveWidth) {
        path.relativeQuadraticBezierTo(
          outWave ? waveHeight : -waveHeight, waveWidth/2,
          0.0, waveWidth,
        );
        outWave = !outWave;
      }
      break;
    case AxisDirection.down:
      var d = size.width + (waveWidth * 2) * (1 - waveAnimation.value) + OVERPAINT;
      path.moveTo(-OVERPAINT,-OVERPAINT);
      path.lineTo(size.width + OVERPAINT, -OVERPAINT);
      path.lineTo(d, size.height * length.value);
      var outWave = true;

      for (; d > - OVERPAINT; d -= waveWidth) {
        path.relativeQuadraticBezierTo(
          -waveWidth/2, outWave ? waveHeight : -waveHeight,
          -waveWidth, 0.0,
        );
        outWave = !outWave;
      }
      break;
    case AxisDirection.left:
      var d = (waveWidth * -2) * (1 - waveAnimation.value) - OVERPAINT;
      path.moveTo(-OVERPAINT, -OVERPAINT);
      path.lineTo(size.width * length.value, d);
      var outWave = true;

      for (; d < size.height + OVERPAINT; d += waveWidth) {
        path.relativeQuadraticBezierTo(
          outWave ? waveHeight : -waveHeight, waveWidth/2,
          0.0, waveWidth,
        );
        outWave = !outWave;
      }
      path.lineTo(-OVERPAINT, size.height + OVERPAINT);
      break;
  }
  path.close();
  canvas.drawPath(path, paint..color = color.withOpacity(opacity.value));
}

class NewScoreBarPainter extends CustomPainter {
  final Animation<double> yellowLength, blueLength, waveAnimation, opacity;
  final Orientation orientation;

  NewScoreBarPainter({
    required this.yellowLength,
    required this.blueLength,
    required this.waveAnimation,
    required this.orientation,
    required this.opacity,
  }):
        super(repaint: Listenable.merge([
        yellowLength,
        blueLength,
        waveAnimation,
        opacity,
      ]))
  ;

  @override
  void paint(Canvas canvas, Size size) {
    final palette = const Palette();
    if (orientation == Orientation.portrait) {
      paintScoreBar(
        canvas: canvas,
        size: size,
        length: blueLength,
        waveAnimation: waveAnimation,
        opacity: opacity,
        direction: AxisDirection.left,
        color: palette.tileBlue,
      );
      paintScoreBar(
        canvas: canvas,
        size: size,
        length: yellowLength,
        waveAnimation: waveAnimation,
        opacity: opacity,
        direction: AxisDirection.right,
        color: palette.tileYellow,
      );
    } else {
      paintScoreBar(
        canvas: canvas,
        size: size,
        length: blueLength,
        waveAnimation: waveAnimation,
        opacity: opacity,
        direction: AxisDirection.down,
        color: palette.tileBlue,
      );
      paintScoreBar(
        canvas: canvas,
        size: size,
        length: yellowLength,
        waveAnimation: waveAnimation,
        opacity: opacity,
        direction: AxisDirection.up,
        color: palette.tileYellow,
      );
    }
  }

  @override
  bool shouldRepaint(NewScoreBarPainter oldDelegate) {
    return this.orientation != oldDelegate.orientation;
  }
}

class PlaySessionEnd extends StatefulWidget {
  final TableturfBattle battle;

  const PlaySessionEnd({
    super.key,
    required this.battle,
  });

  @override
  State<PlaySessionEnd> createState() => _PlaySessionEndState();
}

class _PlaySessionEndState extends State<PlaySessionEnd>
    with TickerProviderStateMixin {
  static final _log = Logger('PlaySessionEndState');

  late final AnimationController _scoreBarAnimator, _scoreSplashAnimator, _scoreCountersAnimator, _scoreWaveAnimator;
  late final Animation<double> yellowScoreAnimation, blueScoreAnimation;
  late final Animation<double> winScoreMoveAnimation, winScoreFadeAnimation;
  late final List<Animation<Offset>> winScoreDropletMoveAnimations;
  late final Animation<double> scoreFade, scoreSize;

  @override
  void initState() {
    super.initState();
    _scoreCountersAnimator = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this
    );
    _scoreBarAnimator = AnimationController(
      duration: const Duration(milliseconds: 2250),
      vsync: this
    );
    _scoreSplashAnimator = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this
    );
    _scoreWaveAnimator = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this
    );
    _scoreWaveAnimator.repeat();

    scoreFade = Tween(
      begin: 0.0,
      end: 1.0,
    ).animate(_scoreCountersAnimator);
    scoreSize = Tween(
      begin: 1.3,
      end: 1.0,
    ).chain(CurveTween(curve: Curves.bounceOut))
        .animate(_scoreCountersAnimator);

    final battle = widget.battle;
    final yellowScore = battle.yellowCountNotifier.value;
    final blueScore = battle.blueCountNotifier.value;
    final yellowScoreRatio = yellowScore / (yellowScore + blueScore);
    const initialBarSize = 0.3;
    const barStartOffset = -0.005;

    yellowScoreAnimation = TweenSequence([
      TweenSequenceItem(
        tween: Tween(
          begin: barStartOffset,
          end: initialBarSize,
        ).chain(CurveTween(curve: Curves.ease)),
        weight: 80
      ),
      TweenSequenceItem(
        tween: ConstantTween(initialBarSize),
        weight: 22
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: initialBarSize,
          end: yellowScoreRatio,
        ).chain(CurveTween(curve: Curves.easeInToLinear)),
        weight: 3
      ),
    ]).animate(_scoreBarAnimator);
    blueScoreAnimation = TweenSequence([
      TweenSequenceItem(
        tween: Tween(
          begin: barStartOffset,
          end: initialBarSize,
        ).chain(CurveTween(curve: Curves.ease)),
        weight: 80
      ),
      TweenSequenceItem(
        tween: ConstantTween(initialBarSize),
        weight: 22
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: initialBarSize,
          end: 1 - yellowScoreRatio,
        ).chain(CurveTween(curve: Curves.easeInToLinear)),
        weight: 3
      ),
    ]).animate(_scoreBarAnimator);

    /*
    late final Animation<double> winScoreMoveAnimation, winScoreFadeAnimation;
    late final List<Animation<Offset>> winScoreDropletMoveAnimations;
    */

    winScoreFadeAnimation = TweenSequence([
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.0
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50
      )
    ]).animate(_scoreSplashAnimator);

    const winSplashExtendDist = 0.2;
    if (yellowScoreRatio > 0.5) {
      winScoreMoveAnimation = Tween(
        begin: yellowScoreRatio,
        end: yellowScoreRatio + winSplashExtendDist,
      ).animate(_scoreSplashAnimator);
      winScoreDropletMoveAnimations = [];
    } else {
      winScoreMoveAnimation = Tween(
        begin: 1 - yellowScoreRatio,
        end: 1 - yellowScoreRatio - winSplashExtendDist,
      ).animate(_scoreSplashAnimator);
      winScoreDropletMoveAnimations = [];
    }

    _playInitSequence();
  }

  FutureOr<void> _playInitSequence() async {
    _log.info("outro sequence started");
    final audioController = AudioController();
    await Future<void>.delayed(const Duration(milliseconds: 1300));
    audioController.playSfx(SfxType.scoreBarFill);
    await _scoreBarAnimator.forward();
    audioController.playSfx(SfxType.scoreBarImpact);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    await _scoreCountersAnimator.forward();
    await Future<void>.delayed(const Duration(milliseconds: 300));

    final yellowScore = widget.battle.yellowCountNotifier.value;
    final blueScore = widget.battle.blueCountNotifier.value;
    if (yellowScore > blueScore) {
      audioController.playSong(SongType.resultWin);
    } else {
      audioController.playSong(SongType.resultLose);
    }
  }

  @override
  void dispose() {
    AudioController().musicPlayer.stop();
    AudioController().musicPlayer.setAudioSource(ConcatenatingAudioSource(children: []));
    _scoreBarAnimator.dispose();
    _scoreCountersAnimator.dispose();
    _scoreSplashAnimator.dispose();
    _scoreWaveAnimator.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();
    final mediaQuery = MediaQuery.of(context);

    final boardWidget = buildBoardWidget(
      battle: widget.battle,
      loopAnimation: false,
    );

    late final Widget screen;
    if (mediaQuery.orientation == Orientation.portrait) {
      screen = Container(
        color: palette.backgroundPlaySession,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const Spacer(flex: 1),
            Expanded(
                flex: 8,
                child: boardWidget
            ),
            Expanded(
                flex: 1,
                child: AnimatedBuilder(
                    animation: _scoreCountersAnimator,
                    builder: (_, __) {
                      return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Transform.scale(
                              scale: scoreSize.value,
                              child: Opacity(
                                opacity: scoreFade.value,
                                child: ScoreCounter(
                                    scoreNotifier: widget.battle.blueCountNotifier,
                                    traits: const BlueTraits()
                                ),
                              ),
                            ),
                            Transform.scale(
                              scale: scoreSize.value,
                              child: Opacity(
                                opacity: scoreFade.value,
                                child: ScoreCounter(
                                    scoreNotifier: widget.battle.yellowCountNotifier,
                                    traits: const YellowTraits()
                                ),
                              ),
                            ),
                          ]
                      );
                    }
                )
            ),
            Expanded(
              flex: 1,
              child: Center(
                child: RepaintBoundary(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(mediaQuery.size.longestSide),
                    child: CustomPaint(
                      painter: NewScoreBarPainter(
                        yellowLength: yellowScoreAnimation,
                        blueLength: blueScoreAnimation,
                        waveAnimation: _scoreWaveAnimator,
                        orientation: mediaQuery.orientation,
                        opacity: AlwaysStoppedAnimation(1.0),
                      ),
                      child: FractionallySizedBox(
                        widthFactor: 0.8,
                        heightFactor: 0.5,
                      ),
                      willChange: true,
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(flex: 1),
          ],
        ),
      );
    } else {
      screen = Container(
        color: palette.backgroundPlaySession,
        padding: mediaQuery.padding,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              flex: 8,
              child: Center(
                child: Text("some other fancy shit goes here")
              )
            ),
            Expanded(
              flex: 1,
              child: AnimatedBuilder(
                    animation: _scoreCountersAnimator,
                    builder: (_, __) {
                      return Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Transform.scale(
                              scale: scoreSize.value,
                              child: Opacity(
                                opacity: scoreFade.value,
                                child: ScoreCounter(
                                    scoreNotifier: widget.battle.blueCountNotifier,
                                    traits: const BlueTraits()
                                ),
                              ),
                            ),
                            Transform.scale(
                              scale: scoreSize.value,
                              child: Opacity(
                                opacity: scoreFade.value,
                                child: ScoreCounter(
                                    scoreNotifier: widget.battle.yellowCountNotifier,
                                    traits: const YellowTraits()
                                ),
                              ),
                            ),
                          ]
                      );
                    }
                )
            ),
            Expanded(
              flex: 1,
              child: Center(
                child: RepaintBoundary(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(mediaQuery.size.longestSide),
                    child: CustomPaint(
                      painter: NewScoreBarPainter(
                        yellowLength: yellowScoreAnimation,
                        blueLength: blueScoreAnimation,
                        waveAnimation: _scoreWaveAnimator,
                        orientation: mediaQuery.orientation,
                        opacity: AlwaysStoppedAnimation(1.0),
                      ),
                      child: FractionallySizedBox(
                        heightFactor: 0.8,
                        widthFactor: 0.8,
                      ),
                      willChange: true,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 10,
              child: boardWidget
            ),
          ],
        ),
      );
    }

    return DefaultTextStyle(
      style: TextStyle(
        fontFamily: "Splatfont2",
        color: Colors.white,
        fontSize: 16,
        letterSpacing: 0.6,
        shadows: [
          Shadow(
            color: const Color.fromRGBO(256, 256, 256, 0.4),
            offset: Offset(1, 1),
          )
        ]
      ),
      child: Padding(
        padding: mediaQuery.padding,
        child: screen,
      )
    );
  }
}
