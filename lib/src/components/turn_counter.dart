import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tableturf_mobile/src/audio/sounds.dart';
import 'package:tableturf_mobile/src/game_internals/battle.dart';

import 'package:tableturf_mobile/src/audio/audio_controller.dart';
import 'package:tableturf_mobile/src/style/constants.dart';

import 'tableturf_battle.dart';

class TurnCounter extends StatefulWidget {
  final int initialTurnCount;
  const TurnCounter({
    super.key,
    required this.initialTurnCount,
  });

  @override
  State<TurnCounter> createState() => _TurnCounterState();
}

class _TurnCounterState extends State<TurnCounter>
    with SingleTickerProviderStateMixin {
  final GlobalKey _key = GlobalKey(debugLabel: "TurnCounter");
  late final TableturfBattleController model;
  late final StreamSubscription<BattleEvent> battleSubscription;
  late int turnCount;
  late final AnimationController _tickController;
  late final Animation<Decoration> _backgroundDarken;
  late final Animation<double> _counterScale;
  late final Animation<Alignment> _counterMove;
  OverlayEntry? animationLayer;

  static const darkenAmount = 0.5;
  static const focusScale = 1.4;
  static const counterBounceHeight = 2.5;

  @override
  void initState() {
    super.initState();
    model = TableturfBattle.getControllerOf(context);
    turnCount = widget.initialTurnCount;
    battleSubscription = TableturfBattle.listen(context, _onBattleEvent);

    _tickController = AnimationController(
      duration: Durations.animateTurnCounter,
      vsync: this,
    );

    const darkenColor = const Color.fromRGBO(0, 0, 0, darkenAmount);
    _backgroundDarken = TweenSequence([
      TweenSequenceItem(
        tween: DecorationTween(
          begin: BoxDecoration(
            color: Colors.transparent,
          ),
          end: BoxDecoration(
            color: darkenColor,
          )
        ),
        weight: 20.0
      ),
      TweenSequenceItem(
        tween: ConstantTween(BoxDecoration(color: darkenColor)),
        weight: 90.0
      ),
      TweenSequenceItem(
        tween: DecorationTween(
          begin: BoxDecoration(
            color: darkenColor,
          ),
          end: BoxDecoration(
            color: Colors.transparent,
          )
        ),
        weight: 20.0
      ),
    ]).animate(_tickController);

    _counterScale = TweenSequence([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: focusScale,
        ),
        weight: 20.0,
      ),
      TweenSequenceItem(
        tween: ConstantTween(focusScale),
        weight: 90.0,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: focusScale,
          end: 1.0,
        ),
        weight: 20.0,
      ),
    ]).animate(_tickController);

    // taken from bounceOut curve code
    const bounceCurveRatio = 2.75;
    _counterMove = TweenSequence([
      TweenSequenceItem(
        tween: ConstantTween(Alignment.center),
        weight: Durations.turnCounterUpdate.inMilliseconds.toDouble(),
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: Alignment.center,
          end: const Alignment(0.0, -counterBounceHeight),
        ).chain(CurveTween(curve: Curves.decelerate)),
        weight: Durations.turnCounterBounceUp.inMilliseconds.toDouble(),
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: const Alignment(0.0, -counterBounceHeight),
          end: Alignment.center,
        ).chain(CurveTween(curve: Curves.bounceOut)),
        weight: Durations.turnCounterBounceUp.inMilliseconds * bounceCurveRatio,
      ),
      TweenSequenceItem(
        tween: ConstantTween(Alignment.center),
        weight: (
          Durations.animateTurnCounter.inMilliseconds
          - Durations.turnCounterUpdate.inMilliseconds
          - (Durations.turnCounterBounceUp.inMilliseconds * (bounceCurveRatio + 1.0))
        )
      ),
    ]).animate(_tickController);
  }

  @override
  void dispose() {
    battleSubscription.cancel();
    _tickController.dispose();
    animationLayer?.remove();
    animationLayer = null;
    super.dispose();
  }

  Future<void> _onBattleEvent(BattleEvent event) async {
    switch (event) {
      case TurnCountTick(:final newTurnCount):
        await _onTurnCountChange(newTurnCount);
    }
  }

  Future<void> _onTurnCountChange(int newValue) async {
    final overlayState = Overlay.of(context);

    assert(animationLayer == null);
    animationLayer = OverlayEntry(builder: (context) {
      MediaQuery.of(context);
      final counterContext = _key.currentContext;
      if (counterContext == null) {
        animationLayer?.remove();
        animationLayer = null;
        return const SizedBox();
      }
      final renderBox = counterContext.findRenderObject()! as RenderBox;
      final globalPos = renderBox.localToGlobal(Offset.zero);
      return Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBoxTransition(
              decoration: _backgroundDarken,
              child: SizedBox.expand(),
          ),
          Positioned(
            top: globalPos.dy,
            left: globalPos.dx,
            child: SizedBox(
              height: renderBox.size.height,
              width: renderBox.size.width,
              child: _buildCounter(
                context: context,
              ),
            )
          )
        ]
      );
    });
    overlayState.insert(animationLayer!);

    _tickController.value = 0.0;
    Timer(Durations.turnCounterUpdate, () async {
      setState(() {
        turnCount = newValue;
      });
      animationLayer?.markNeedsBuild();
    });
    await _tickController.forward();
    animationLayer?.remove();
    animationLayer = null;
  }

  Widget _buildCounter({
    required BuildContext context,
    Key? key,
  }) {
    final turnText = DefaultTextStyle(
      style: TextStyle(
        fontFamily: "Splatfont1",
        color: turnCount > 3
            ? Colors.white
            : Colors.red,
        letterSpacing: 0.6,
        shadows: [
          Shadow(
            color: Color.fromRGBO(0, 0, 0, 0.4),
            offset: Offset(1, 1),
          )
        ]
      ),
      child: Text(
        turnCount.toString(),
      ),
    );

    return ScaleTransition(
      key: key,
      scale: _counterScale,
      child: AspectRatio(
        aspectRatio: 1,
        child: SizedBox(
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color.fromRGBO(128, 128, 128, 1)
            ),
            child: AlignTransition(
              alignment: _counterMove,
              child: FractionallySizedBox(
                heightFactor: 0.9,
                widthFactor: 0.9,
                child: FittedBox(
                  fit: BoxFit.fitHeight,
                  child: turnText,
                )
              ),
            )
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildCounter(
      context: context,
      key: _key,
    );
  }
}
