import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart' hide Level;
import 'package:provider/provider.dart';

import 'package:tableturf_mobile/src/audio/audio_controller.dart';
import 'package:tableturf_mobile/src/game_internals/battle.dart';
import 'package:tableturf_mobile/src/game_internals/opponentAI.dart';
import 'package:tableturf_mobile/src/game_internals/player.dart';
import 'package:tableturf_mobile/src/game_internals/tile.dart';
import 'package:tableturf_mobile/src/play_session/components/splashtag.dart';
import 'package:tableturf_mobile/src/style/palette.dart';
import 'package:tableturf_mobile/src/style/my_transition.dart';

import '../audio/songs.dart';
import '../audio/sounds.dart';
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
  late final Animation<double> _firstSplashTagOpacity, _secondSplashTagOpacity, _vsSplashOpacity;
  late final Animation<Alignment> _firstSplashTagTranslation, _secondSplashTagTranslation;
  late final Animation<double> _vsSplashScale;
  late final Animation<double> _introScale;
  late final Animation<Decoration> _introBackground;

  @override
  void initState() {
    super.initState();
    battle = TableturfBattle(
      yellow: widget.yellow,
      blue: widget.blue,
      board: widget.board,
      aiLevel: widget.aiLevel,
      playerAI: widget.playerAI,
    );

    const firstSplashTagEntry = 250.0;
    const secondSplashTagEntry = 800.0;
    const splashTagEntryPeriod = 200.0;
    const splashTagSettlePeriod = 3000.0;
    const vsSplashEntry = 1800.0;
    const vsSplashEntryPeriod = 100.0;
    const introFadeOutDuration = 200.0;
    const animationDuration = 4700;
    _introAnimator = AnimationController(
      duration: const Duration(milliseconds: animationDuration),
      vsync: this
    );

    _firstSplashTagOpacity = TweenSequence([
      TweenSequenceItem(
        tween: ConstantTween(0.0),
        weight: firstSplashTagEntry,
      ),
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 1.0),
          weight: splashTagEntryPeriod
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: animationDuration - firstSplashTagEntry - splashTagEntryPeriod - introFadeOutDuration,
      ),
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.0),
          weight: introFadeOutDuration
      ),
    ]).animate(_introAnimator);

    _secondSplashTagOpacity = TweenSequence([
      TweenSequenceItem(
        tween: ConstantTween(0.0),
        weight: secondSplashTagEntry,
      ),
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 1.0),
          weight: splashTagEntryPeriod
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: animationDuration - secondSplashTagEntry - splashTagEntryPeriod - introFadeOutDuration,
      ),
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.0),
          weight: introFadeOutDuration
      ),
    ]).animate(_introAnimator);

    _vsSplashOpacity = TweenSequence([
      TweenSequenceItem(
        tween: ConstantTween(0.0),
        weight: vsSplashEntry,
      ),
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOut)),
          weight: splashTagEntryPeriod
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: animationDuration - vsSplashEntry - splashTagEntryPeriod - introFadeOutDuration,
      ),
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.0),
          weight: introFadeOutDuration
      ),
    ]).animate(_introAnimator);

    const splashTagVerticalOffset = -0.4;
    const splashTagTranslationStart = 0.9;
    const splashTagTranslationFastEnd = 0.6;
    const splashTagTranslationSlowEnd = 0.55;
    _firstSplashTagTranslation = TweenSequence([
      TweenSequenceItem(
        tween: ConstantTween(
          Alignment(-splashTagTranslationStart, -splashTagVerticalOffset)
        ),
        weight: firstSplashTagEntry,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: Alignment(-splashTagTranslationStart, -splashTagVerticalOffset),
          end: Alignment(-splashTagTranslationFastEnd, -splashTagVerticalOffset)
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: splashTagEntryPeriod,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: Alignment(-splashTagTranslationFastEnd, -splashTagVerticalOffset),
          end: Alignment(-splashTagTranslationSlowEnd, -splashTagVerticalOffset)
        ),
        weight: splashTagSettlePeriod,
      ),
      TweenSequenceItem(
        tween: ConstantTween(
          Alignment(-splashTagTranslationSlowEnd, -splashTagVerticalOffset)
        ),
        weight: animationDuration - firstSplashTagEntry - splashTagEntryPeriod - splashTagSettlePeriod,
      ),
    ]).animate(_introAnimator);
    _secondSplashTagTranslation = TweenSequence([
      TweenSequenceItem(
        tween: ConstantTween(
          Alignment(splashTagTranslationStart, splashTagVerticalOffset)
        ),
        weight: secondSplashTagEntry,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: Alignment(splashTagTranslationStart, splashTagVerticalOffset),
          end: Alignment(splashTagTranslationFastEnd, splashTagVerticalOffset)
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: splashTagEntryPeriod,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: Alignment(splashTagTranslationFastEnd, splashTagVerticalOffset),
          end: Alignment(splashTagTranslationSlowEnd, splashTagVerticalOffset)
        ),
        weight: splashTagSettlePeriod,
      ),
      TweenSequenceItem(
        tween: ConstantTween(
          Alignment(splashTagTranslationSlowEnd, splashTagVerticalOffset)
        ),
        weight: animationDuration - secondSplashTagEntry - splashTagEntryPeriod - splashTagSettlePeriod,
      ),
    ]).animate(_introAnimator);

    const vsSplashScaleStart = 1.8;
    _vsSplashScale = TweenSequence([
      TweenSequenceItem(
        tween: ConstantTween(vsSplashScaleStart),
        weight: vsSplashEntry,
      ),
      TweenSequenceItem(
        tween: Tween(begin: vsSplashScaleStart, end: 1.0).chain(CurveTween(curve: Curves.bounceOut)),
        weight: vsSplashEntryPeriod,
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: animationDuration - vsSplashEntry - vsSplashEntryPeriod,
      )
    ]).animate(_introAnimator);

    _introScale = TweenSequence([
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: animationDuration - introFadeOutDuration,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.5).chain(CurveTween(curve: Curves.easeIn)),
        weight: introFadeOutDuration,
      ),
    ]).animate(_introAnimator);

    const backgroundColor = Color.fromRGBO(0, 0, 0, 0.5);
    _introBackground = TweenSequence([
      TweenSequenceItem(
        tween: ConstantTween(BoxDecoration(
          color: backgroundColor,
        )),
        weight: animationDuration - introFadeOutDuration,
      ),
      TweenSequenceItem(
        tween: DecorationTween(
          begin: BoxDecoration(
            color: backgroundColor
          ),
          end: BoxDecoration(
            color: const Color.fromRGBO(0, 0, 0, 0.0)
          )
        ),
        weight: introFadeOutDuration,
      ),
    ]).animate(_introAnimator);

    _playInitSequence();
  }

  FutureOr<void> _playInitSequence() async {
    _log.info("init sequence started");
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final overlayState = Overlay.of(context);
    final animationLayer = OverlayEntry(builder: (context) {
      final mediaQuery = MediaQuery.of(context);
      return DefaultTextStyle(
        style: TextStyle(
          fontFamily: "Splatfont1",
          fontSize: 48,
          color: Colors.white,
        ),
        child: DecoratedBoxTransition(
          decoration: _introBackground,
          child: Center(
            child: AspectRatio(
              aspectRatio: mediaQuery.orientation == Orientation.landscape
                ? mediaQuery.size.aspectRatio
                : 1/1.5,
              child: ScaleTransition(
                scale: _introScale,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AlignTransition(
                      alignment: _firstSplashTagTranslation,
                      child: FractionallySizedBox(
                        heightFactor: mediaQuery.orientation == Orientation.landscape
                          ? 0.175
                          : 0.3,
                        widthFactor: 0.6,
                        child: FadeTransition(
                          opacity: _firstSplashTagOpacity,
                          child: SplashTag(
                            name: battle.yellow.name,
                            tagIcon: battle.yellow.icon,
                          )
                        ),
                      )
                    ),
                    AlignTransition(
                      alignment: _secondSplashTagTranslation,
                      child: FractionallySizedBox(
                        heightFactor: mediaQuery.orientation == Orientation.landscape
                          ? 0.175
                          : 0.3,
                        widthFactor: 0.6,
                        child: FadeTransition(
                          opacity: _secondSplashTagOpacity,
                          child: SplashTag(
                            name: battle.blue.name,
                            tagIcon: battle.blue.icon,
                          )
                        ),
                      )
                    ),
                    FractionallySizedBox(
                      heightFactor: 0.6,
                      widthFactor: 0.3,
                      child: Center(
                        child: FractionallySizedBox(
                          heightFactor: 0.4,
                          child: Center(
                            child: ScaleTransition(
                              scale: _vsSplashScale,
                              child: FadeTransition(
                                opacity: _vsSplashOpacity,
                                child: AspectRatio(
                                  aspectRatio: 1.0,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.black,
                                    ),
                                    child: FittedBox(
                                      child: Text("VS"),
                                    )
                                  )
                                )
                              )
                            ),
                          ),
                        )
                      ),
                    )
                  ]
                ),
              ),
            ),
          ),
        ),
      );
    });
    overlayState.insert(animationLayer);
    await Future<void>.delayed(const Duration(milliseconds: 800));

    final audioController = AudioController();
    _introAnimator.value = 0.0;
    audioController.playSfx(SfxType.gameIntro);
    Future.delayed(const Duration(milliseconds: 2075), () async {
      await audioController.playSong(SongType.battle1);
    });
    Future.delayed(const Duration(milliseconds: 3500), () async {
      audioController.playSfx(SfxType.gameIntroExit);
    });
    await _introAnimator.forward();

    animationLayer.remove();
    await Future.delayed(const Duration(milliseconds: 50));

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
