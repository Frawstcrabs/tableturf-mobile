import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:tableturf_mobile/src/audio/audio_controller.dart';
import 'package:tableturf_mobile/src/audio/sounds.dart';
import 'package:tableturf_mobile/src/player_progress/player_progress.dart';

import '../components/paint_score_bar.dart';
import '../style/constants.dart';

class XpBarPainter extends CustomPainter {
  final Animation<double> length, waveAnimation;

  XpBarPainter({
    required this.length,
    required this.waveAnimation,
  }): super(repaint: Listenable.merge([length, waveAnimation]));

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(Colors.grey[900]!, BlendMode.srcOver);
    paintScoreBar(
      canvas: canvas,
      size: size,
      length: length,
      waveAnimation: waveAnimation,
      direction: AxisDirection.left,
      paint: Paint()..shader = LinearGradient(
        colors: [
          const Color.fromRGBO(129, 51, 201, 1.0),
          const Color.fromRGBO(78, 105, 136, 1.0),
          const Color.fromRGBO(71, 164, 90, 1.0),
        ],
        stops: [
          0.0,
          0.5,
          1.0,
        ],
      ).createShader(Offset(-size.width * (1.0 - length.value), 0) & size),
    );
  }

  @override
  bool shouldRepaint(XpBarPainter other) {
    return false;
  }
}

class XpBarAnimationEntry {
  final int begin, end;
  final int range;
  const XpBarAnimationEntry({
    required this.begin,
    required this.end,
    required this.range,
  });
}

class XpBarPopup extends StatefulWidget {
  final Completer<void> popupExited;
  final int beforeXp, afterXp;
  const XpBarPopup({
    super.key,
    required this.popupExited,
    required this.beforeXp,
    required this.afterXp,
  });

  @override
  State<XpBarPopup> createState() => _XpBarPopupState();
}

