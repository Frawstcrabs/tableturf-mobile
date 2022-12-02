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
      end: -0.375,
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
      end: 0.25,
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
    final mediaQuery = MediaQuery.of(context);
    final diameter = mediaQuery.orientation == Orientation.landscape
        ? mediaQuery.size.width * 0.06
        : mediaQuery.size.height * 0.06;
    final scoreDiffDisplay = Container(
      width: diameter/2,
      height: diameter/2,
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
    );
    return Stack(
      children: [
        AnimatedBuilder(
          animation: showSumController,
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
                      style: TextStyle(
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
                      )
                    ),
                  )
                )
              ),
            ),
          ),
          builder: (_, child) => Container(
            width: diameter,
            height: diameter,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.traits.scoreCountBackground
            ),
            child: Transform.scale(
              scale: showSumScale.value,
              child: child
            )
          )
        ),
        AnimatedBuilder(
          animation: showDiffController,
          builder: (_, sdd) => Transform.translate(
            offset: Offset(
              diameter * (0.75 + showDiffEndMoveX.value),
              diameter * (-0.1 + showDiffEndMoveY.value)
            ),
            child: Opacity(
              opacity: showDiffEndFade.value,
              child: Transform.scale(
                scale: showDiffScale.value,
                child: sdd,
              ),
            ),
          ),
          child: scoreDiffDisplay,
        )
      ]
    );
  }
}