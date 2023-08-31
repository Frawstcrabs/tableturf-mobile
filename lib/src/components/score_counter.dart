import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tableturf_mobile/src/game_internals/battle.dart';
import 'package:tableturf_mobile/src/game_internals/player.dart';
import 'package:tableturf_mobile/src/components/tableturf_battle.dart';

import '../game_internals/move.dart';
import '../style/constants.dart';


class ScoreCounter extends StatefulWidget {
  final TableturfPlayer player;
  final int initialScore;

  const ScoreCounter({
    super.key,
    required this.player,
    required this.initialScore,
  });

  @override
  State<ScoreCounter> createState() => _ScoreCounterState();
}

class _ScoreCounterState extends State<ScoreCounter>
    with TickerProviderStateMixin {
  late final TableturfBattleController controller;
  late final StreamSubscription<BattleEvent> battleSubscription;
  late AnimationController showDiffController, showSumController;
  late Animation<double>
      showDiffScale,
      showDiffEndFade,
      showSumScale;
  late final Animation<Offset> showDiffEndMove;
  late int _prevScore;
  int _scoreDiff = 0;
  final ValueNotifier<int> potentialScoreDiff = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    controller = TableturfBattle.getControllerOf(context);
    _prevScore = widget.initialScore;
    battleSubscription = TableturfBattle.listen(context, _onBattleEvent);
    showDiffController = AnimationController(
      duration: Durations.animateBattleScoreDiff,
      vsync: this,
    );
    showSumController = AnimationController(
      duration: Durations.animateBattleScoreSum,
      vsync: this,
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

    controller.moveChangeNotifier.addListener(_checkCalculatePotentialScore);
  }

  @override
  void dispose() {
    battleSubscription.cancel();
    showDiffController.dispose();
    showSumController.dispose();
    controller.moveChangeNotifier.removeListener(_checkCalculatePotentialScore);
    super.dispose();
  }

  Future<void> _onBattleEvent(BattleEvent event) async {
    switch (event) {
      case TurnStart():
        potentialScoreDiff.value = 0;
      case ScoreUpdate(:final newScores):
        await onScoreUpdate(newScores[widget.player.id]!);
    }
  }

  void _checkCalculatePotentialScore() {
    final move = controller.playerMove;
    final isValid = controller.moveIsValidNotifier.value;
    if (move != null && isValid) {
      calculatePotentialScore(move);
    } else {
      potentialScoreDiff.value = 0;
    }
  }

  void calculatePotentialScore(TableturfMove move) {
    final changes = move.boardChanges;
    final board = controller.board;
    final traits = widget.player.traits;
    int diff = 0;
    for (final MapEntry(key: coords, value: state) in changes.entries) {
      final boardTile = board[coords.y][coords.x];
      if (boardTile != traits.normalTile && boardTile != traits.specialTile) {
        if (state == traits.normalTile || state == traits.specialTile) {
          // tile would go from one not in traits to one in traits
          // this gain a point
          diff += 1;
        }
      } else {
        if (state != traits.normalTile && state != traits.specialTile) {
          // tile would go from one in traits to one not in traits
          // thus lose a point
          diff -= 1;
        }
      }
    }
    potentialScoreDiff.value = diff;
  }

  Future<void> onScoreUpdate(int newScore) async {
    if (!mounted) return;
    if (newScore - _prevScore == 0) {
      return;
    }
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
    final traits = widget.player.traits;
    final scoreDiffDisplay = FractionallySizedBox(
      heightFactor: 0.5,
      widthFactor: 0.5,
      child: AspectRatio(
        aspectRatio: 1.0,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _scoreDiff > 0 ? traits.scoreCountShadow : Colors.grey,
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
      color: traits.scoreCountText,
      letterSpacing: 0.6,
      shadows: [
        Shadow(
          color: traits.scoreCountShadow,
          offset: Offset(1, 1),
        ),
      ],
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
                    color: traits.scoreCountBackground,
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
                            ),
                          ),
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
                Transform.translate(
                  offset: Offset(diameter * 0.15, diameter * 0.6),
                  child: ValueListenableBuilder(
                    valueListenable: potentialScoreDiff,
                    builder: (_, int newScore, __) {
                      if (newScore == 0) {
                        return const SizedBox();
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
                            (_prevScore + newScore).toString(),
                            style: textStyle.copyWith(fontSize: diameter * 0.35),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}