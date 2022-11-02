import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tableturf_mobile/src/audio/sounds.dart';
import 'package:tableturf_mobile/src/game_internals/battle.dart';

import '../audio/audio_controller.dart';

class TurnCounter extends StatefulWidget {
  final TableturfBattle battle;
  const TurnCounter({super.key, required this.battle});

  @override
  State<TurnCounter> createState() => _TurnCounterState();
}

class _TurnCounterState extends State<TurnCounter>
    with SingleTickerProviderStateMixin {
  final GlobalKey _key = GlobalKey(debugLabel: "TurnCounter");
  late int turnCount;
  late final AnimationController _tickController;
  late final Animation<Decoration> _backgroundDarken;
  late final Animation<double> _counterScale, _counterMove;

  static const duration = Duration(milliseconds: 1300);
  static const darkenAmount = 0.5;
  static const focusScale = 1.3;
  static final counterBounceHeight = 4.0;

  @override
  void initState() {
    super.initState();
    turnCount = widget.battle.turnCountNotifier.value;
    widget.battle.turnCountNotifier.addListener(_onTurnCountChange);

    _tickController = AnimationController(
      duration: duration,
      vsync: this,
    );

    final darkenColor = const Color.fromRGBO(0, 0, 0, darkenAmount);
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

    _counterMove = TweenSequence([
      TweenSequenceItem(
        tween: ConstantTween(0.0),
        weight: 36.0,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: -counterBounceHeight,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 7.0,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: -counterBounceHeight,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.bounceOut)),
        weight: 14.0,
      ),
      TweenSequenceItem(
        tween: ConstantTween(0.0),
        weight: 73.0,
      ),
    ]).animate(_tickController);
  }

  @override
  void dispose() {
    widget.battle.turnCountNotifier.removeListener(_onTurnCountChange);
    _tickController.dispose();
    super.dispose();
  }

  Future<void> _onTurnCountChange() async {
    final newValue = widget.battle.turnCountNotifier.value;
    var tempValue = turnCount;
    final audioController = AudioController();
    final context = _key.currentContext!;
    final globalPos = (context.findRenderObject()! as RenderBox).localToGlobal(Offset.zero);
    final overlayState = Overlay.of(context)!;

    final animationLayer = OverlayEntry(builder: (_) {
      return AnimatedBuilder(
        animation: _tickController,
        builder: (_, __) => Stack(
          children: [
            SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: DecoratedBoxTransition(
                decoration: _backgroundDarken,
                child: Container()
              )
            ),
            Positioned(
                top: globalPos.dy,
                left: globalPos.dx,
                child: Transform.scale(
                  scale: _counterScale.value,
                  child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(999)),
                          color: Color.fromRGBO(128, 128, 128, 1)
                      ),
                      child: Center(
                        child: Transform.translate(
                          offset: Offset(0.5, _counterMove.value - 1),
                          child: DefaultTextStyle(
                            style: TextStyle(
                              fontFamily: "Splatfont1",
                              color: tempValue > 3
                                  ? Colors.white
                                  : Colors.red,
                              fontSize: 20,
                              letterSpacing: 0.6,
                              shadows: [
                                Shadow(
                                  color: Color.fromRGBO(0, 0, 0, 0.4),
                                  offset: Offset(2, 2),
                                )
                              ]
                            ),
                            child: Text(
                              tempValue.toString(),
                            ),
                          ),
                        ),
                      )
                  ),
                )
            )
          ],
        )
      );
    });
    overlayState.insert(animationLayer);

    _tickController.value = 0.0;
    audioController.playSfx(newValue <= 3 ? SfxType.turnCountEnding : SfxType.turnCountNormal);
    await _tickController.animateTo(360/duration.inMilliseconds);
    tempValue = newValue;
    setState(() {
      turnCount = newValue;
    });
    await _tickController.forward(from: 360/duration.inMilliseconds);
    animationLayer.remove();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: _key,
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(999)),
        color: Color.fromRGBO(128, 128, 128, 1)
      ),
      child: Center(
        child: Transform.translate(
          offset: Offset(0.5, -1),
          child: Text(
            turnCount.toString(),
            style: TextStyle(
              fontFamily: "Splatfont1",
              color: turnCount > 3
                  ? Colors.white
                  : Colors.red,
              fontSize: 20,
              letterSpacing: 0.6,
              shadows: [
                Shadow(
                  color: Color.fromRGBO(0, 0, 0, 0.4),
                  offset: Offset(2, 2),
                )
              ]
            )
          ),
        ),
      )
    );
  }
}
