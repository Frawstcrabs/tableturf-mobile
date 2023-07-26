import 'package:flutter/material.dart';
import 'package:tableturf_mobile/src/game_internals/player.dart';

import '../style/constants.dart';


class ScoreCounter extends StatefulWidget {
  final ValueNotifier<int> scoreNotifier;
  final ValueNotifier<int?>? newScoreNotifier;
  final PlayerTraits traits;

  const ScoreCounter({
    super.key,
    required this.scoreNotifier,
    required this.traits,
    this.newScoreNotifier,
  });

  @override
  State<ScoreCounter> createState() => _ScoreCounterState();
}

class _ScoreCounterState extends State<ScoreCounter>
    with TickerProviderStateMixin {
  late AnimationController showDiffController, showSumController;
  late Animation<double>
      showDiffScale,
      showDiffEndFade,
      showSumScale;
  late final Animation<Offset> showDiffEndMove;
  late int _prevScore;
  int _scoreDiff = 0;

  @override
  void initState() {
    super.initState();
    _prevScore = widget.scoreNotifier.value;
    widget.scoreNotifier.addListener(onScoreUpdate);
    showDiffController = AnimationController(
        duration: Durations.animateBattleScoreDiff,
        vsync: this
    );
    showSumController = AnimationController(
        duration: Durations.animateBattleScoreSum,
        vsync: this
    );
    showDiffController.value = 1.0;
    showSumController.value = 1.0;

    showDiffScale = TweenSequence([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 40.0
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: 40.0
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.85,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20.0
      ),
    ]).animate(showDiffController);
    showDiffEndMove = Tween<Offset>(
      begin: Offset(1.5, -0.2),
      end: Offset(0.75, 0.3),
    ).animate(
      CurvedAnimation(
        parent: showDiffController,
        curve: Interval(
          0.8, 1.0,
          curve: Curves.easeInOut,
        ),
      ),
    );
    showDiffEndFade = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: showDiffController,
        curve: Interval(
          0.8, 0.95,
          curve: Curves.linear,
        ),
      ),
    );
    showSumScale = TweenSequence([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.3,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50.0
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.3,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 70.0
      ),
    ]).animate(showSumController);
  }

  @override
  void dispose() {
    widget.scoreNotifier.removeListener(onScoreUpdate);
    showDiffController.dispose();
    showSumController.dispose();
    super.dispose();
  }

  Future<void> onScoreUpdate() async {
    final newScore = widget.scoreNotifier.value;
    if (!mounted) return;
    setState(() {
      _scoreDiff = newScore - _prevScore;
    });
    try {
      await showDiffController.forward(from: 0.0).orCancel;
      setState(() {
        _prevScore = newScore;
      });
      await showSumController.forward(from: 0.0).orCancel;
    } catch (err) {}
    if (mounted) {
      setState(() {
        _prevScore = newScore;
      });
    }
  }

  @override
  Widget build(BuildContext buildContext) {
    final scoreDiffDisplay = FractionallySizedBox(
      heightFactor: 0.5,
      widthFactor: 0.5,
      child: AspectRatio(
        aspectRatio: 1.0,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _scoreDiff > 0 ? widget.traits.scoreCountShadow : Colors.grey,
          ),
          child: Center(
                child: FractionallySizedBox(
                  heightFactor: 0.9,
                  widthFactor: 0.9,
                  child: FittedBox(
                    fit: BoxFit.fitHeight,
                    child: Text(
                        (_scoreDiff > 0 ? "+" : "") + _scoreDiff.toString(),
                        style: TextStyle(
                            fontFamily: "Splatfont1",
                            fontStyle: FontStyle.italic,
                            color: _scoreDiff > 0 ? Colors.white : Colors.grey[800],
                            letterSpacing: 0.3,
                            shadows: [
                              Shadow(
                                color: Colors.grey[600]!,
                                offset: Offset(1, 1),
                              )
                            ]
                        )
                    ),
                  ),
                )
            )
        ),
      ),
    );
    final textStyle = TextStyle(
        fontFamily: "Splatfont1",
        fontStyle: FontStyle.italic,
        color: widget.traits.scoreCountText,
        letterSpacing: 0.6,
        shadows: [
          Shadow(
            color: widget.traits.scoreCountShadow,
            offset: Offset(1, 1),
          )
        ]
    );
    return Center(
      child: AspectRatio(
        aspectRatio: 1.0,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final diameter = constraints.maxHeight;
            return Stack(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.traits.scoreCountBackground
                  ),
                  child: ScaleTransition(
                    scale: showSumScale,
                    child: Scaffold(
                      backgroundColor: Colors.transparent,
                      body: Transform.translate(
                        offset: Offset(-1, -0.5),
                        child: Center(
                          child: FractionallySizedBox(
                            heightFactor: 0.9,
                            widthFactor: 0.9,
                            child: FittedBox(
                              fit: BoxFit.fitHeight,
                              child: Text(
                                _prevScore.toString(),
                                style: textStyle,
                              ),
                            )
                          )
                        ),
                      ),
                    )
                  )
                ),
                SlideTransition(
                  position: showDiffEndMove,
                  child: FadeTransition(
                    opacity: showDiffEndFade,
                    child: ScaleTransition(
                      scale: showDiffScale,
                      child: scoreDiffDisplay,
                    ),
                  ),
                ),
                if (widget.newScoreNotifier != null) Transform.translate(
                  offset: Offset(diameter * 0.15, diameter * 0.6),
                  child: ValueListenableBuilder(
                    valueListenable: widget.newScoreNotifier!,
                    builder: (_, int? newScore, __) {
                      if (newScore == null || newScore == _prevScore) {
                        return Container();
                      }
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.subdirectory_arrow_right,
                            size: diameter * 0.3,
                            color: textStyle.color,
                            shadows: textStyle.shadows,
                          ),
                          Text(
                            newScore.toString(),
                            style: textStyle.copyWith(fontSize: diameter * 0.35),
                          )
                        ],
                      );
                    }
                  )
                )
              ]
            );
          }
        ),
      ),
    );
  }
}