import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:logging/logging.dart' hide Level;
import 'package:provider/provider.dart';

import 'package:tableturf_mobile/src/audio/audio_controller.dart';
import 'package:tableturf_mobile/src/audio/songs.dart';
import 'package:tableturf_mobile/src/audio/sounds.dart';
import 'package:tableturf_mobile/src/game_internals/battle.dart';
import 'package:tableturf_mobile/src/game_internals/player.dart';
import 'package:tableturf_mobile/src/play_session/session_intro.dart';
import 'package:tableturf_mobile/src/settings/settings.dart';
import 'package:tableturf_mobile/src/style/palette.dart';

import '../game_internals/card.dart';
import '../game_internals/opponentAI.dart';
import '../style/my_transition.dart';
import '../components/build_board_widget.dart';
import '../components/multi_choice_prompt.dart';
import '../components/score_counter.dart';
import '../components/splashtag.dart';

void paintScoreBar({
  required Canvas canvas,
  required Size size,
  required Animation<double> length,
  required Animation<double> waveAnimation,
  double opacity = 1.0,
  required AxisDirection direction,
  required Color color,
}) {
  const WAVE_WIDTH = 0.3;
  const WAVE_HEIGHT = 0.4;
  const OVERPAINT = 5.0;
  if (opacity == 0.0) return;

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
  canvas.drawPath(path, paint..color = color.withOpacity(opacity));
}

class ScoreBarPainter extends CustomPainter {
  final Animation<double> yellowLength, blueLength, waveAnimation;
  final Orientation orientation;

  ScoreBarPainter({
    required this.yellowLength,
    required this.blueLength,
    required this.waveAnimation,
    required this.orientation,
  }):
        super(repaint: Listenable.merge([
        yellowLength,
        blueLength,
        waveAnimation,
      ]))
  ;

  @override
  void paint(Canvas canvas, Size size) {
    final palette = const Palette();
    canvas.drawColor(Colors.black38, BlendMode.srcOver);
    if (orientation == Orientation.portrait) {
      paintScoreBar(
        canvas: canvas,
        size: size,
        length: blueLength,
        waveAnimation: waveAnimation,
        direction: AxisDirection.right,
        color: palette.tileBlue,
      );
      paintScoreBar(
        canvas: canvas,
        size: size,
        length: yellowLength,
        waveAnimation: waveAnimation,
        direction: AxisDirection.left,
        color: palette.tileYellow,
      );
    } else {
      paintScoreBar(
        canvas: canvas,
        size: size,
        length: blueLength,
        waveAnimation: waveAnimation,
        direction: AxisDirection.down,
        color: palette.tileBlue,
      );
      paintScoreBar(
        canvas: canvas,
        size: size,
        length: yellowLength,
        waveAnimation: waveAnimation,
        direction: AxisDirection.up,
        color: palette.tileYellow,
      );
    }
  }

  @override
  bool shouldRepaint(ScoreBarPainter oldDelegate) {
    return this.orientation != oldDelegate.orientation;
  }
}

enum PlayWinner {
  blue,
  yellow,
}

class WinEffectPainter extends CustomPainter {
  final Animation<double> length, waveAnimation, opacity;
  final PlayWinner winner;
  final Orientation orientation;

  WinEffectPainter({
    required this.length,
    required this.waveAnimation,
    required this.opacity,
    required this.winner,
    required this.orientation,
  }):
    super(repaint: Listenable.merge([
      length,
      waveAnimation,
      opacity,
    ]))
  ;

  @override
  void paint(Canvas canvas, Size size) {
    late AxisDirection direction;
    late Color color;
    switch (winner) {
      case PlayWinner.blue:
        color = const Palette().tileBlue;
        switch (orientation) {
          case Orientation.portrait:
            direction = AxisDirection.right;
            break;
          case Orientation.landscape:
            direction = AxisDirection.down;
            break;
        }
        break;
      case PlayWinner.yellow:
        color = const Palette().tileYellow;
        switch (orientation) {
          case Orientation.portrait:
            direction = AxisDirection.left;
            break;
          case Orientation.landscape:
            direction = AxisDirection.up;
            break;
        }
        break;
    }
    paintScoreBar(
      canvas: canvas,
      size: size,
      length: length,
      waveAnimation: waveAnimation,
      opacity: opacity.value,
      direction: direction,
      color: color,
    );
  }