class _XpBarPopupState extends State<XpBarPopup>
    with TickerProviderStateMixin {
  bool finishedAnimation = false;

  late final AnimationController transitionController;
  late final Animation<double> transitionOpacity, transitionScale, transitionRotate;
  late final Animation<Offset> transitionOffset;

  late final AnimationController barLengthController, barWaveController;
  Animation<double> barLength = const AlwaysStoppedAnimation(0.0);

  late final AnimationController rankUpController;
  late final Animation<double> rankUpRankScale, rankUpRankOpacity;
  late final Animation<double> rankUpTextScale, rankUpTextOpacity;

  Duration remainingDuration = Durations.xpBarFill;

  final ValueNotifier<int> currentRank = ValueNotifier(1);
  int currentXpRequirement = 100;
  int xpDiff = 0;

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
    transitionScale = ConstantTween(1.0).animate(transitionController);
    transitionOffset = TweenSequence([
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
          tween: Tween(
            begin: Offset.zero,
            end: Offset(0.0, -0.03),
          ).chain(CurveTween(curve: Curves.easeIn)),
          weight: 8
      ),
      TweenSequenceItem(
          tween: Tween(
            begin: Offset(0.0, -0.03),
            end: Offset(0.0, 0.15),
          ).chain(CurveTween(curve: Curves.easeOut)),
          weight: 42
      ),
    ]).animate(transitionController);
    const defaultRotate = -0.0025;
    transitionRotate = TweenSequence([
      TweenSequenceItem(
          tween: Tween(begin: -(defaultRotate * 2), end: defaultRotate),
          weight: 50
      ),
      TweenSequenceItem(
          tween: Tween(begin: defaultRotate, end: defaultRotate * 2),
          weight: 50
      ),
    ]).animate(transitionController);

    const rankUpRankEntry = 0.00001;
    const rankUpTextEntry = 50.0;
    const opacityDuration = 100.0;
    const scaleDuration = 300.0;
    const scaleAmount = 2.0;
    const rankUpDuration = rankUpTextEntry + scaleDuration + 1;

    rankUpController = AnimationController(
      duration: Duration(milliseconds: rankUpDuration.toInt()),
      vsync: this,
    );

    rankUpRankOpacity = TweenSequence([
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: rankUpRankEntry,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0),
        weight: opacityDuration,
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: rankUpDuration - rankUpRankEntry - opacityDuration,
      ),
    ]).animate(rankUpController);

    rankUpTextOpacity = TweenSequence([
      TweenSequenceItem(
        tween: ConstantTween(0.0),
        weight: rankUpTextEntry,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0),
        weight: opacityDuration,
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: rankUpDuration - rankUpTextEntry - opacityDuration,
      ),
    ]).animate(rankUpController);

    rankUpRankScale = TweenSequence([
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: rankUpRankEntry,
      ),
      TweenSequenceItem(
        tween: Tween(begin: scaleAmount, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: scaleDuration,
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: rankUpDuration - rankUpRankEntry - scaleDuration,
      ),
    ]).animate(rankUpController);

    rankUpTextScale = TweenSequence([
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: rankUpTextEntry,
      ),
      TweenSequenceItem(
        tween: Tween(begin: scaleAmount, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: scaleDuration,
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: rankUpDuration - rankUpTextEntry - scaleDuration,
      ),
    ]).animate(rankUpController);

    barWaveController = AnimationController(
        duration: const Duration(milliseconds: 1000),
        vsync: this
    );

    barLengthController = AnimationController(
      // duration will be calculated dynamically
      vsync: this
    );

    startAnimation();
  }

  Future<void> startAnimation() async {
    final transitionFuture = transitionController.animateTo(0.5);
    barWaveController.repeat();

    xpDiff = widget.afterXp - widget.beforeXp;
    final beforeRank = calculateXpToRank(widget.beforeXp);
    final afterRank = calculateXpToRank(widget.afterXp);
    final rankBrackets = rankRequirements.sublist(beforeRank - 1, afterRank);
    if (xpDiff == 0) {
      currentRank.value = afterRank;
      currentXpRequirement = rankBrackets[0];
      barLength = AlwaysStoppedAnimation(widget.afterXp / rankBrackets[0]);
    } else {
      int clearedXp = rankRequirements.sublist(0, beforeRank - 1).fold<int>(
          0, (a, b) => a + b);
      final List<XpBarAnimationEntry> entries = [];
      int xpRangeStart = widget.beforeXp - clearedXp;
      int remainingXp = xpDiff;
      for (final bracket in rankBrackets) {
        final tweenStart = max(xpRangeStart, 0);
        final tweenEnd = min(tweenStart + remainingXp, bracket);
        entries.add(XpBarAnimationEntry(
          begin: tweenStart,
          end: tweenEnd,
          range: bracket,
        ));
        xpRangeStart = 0;
        clearedXp += bracket;
        remainingXp = widget.afterXp - clearedXp;
      }
      bool firstTween = true;
      currentRank.value = beforeRank;
      currentXpRequirement = rankBrackets[0];
      final audioController = AudioController();
      audioController.playSfx(SfxType.xpGaugeFill);
      for (final entry in entries) {
        currentXpRequirement = entry.range;
        barLengthController.duration =
            Durations.xpBarFill * ((entry.end - entry.begin) / xpDiff);
        barLength = Tween(
            begin: entry.begin / entry.range,
            end: entry.end / entry.range
        ).animate(barLengthController);
        if (!firstTween) {
          currentRank.value += 1;
          audioController.playSfx(SfxType.rankUp);
          rankUpController.forward(from: 0.0);
        } else {
          firstTween = false;
        }
        await barLengthController.forward(from: 0.0);
      }
    }
    await transitionFuture;
    finishedAnimation = true;
  }

  @override
  void dispose() {
    transitionController..stop()..dispose();
    barLengthController..stop()..dispose();
    barWaveController..stop()..dispose();
    super.dispose();
  }

  Future<void> onExit() async {
    if (!finishedAnimation) return;

    await transitionController.forward();
    barWaveController.stop();
    Navigator.of(context).pop();
    widget.popupExited.complete();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;

    final promptBox = FractionallySizedBox(
      heightFactor: isLandscape ? 0.5 : null,
      widthFactor: isLandscape ? null : 0.8,
      child: AspectRatio(
        aspectRatio: 4/2.5,
        child: LayoutBuilder(
          builder: (context, constraints) {
            const designWidth = 646;
            final designRatio = constraints.maxWidth / designWidth;
            final xpBarRounding = 30 * designRatio;
            final content = FractionallySizedBox(
              widthFactor: 0.7,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const Spacer(flex: 7),
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(xpBarRounding, 0, 0, 0),
                          child: SizedBox.expand(
                            child: FittedBox(
                              fit: BoxFit.fitHeight,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Tableturf Rank",
                                style: TextStyle(
                                  fontFamily: "Splatfont1",
                                  color: Palette.xpTitleText,
                                  shadows: [
                                    Shadow(offset: Offset(1, 1) * designRatio)
                                  ]
                                )
                              ),
                            ),
                          )
                        )
                      ),
                      Expanded(
                        flex: 4,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(xpBarRounding),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: xpBarRounding),
                          child: Row(
                            children: [
                              const Spacer(flex: 1),
                              Expanded(
                                flex: 1,
                                child: ScaleTransition(
                                  scale: rankUpRankScale,
                                  child: FadeTransition(
                                    opacity: rankUpRankOpacity,
                                    child: FittedBox(
                                      fit: BoxFit.fitHeight,
                                      child: ValueListenableBuilder(
                                        valueListenable: currentRank,
                                        builder: (context, int currentRank, child) {
                                          return Text(
                                            currentRank.toString(),
                                            style: TextStyle(
                                              fontFamily: "Splatfont1",
                                              shadows: [
                                                Shadow(offset: Offset(2, 2) * designRatio)
                                              ]
                                            )
                                          );
                                        }
                                      )
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 6,
                                child: FractionallySizedBox(
                                  heightFactor: 0.75,
                                  child: ClipRect(
                                    clipBehavior: Clip.antiAlias,
                                    child: AnimatedBuilder(
                                      animation: barLengthController,
                                      builder: (context, child) {
                                        final currentXp = (currentXpRequirement * barLength.value).round();
                                        return CustomPaint(
                                          painter: XpBarPainter(
                                            length: barLength,
                                            waveAnimation: barWaveController,
                                          ),
                                          child: SizedBox.expand(
                                            child: FittedBox(
                                              alignment: Alignment(0.75, 0),
                                              fit: BoxFit.fitHeight,
                                              child: Text(
                                                "$currentXp/$currentXpRequirement",
                                                style: TextStyle(
                                                  fontFamily: "Splatfont2",
                                                  shadows: [
                                                    Shadow(offset: Offset(1, 1) * designRatio)
                                                  ]
                                                )
                                              )
                                            ),
                                          ),
                                        );
                                      }
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(flex: 7),
                    ]
                  ),
                  Align(
                    alignment: Alignment(-0.425, -0.05),
                    child: ScaleTransition(
                      scale: rankUpTextScale,
                      child: FadeTransition(
                        opacity: rankUpTextOpacity,
                        child: Text(
                          "Rank Up!",
                          style: TextStyle(
                            fontFamily: "Splatfont1",
                            color: Palette.xpRankUpText,
                            shadows: [
                              Shadow(offset: Offset(1, 1) * designRatio)
                            ]
                          )
                        )
                      )
                    )
                  )
                ],
              ),
            );
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
          }
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
              )
            ),
            child: Align(
              alignment: Alignment.center,
              child: promptBox,
            )
          )
        ),
      ),
    );
  }
}


Future<void> showXpBarPopup(BuildContext context, {
  required int beforeXp,
  required int afterXp,
}) async {
  final Completer<void> popupExited = Completer();
  Navigator.of(context).push(PageRouteBuilder(
    opaque: false,
    pageBuilder: (_, __, ___) {
      return XpBarPopup(
        beforeXp: beforeXp,
        afterXp: afterXp,
        popupExited: popupExited
      );
    }
  ));
  await popupExited.future;
}