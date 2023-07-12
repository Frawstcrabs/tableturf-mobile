import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart' hide Level;
import 'package:provider/provider.dart';

import 'package:tableturf_mobile/src/audio/audio_controller.dart';
import 'package:tableturf_mobile/src/game_internals/battle.dart';
import 'package:tableturf_mobile/src/game_internals/opponentAI.dart';
import 'package:tableturf_mobile/src/game_internals/player.dart';
import 'package:tableturf_mobile/src/game_internals/tile.dart';
import 'package:tableturf_mobile/src/style/palette.dart';
import 'package:tableturf_mobile/src/style/my_transition.dart';

import '../audio/songs.dart';
import 'session_running.dart';
import 'components/build_board_widget.dart';

class PlaySessionIntro extends StatefulWidget {
  final TableturfPlayer yellow, blue;
  final TileGrid board;
  final AILevel aiLevel;
  final AILevel? playerAI;
  final String boardHeroTag;

  const PlaySessionIntro({
    super.key,
    required this.boardHeroTag,
    required this.yellow,
    required this.blue,
    required this.board,
    required this.aiLevel,
    this.playerAI,
  });

  @override
  State<PlaySessionIntro> createState() => _PlaySessionIntroState();
}

class _PlaySessionIntroState extends State<PlaySessionIntro>
    with SingleTickerProviderStateMixin {
  static final _log = Logger('PlaySessionIntroState');
  late final TableturfBattle battle;

  late final AnimationController _introAnimator;

  @override
  void initState() {
    super.initState();
    _introAnimator = AnimationController(
        duration: const Duration(milliseconds: 1000),
        vsync: this
    );
    battle = TableturfBattle(
      yellow: widget.yellow,
      blue: widget.blue,
      board: widget.board,
      aiLevel: widget.aiLevel,
      playerAI: widget.playerAI,
    );
    _playInitSequence();
  }

  FutureOr<void> _playInitSequence() async {
    _log.info("init sequence started");
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final overlayState = Overlay.of(context);
    final animationLayer = OverlayEntry(builder: (_) {
      return Container(
        color: Color.fromRGBO(0, 0, 0, 0.5),
        child: Center(
          child: RotationTransition(
            turns: _introAnimator,
            child: Container(width: 20, height: 80, color: Colors.green)
          )
        )
      );
    });
    overlayState.insert(animationLayer);

    await Future<void>.delayed(const Duration(milliseconds: 500));
    await AudioController().playSong(SongType.battle1);
    _introAnimator.value = 0.0;
    await _introAnimator.forward();
    animationLayer.remove();

    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) {
        return PlaySessionScreen(
          key: const Key('play session screen'),
          battle: battle,
          boardHeroTag: widget.boardHeroTag,
        );
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (animation.status == AnimationStatus.forward) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        } else {
          return FadeToBlackTransition(
            animation: animation,
            child: child,
          );
        }
      },
      transitionDuration: const Duration(milliseconds: 500),
    ));
  }

  @override
  void dispose() {
    _introAnimator.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();
    final mediaQuery = MediaQuery.of(context);

    final screen = Container(
      color: palette.backgroundPlaySession,
      child: Padding(
        padding: mediaQuery.padding,
        child: buildBoardWidget(
          battle: battle,
          loopAnimation: false,
          boardHeroTag: widget.boardHeroTag,
        ),
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
      child: WillPopScope(
        onWillPop: () async => false,
        child: screen
      )
    );
  }
}
