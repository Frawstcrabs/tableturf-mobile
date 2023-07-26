import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart' hide Level;
import 'package:provider/provider.dart';

import 'package:tableturf_mobile/src/audio/audio_controller.dart';
import 'package:tableturf_mobile/src/game_internals/battle.dart';
import 'package:tableturf_mobile/src/game_internals/opponentAI.dart';
import 'package:tableturf_mobile/src/game_internals/player.dart';
import 'package:tableturf_mobile/src/game_internals/tile.dart';
import 'package:tableturf_mobile/src/components/splashtag.dart';
import 'package:tableturf_mobile/src/style/constants.dart';
import 'package:tableturf_mobile/src/style/my_transition.dart';

import '../audio/songs.dart';
import '../audio/sounds.dart';
import 'session_running.dart';
import '../components/build_board_widget.dart';

class PlaySessionIntro extends StatefulWidget {
  final TableturfPlayer yellow, blue;
  final TileGrid board;
  final AILevel aiLevel;
  final AILevel? playerAI;
  final String boardHeroTag;
  final void Function()? onWin, onLose;
  final Completer sessionCompleter;
  final bool showXpPopup;

  const PlaySessionIntro({
    super.key,
    required this.sessionCompleter,
    required this.boardHeroTag,
    required this.yellow,
    required this.blue,
    required this.board,
    required this.aiLevel,
    required this.showXpPopup,
    this.playerAI,
    this.onWin,
    this.onLose,
  });

  @override
  State<PlaySessionIntro> createState() => _PlaySessionIntroState();
}

class _PlaySessionIntroState extends State<PlaySessionIntro>
    with SingleTickerProviderStateMixin {
  static final _log = Logger('PlaySessionIntroState');
  late final TableturfBattle battle;

  late final AnimationController _introAnimator;
  late final Animation<double> _firstSplashTagOpacity, _secondSplashTagOpacity, _vsSplashOpacity, _vsSplashBackgroundOpacity;
  late final Animation<Alignment> _firstSplashTagTranslation, _secondSplashTagTranslation;
  late final Animation<double> _vsSplashScale, _vsSplashBackgroundScale;
  late final Animation<double> _introScale;
  late final Animation<Decoration> _introBackground;

  static const animationDuration = 4700;
  static const firstSplashTagEntry = 250.0;
  static const secondSplashTagEntry = 800.0;
  static const vsSplashEntry = 1800.0;
  static const vsSplashBackgroundEntry = vsSplashEntry + 40;
  static const splashTagEntryPeriod = 200.0;
  static const vsSplashEntryPeriod = 250.0;
  static const vsSplashOpacityDurationRatio = 0.2;
  static const splashTagSettlePeriod = 3000.0;
  static const splashTagVerticalOffset = -0.4;
  static const splashTagTranslationStart = 0.9;
  static const splashTagTranslationFastEnd = 0.6;
  static const splashTagTranslationSlowEnd = 0.55;
  static const vsSplashScaleStart = 1.7;
  static const introFadeOutDuration = 200.0;

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
          tween: Tween(begin: 0.0, end: 1.0),
          weight: splashTagEntryPeriod * vsSplashOpacityDurationRatio
      ),
      TweenSequenceItem(
          tween: ConstantTween(1.0),
          weight: splashTagEntryPeriod * (1 - vsSplashOpacityDurationRatio)
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

    _vsSplashBackgroundOpacity = TweenSequence([
      TweenSequenceItem(
        tween: ConstantTween(0.0),
        weight: vsSplashBackgroundEntry,
      ),
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 1.0),
          weight: splashTagEntryPeriod * vsSplashOpacityDurationRatio
      ),
      TweenSequenceItem(
          tween: ConstantTween(1.0),
          weight: splashTagEntryPeriod * (1 - vsSplashOpacityDurationRatio)
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: animationDuration - vsSplashBackgroundEntry - splashTagEntryPeriod - introFadeOutDuration,
      ),
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.0),
          weight: introFadeOutDuration
      ),
    ]).animate(_introAnimator);

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

    _vsSplashScale = TweenSequence([
      TweenSequenceItem(
        tween: ConstantTween(vsSplashScaleStart),
        weight: vsSplashEntry,
      ),
      TweenSequenceItem(
        tween: Tween(begin: vsSplashScaleStart, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)),
        weight: vsSplashEntryPeriod,
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: animationDuration - vsSplashEntry - vsSplashEntryPeriod,
      )
    ]).animate(_introAnimator);
    _vsSplashBackgroundScale = TweenSequence([
      TweenSequenceItem(
        tween: ConstantTween(vsSplashScaleStart),
        weight: vsSplashBackgroundEntry,
      ),
      TweenSequenceItem(
        tween: Tween(begin: vsSplashScaleStart, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)),
        weight: vsSplashEntryPeriod,
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: animationDuration - vsSplashBackgroundEntry - vsSplashEntryPeriod,
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
                    ScaleTransition(
                      scale: _vsSplashBackgroundScale,
                      child: FadeTransition(
                        opacity: _vsSplashBackgroundOpacity,
                        child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Align(
                                  alignment: Alignment(-0.7, -0.1),
                                  child: FractionallySizedBox(
                                      heightFactor: 0.6 * 0.3,
                                      child: AspectRatio(
                                          aspectRatio: 1.0,
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Palette.tileYellow,
                                            ),
                                          )
                                      )
                                  )
                              ),
                              Align(
                                  alignment: Alignment(0.7, 0.1),
                                  child: FractionallySizedBox(
                                      heightFactor: 0.6 * 0.3,
                                      child: AspectRatio(
                                          aspectRatio: 1.0,
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Palette.tileBlue,
                                            ),
                                          )
                                      )
                                  )
                              ),
                            ]
                        ),
                      ),
                    ),
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
    final audioController = AudioController();
    await audioController.loadSong(SongType.battle1);
    await Future<void>.delayed(const Duration(milliseconds: 800));

    _introAnimator.value = 0.0;
    await audioController.playSfx(SfxType.gameIntro);
    Future.delayed(const Duration(milliseconds: 2150), () async {
      await audioController.startSong();
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
          sessionCompleter: widget.sessionCompleter,
          battle: battle,
          boardHeroTag: widget.boardHeroTag,
          onWin: widget.onWin,
          onLose: widget.onLose,
          showXpPopup: widget.showXpPopup,
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
    final mediaQuery = MediaQuery.of(context);

    final screen = Container(
      color: Palette.backgroundPlaySession,
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
