import 'package:flutter/material.dart';
import 'package:tableturf_mobile/src/game_internals/player.dart';


class ScoreCounter extends StatefulWidget {
  final ValueNotifier<int> scoreNotifier;
  final PlayerTraits traits;

  const ScoreCounter({
    super.key,
    required this.scoreNotifier,
    required this.traits,
  });

  @override
  State<ScoreCounter> createState() => _ScoreCounterState();
}

class _ScoreCounterState extends State<ScoreCounter>
    with TickerProviderStateMixin {
  late AnimationController showDiffController, showSumController;
  late Animation<double>
      showDiffScale,
      showDiffEndMoveX,
      showDiffEndMoveY,
      showDiffEndFade,
      showSumScale;
  late int _prevScore;
  int _scoreDiff = 0;

  @override
  void initState() {
    super.initState();
    _prevScore = widget.scoreNotifier.value;
    widget.scoreNotifier.addListener(onScoreUpdate);
    showDiffController = AnimationController(
        duration: const Duration(milliseconds: 1000),
        vsync: this
    );
    showSumController = AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this
    );
    showDiffController.value = 1.0;
    showSumController.value = 1.0;

    showDiffScale = TweenSequence([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.elasticIn.flipped)),
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
    showDiffEndMoveX = Tween<double>(
      begin: 0,
      end: -15,
    ).animate(
      CurvedAnimation(
        parent: showDiffController,
        curve: Interval(
          0.8, 1.0,
          curve: Curves.easeInOut,
        ),
      ),
    );
    showDiffEndMoveY = Tween<double>(
      begin: 0,
      end: 10,
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
    final scoreDiffDisplay = Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(999)),
            color: _scoreDiff > 0 ? widget.traits.scoreCountShadow : Colors.grey,
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Transform.translate(
            offset: Offset(-1, -0.5),
            child: Center(
                child: Text(
                    (_scoreDiff > 0 ? "+" : "") + _scoreDiff.toString(),
                    style: TextStyle(
                        fontFamily: "Splatfont1",
                        fontStyle: FontStyle.italic,
                        color: _scoreDiff > 0 ? Colors.white : Colors.grey[800],
                        fontSize: 10,
                        letterSpacing: 0.3,
                        shadows: [
                          Shadow(
                            color: Colors.grey[600]!,
                            offset: Offset(1, 1),
                          )
                        ]
                    )
                )
            ),
          ),
        )
    );
    return Stack(
      children: [
        AnimatedBuilder(
          animation: showSumController,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Transform.translate(
              offset: Offset(-2, -1),
              child: Center(
                child: Text(
                  _prevScore.toString(),
                  style: TextStyle(
                    fontFamily: "Splatfont1",
                    fontStyle: FontStyle.italic,
                    color: widget.traits.scoreCountText,
                    fontSize: 22,
                    letterSpacing: 0.6,
                    shadows: [
                      Shadow(
                        color: widget.traits.scoreCountShadow,
                        offset: Offset(2, 2),
                      )
                    ]
                  )
                )
              ),
            ),
          ),
          builder: (_, child) => Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(999)),
              color: widget.traits.scoreCountBackground
            ),
            child: Transform.scale(
              scale: showSumScale.value,
              child: child
            )
          )
        ),
        Transform.translate(
          offset: Offset(30, -5),
          child: AnimatedBuilder(
            animation: showDiffController,
            child: scoreDiffDisplay,
            builder: (_, sdd) => Transform.scale(
              scale: showDiffScale.value,
              child: Opacity(
                opacity: showDiffEndFade.value,
                child: Transform.translate(
                  offset: Offset(showDiffEndMoveX.value, showDiffEndMoveY.value),
                  child: sdd,
                )
              )
            )
          ),
        )
      ]
    );
  }
}