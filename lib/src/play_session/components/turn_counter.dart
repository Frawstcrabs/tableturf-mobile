import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tableturf_mobile/src/audio/sounds.dart';
import 'package:tableturf_mobile/src/game_internals/battle.dart';

import 'package:tableturf_mobile/src/audio/audio_controller.dart';

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
  static const focusScale = 1.4;
  static const counterBounceHeight = 0.14;

  @override
  void initState() {
    super.initState();
    turnCount = widget.battle.turnCountNotifier.value;
    widget.battle.turnCountNotifier.addListener(_onTurnCountChange);

    _tickController = AnimationController(
      duration: duration,
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
    final audioController = AudioController();
    final context = _key.currentContext!;
    final renderBox = context.findRenderObject()! as RenderBox;
    final globalPos = renderBox.localToGlobal(Offset.zero);
    final overlayState = Overlay.of(context)!;

    final backgroundLayer = OverlayEntry(builder: (_) {
      return DecoratedBoxTransition(
        decoration: _backgroundDarken,
        child: Container()
      );
    });
    final animationLayer = OverlayEntry(builder: (_) {
      return Positioned(
        top: globalPos.dy,
        left: globalPos.dx,
        child: SizedBox(
          height: renderBox.size.height,
          width: renderBox.size.width,
          child: _buildCounter(
            context: context,
          ),
        )
      );
    });
    overlayState.insert(backgroundLayer);
    overlayState.insert(animationLayer);

    _tickController.value = 0.0;
    audioController.playSfx(newValue <= 3 ? SfxType.turnCountEnding : SfxType.turnCountNormal);
    await _tickController.animateTo(360/duration.inMilliseconds);
    setState(() {
      turnCount = newValue;
    });
    animationLayer.markNeedsBuild();
    await _tickController.forward(from: 360/duration.inMilliseconds);
    animationLayer.remove();
    backgroundLayer.remove();
  }

  Widget _buildCounter({
    required BuildContext context,
    Key? key,
  }) {
    final mediaQuery = MediaQuery.of(context);
    final diameter = mediaQuery.orientation == Orientation.landscape
      ? mediaQuery.size.width * 0.08
      : mediaQuery.size.height * 0.06;

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

    return AnimatedBuilder(
      animation: _tickController,
      builder: (_, __) => Transform.scale(
        scale: _counterScale.value,
        child: AspectRatio(
          aspectRatio: 1,
          child: SizedBox(
            key: key,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: Color.fromRGBO(128, 128, 128, 1)
              ),
              child: Center(
                child: Transform.translate(
                  offset: Offset(0, diameter * _counterMove.value),
                  child: FractionallySizedBox(
                    heightFactor: 0.9,
                    widthFactor: 0.9,
                    child: FittedBox(
                      fit: BoxFit.fitHeight,
                      child: turnText,
                    )
                  ),
                ),
              )
            ),
          ),
        ),
      )
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
