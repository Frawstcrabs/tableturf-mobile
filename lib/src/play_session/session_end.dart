import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart' hide Level;
import 'package:provider/provider.dart';

import 'package:tableturf_mobile/src/audio/audio_controller.dart';
import 'package:tableturf_mobile/src/game_internals/battle.dart';
import 'package:tableturf_mobile/src/game_internals/player.dart';
import 'package:tableturf_mobile/src/style/palette.dart';

import 'components/build_board_widget.dart';

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

  late final AnimationController _scoreBarAnimator, _scoreCountersAnimator;
  late final Animation<double> yellowScoreAnimation, blueScoreAnimation;

  @override
  void initState() {
    super.initState();
    _scoreCountersAnimator = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this
    );
    _scoreBarAnimator = AnimationController(
      duration: const Duration(milliseconds: 2750),
      vsync: this
    );

    final battle = widget.battle;
    final yellowScore = battle.yellowCountNotifier.value;
    final blueScore = battle.blueCountNotifier.value;
    final yellowScoreRatio = yellowScore / (yellowScore + blueScore);
    const initialBarSize = 0.3;

    yellowScoreAnimation = TweenSequence([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
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
          begin: 0.0,
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

    _playInitSequence();
  }

  FutureOr<void> _playInitSequence() async {
    _log.info("outro sequence started");
    await Future<void>.delayed(const Duration(milliseconds: 1300));
    await _scoreBarAnimator.forward();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    await _scoreCountersAnimator.forward();
  }

  @override
  void dispose() {
    _scoreBarAnimator.dispose();
    _scoreCountersAnimator.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();
    final mediaQuery = MediaQuery.of(context);

    final scoreBarHeight = 30.0;
    final scoreBarWidth = mediaQuery.size.width * 0.8;

    final boardWidget = buildBoardWidget(
      battle: widget.battle
    );

    final screen = Container(
      color: palette.backgroundPlaySession,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Container(
            height: mediaQuery.padding.top + 10
          ),
          Expanded(
            flex: 5,
            child: boardWidget
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(scoreBarHeight),
                child: Container(
                  height: scoreBarHeight,
                  width: scoreBarWidth,
                  decoration: BoxDecoration(
                    color: Colors.black38,
                  ),
                  child: AnimatedBuilder(
                    animation: _scoreBarAnimator,
                    builder: (_, __) {
                      return Stack(
                        children: [
                          Positioned(
                            left: 0,
                            child: Container(
                              color: const BlueTraits().normalColour,
                              height: scoreBarHeight,
                              width: scoreBarWidth * blueScoreAnimation.value,
                            ),
                          ),
                          Positioned(
                            right: 0,
                            child: Container(
                              color: const YellowTraits().normalColour,
                              height: scoreBarHeight,
                              width: scoreBarWidth * yellowScoreAnimation.value,
                            ),
                          ),
                        ],
                      );
                    }
                  ),
                ),
              ),
            ),
          ),
          Container(
            height: mediaQuery.padding.bottom + 5,
          )
        ],
      ),
    );

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
      child: screen
    );
  }
}