  @override
  bool shouldRepaint(WinEffectPainter other) {
    return winner != other.winner || orientation != other.orientation;
  }

}

class PlaySessionEnd extends StatefulWidget {
  final String boardHeroTag;
  final TableturfBattle battle;
  final void Function()? onWin, onLose;
  final Completer sessionCompleter;

  const PlaySessionEnd({
    super.key,
    required this.sessionCompleter,
    required this.boardHeroTag,
    required this.battle,
    this.onWin,
    this.onLose,
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
  late final PlayWinner winner;
  bool initSequenceEnded = false;

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
      duration: const Duration(milliseconds: 500),
      vsync: this
    );
    _scoreSplashAnimator.value = 1.0;
    _scoreWaveAnimator = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this
    );

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
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 3
      ),
    ]).animate(_scoreBarAnimator);

    /*
    late final Animation<double> winScoreMoveAnimation, winScoreFadeAnimation;
    late final List<Animation<Offset>> winScoreDropletMoveAnimations;
    */

    const winScoreStartOpacity = 0.80;
    winScoreFadeAnimation = TweenSequence([
      TweenSequenceItem(
        tween: Tween(
          begin: winScoreStartOpacity,
          end: 0.0
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 95
      ),
      TweenSequenceItem(
        tween: ConstantTween(0.0),
        weight: 5,
      ),
    ]).animate(_scoreSplashAnimator);

    const winSplashExtendDist = 5.0;
    if (yellowScoreRatio > 0.5) {
      winner = PlayWinner.yellow;
      winScoreMoveAnimation = Tween(
        begin: yellowScoreRatio,
        end: yellowScoreRatio + winSplashExtendDist,
      )
          //.chain(CurveTween(curve: Curves.decelerate))
          .animate(_scoreSplashAnimator);
      winScoreDropletMoveAnimations = [];
      widget.onWin?.call();
    } else {
      winner = PlayWinner.blue;
      winScoreMoveAnimation = Tween(
        begin: 1 - yellowScoreRatio,
        end: (1 - yellowScoreRatio) + winSplashExtendDist,
      )
          //.chain(CurveTween(curve: Curves.decelerate))
          .animate(_scoreSplashAnimator);
      winScoreDropletMoveAnimations = [];
      widget.onLose?.call();
    }

    _playInitSequence();
  }

  FutureOr<void> _playInitSequence() async {
    _log.info("outro sequence started");
    final audioController = AudioController();
    final settings = Settings();
    if (settings.continuousAnimation.value) {
      _scoreWaveAnimator.repeat();
    }
    await Future<void>.delayed(const Duration(milliseconds: 1300));
    audioController.playSfx(SfxType.scoreBarFill);
    await _scoreBarAnimator.forward();
    _scoreSplashAnimator.forward(from: 0.0);
    audioController.playSfx(SfxType.scoreBarImpact);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    await _scoreCountersAnimator.forward();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    initSequenceEnded = true;

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
    _scoreBarAnimator.dispose();
    _scoreCountersAnimator.dispose();
    _scoreSplashAnimator.dispose();
    _scoreWaveAnimator.dispose();
    super.dispose();
  }

  Future<void> _checkRematch() async {
    if (!initSequenceEnded) return;
    final audioController = AudioController();
    var choice = await showMultiChoicePrompt(
      context,
      title: "Keep playing?",
      options: ["Nah", "Yes!"],
      useWave: false,
    );
    if (choice == 1) {
      final battle = widget.battle;
      battle.yellow.reset();
      battle.blue.reset();
      audioController.stopSong(fadeDuration: const Duration(milliseconds: 800));
      Navigator.of(context).pushReplacement(buildMyTransition(
        child: PlaySessionIntro(
          sessionCompleter: widget.sessionCompleter,
          yellow: battle.yellow,
          blue: battle.blue,
          board: battle.origBoard,
          boardHeroTag: "boardView-${Random().nextInt(2^31).toString()}",
          aiLevel: battle.aiLevel,
          playerAI: battle.playerAI,
          onWin: widget.onWin,
          onLose: widget.onLose,
        ),
        color: const Palette().backgroundPlaySession,
        transitionDuration: const Duration(milliseconds: 800),
        reverseTransitionDuration: const Duration(milliseconds: 800),
      ));
      return;
    }
    () async {
      await audioController.stopSong(fadeDuration: const Duration(milliseconds: 600));
      await audioController.musicPlayer.setAudioSource(ConcatenatingAudioSource(children: []));
    }();
    Navigator.of(context).pop();
    widget.sessionCompleter.complete();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();
    final mediaQuery = MediaQuery.of(context);

    final boardWidget = buildBoardWidget(
      battle: widget.battle,
      loopAnimation: false,
      boardHeroTag: widget.boardHeroTag,
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
                child: FractionallySizedBox(
                  heightFactor: 0.8,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ScaleTransition(
                          scale: scoreSize,
                          child: FadeTransition(
                            opacity: scoreFade,
                            child: ScoreCounter(
                              scoreNotifier: widget.battle.yellowCountNotifier,
                              traits: const YellowTraits()
                            ),
                          ),
                        ),
                        ScaleTransition(
                          scale: scoreSize,
                          child: FadeTransition(
                            opacity: scoreFade,
                            child: ScoreCounter(
                              scoreNotifier: widget.battle.blueCountNotifier,
                              traits: const BlueTraits()
                            ),
                          ),
                        ),
                      ]
                  ),
                )
            ),
            Expanded(
              flex: 1,
              child: Center(
                child: RepaintBoundary(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(mediaQuery.size.longestSide),
                    child: CustomPaint(
                      painter: ScoreBarPainter(
                        yellowLength: yellowScoreAnimation,
                        blueLength: blueScoreAnimation,
                        waveAnimation: _scoreWaveAnimator,
                        orientation: mediaQuery.orientation,
                      ),
                      child: FractionallySizedBox(
                        widthFactor: 0.8,
                        heightFactor: 0.5,
                      ),
                      foregroundPainter: WinEffectPainter(
                        length: winScoreMoveAnimation,
                        opacity: winScoreFadeAnimation,
                        winner: winner,
                        waveAnimation: _scoreWaveAnimator,
                        orientation: mediaQuery.orientation,
                      ),
                      willChange: Settings().continuousAnimation.value,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: FractionallySizedBox(
                      widthFactor: 0.8,
                      child: SplashTag(
                        name: widget.battle.yellow.name,
                        tagIcon: widget.battle.yellow.icon,
                      ),
                    ),
                  ),
                  Expanded(
                    child: FractionallySizedBox(
                      widthFactor: 0.8,
                      child: SplashTag(
                        name: widget.battle.blue.name,
                        tagIcon: widget.battle.blue.icon,
                      ),
                    ),
                  )
                ]
              )
            )
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: FractionallySizedBox(
                      widthFactor: 0.8,
                      child: SplashTag(
                        name: widget.battle.yellow.name,
                        tagIcon: widget.battle.yellow.icon,
                      ),
                    ),
                  ),
                  Expanded(
                    child: FractionallySizedBox(
                      widthFactor: 0.8,
                      child: SplashTag(
                        name: widget.battle.blue.name,
                        tagIcon: widget.battle.blue.icon,
                      ),
                    ),
                  )
                ]
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
                            ScaleTransition(
                              scale: scoreSize,
                              child: FadeTransition(
                                opacity: scoreFade,
                                child: ScoreCounter(
                                  scoreNotifier: widget.battle.blueCountNotifier,
                                  traits: const BlueTraits()
                                ),
                              ),
                            ),
                            ScaleTransition(
                              scale: scoreSize,
                              child: FadeTransition(
                                opacity: scoreFade,
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
                      painter: ScoreBarPainter(
                        yellowLength: yellowScoreAnimation,
                        blueLength: blueScoreAnimation,
                        waveAnimation: _scoreWaveAnimator,
                        orientation: mediaQuery.orientation,
                      ),
                      child: FractionallySizedBox(
                        heightFactor: 0.8,
                        widthFactor: 0.8,
                      ),
                      foregroundPainter: WinEffectPainter(
                        length: winScoreMoveAnimation,
                        opacity: winScoreFadeAnimation,
                        winner: winner,
                        waveAnimation: _scoreWaveAnimator,
                        orientation: mediaQuery.orientation,
                      ),
                      willChange: true,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 10,
              child: FractionallySizedBox(
                widthFactor: 0.8,
                child: boardWidget
              )
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
        child: GestureDetector(
          onTap: _checkRematch,
          child: WillPopScope(
            onWillPop: () async {
              _checkRematch();
              return false;
            },
            child: screen
          ),
        ),
      )
    );
  }
}
