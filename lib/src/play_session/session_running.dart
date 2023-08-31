import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:tableturf_mobile/src/audio/sounds.dart';
import 'package:logging/logging.dart' hide Level;
import 'package:provider/provider.dart';

import 'package:tableturf_mobile/src/audio/audio_controller.dart';
import 'package:tableturf_mobile/src/components/popup_transition_painter.dart';
import 'package:tableturf_mobile/src/components/tableturf_controller_mixin.dart';
import 'package:tableturf_mobile/src/game_internals/battle.dart';
import 'package:tableturf_mobile/src/game_internals/move.dart';
import 'package:tableturf_mobile/src/game_internals/player.dart';
import 'package:tableturf_mobile/src/components/multi_choice_prompt.dart';
import 'package:tableturf_mobile/src/components/tableturf_battle.dart';
import 'package:tableturf_mobile/src/settings/settings.dart';
import 'package:tableturf_mobile/src/style/constants.dart';
import 'package:tableturf_mobile/src/style/my_transition.dart';

import '../audio/songs.dart';
import '../components/exact_grid.dart';
import '../game_internals/opponentAI.dart';
import 'session_end.dart';
import '../components/arc_tween.dart';
import '../components/build_board_widget.dart';
import '../components/special_meter.dart';
import '../components/turn_counter.dart';
import '../components/card_widget.dart';
import '../components/card_selection.dart';
import '../components/score_counter.dart';

class AspectRatioBuilder extends StatelessWidget {
  final List<MapEntry<double, Widget>> ratios;
  AspectRatioBuilder(Map<double, Widget> unsortedRatios, {super.key})
      : ratios =
            unsortedRatios.entries.sorted((e1, e2) => e1.key.compareTo(e2.key));

  @override
  Widget build(BuildContext context) {
    assert(ratios.isNotEmpty);
    final aspectRatio = MediaQuery.of(context).size.aspectRatio;
    Widget retWidget = ratios.first.value;
    for (final entry in ratios) {
      if (entry.key <= aspectRatio) {
        retWidget = entry.value;
      }
    }
    return retWidget;
  }
}

class SpecialBackgroundPainter extends CustomPainter {
  final bool isLandscape;
  final Animation<Color?> paintColor;

  static const shortSideSize = 3 / 4;

  const SpecialBackgroundPainter(this.isLandscape, this.paintColor)
      : super(repaint: paintColor);

  @override
  void paint(Canvas canvas, Size size) {
    late final Path path;
    final paint = Paint()
      ..color = paintColor.value ?? Colors.black
      ..style = PaintingStyle.fill;
    if (isLandscape) {
      path = Path()
        ..moveTo(size.width * (1 - shortSideSize), size.height)
        ..lineTo(size.width, size.height)
        ..lineTo(size.width * shortSideSize, 0.0)
        ..lineTo(0.0, 0.0)
        ..close();
    } else {
      path = Path()
        ..moveTo(0.0, size.height * shortSideSize)
        ..lineTo(0.0, 0.0)
        ..lineTo(size.width, size.height * (1 - shortSideSize))
        ..lineTo(size.width, size.height)
        ..close();
    }
    canvas.drawShadow(
        path.shift(Offset(5, 5)), const Color.fromRGBO(0, 0, 0, 0.4), 5, false);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(SpecialBackgroundPainter oldPainter) {
    return false;
  }
}

class SwitchTween<T> extends Animatable<T> {
  final double switchPoint;
  final Animatable<T> first, second;

  const SwitchTween({
    required this.switchPoint,
    required this.first,
    required this.second,
  });

  @override
  T transform(double t) {
    if (t < switchPoint) {
      return first.transform(t);
    } else {
      return second.transform(t);
    }
  }
}

class _CardDeckSlice extends StatelessWidget {
  static const DECK_SPACING = Offset(0, -0.05);
  final String cardSleeve;
  final bool isDarkened;
  final double width;

  const _CardDeckSlice({
    required this.cardSleeve,
    required this.isDarkened,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Transform.translate(
          offset: (DECK_SPACING * -1.0) * width,
          child: AspectRatio(
            aspectRatio: CardWidget.CARD_WIDTH / CardWidget.CARD_HEIGHT,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(20 / CardWidget.CARD_HEIGHT * width),
                color: Colors.black,
              ),
            ),
          ),
        ),
        Transform.translate(
          offset: (DECK_SPACING * -0.5) * width,
          child: AspectRatio(
            aspectRatio: CardWidget.CARD_WIDTH / CardWidget.CARD_HEIGHT,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(20 / CardWidget.CARD_HEIGHT * width),
                color: Colors.grey[900],
              ),
            ),
          ),
        ),
        Transform.translate(
          offset: (DECK_SPACING * 0.0) * width,
          child: AspectRatio(
            aspectRatio: CardWidget.CARD_WIDTH / CardWidget.CARD_HEIGHT,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(20 / CardWidget.CARD_HEIGHT * width),
                color: Colors.black,
              ),
            ),
          ),
        ),
        Transform.translate(
          offset: (DECK_SPACING * 0.5) * width,
          child: AspectRatio(
            aspectRatio: CardWidget.CARD_WIDTH / CardWidget.CARD_HEIGHT,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(20 / CardWidget.CARD_HEIGHT * width),
                color: Colors.grey[900],
              ),
            ),
          ),
        ),
        Transform.translate(
          offset: (DECK_SPACING * 1.0) * width,
          child: isDarkened
              ? ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    const Color.fromRGBO(0, 0, 0, 0.5),
                    BlendMode.srcATop,
                  ),
                  child: Image.asset(cardSleeve))
              : Image.asset(cardSleeve),
        ),
      ],
    );
  }
}

class PlaySessionScreen extends StatefulWidget {
  final String boardHeroTag;
  final LocalTableturfBattle battle;
  final TableturfBattleController controller;
  final void Function()? onWin, onLose;
  final Future<void> Function(BuildContext)? onPostGame;
  final Completer sessionCompleter;
  final bool showXpPopup;

  const PlaySessionScreen({
    super.key,
    required this.sessionCompleter,
    required this.boardHeroTag,
    required this.battle,
    required this.controller,
    required this.showXpPopup,
    this.onWin,
    this.onLose,
    this.onPostGame,
  });

  @override
  State<PlaySessionScreen> createState() => _PlaySessionScreenState();
}

class _PlaySessionScreenState extends State<PlaySessionScreen>
    with TickerProviderStateMixin, TableturfBattleMixin {
  static final _log = Logger('PlaySessionScreenState');

  final GlobalKey inputAreaKey = GlobalKey(debugLabel: "InputArea");
  TableturfBattleController get controller => widget.controller;
  TableturfBattleModel get battle => widget.battle;
  final GlobalKey _blueSelectionKey =
      GlobalKey(debugLabel: "BlueSelectionWidget");
  final GlobalKey _yellowSelectionKey =
      GlobalKey(debugLabel: "YellowSelectionWidget");
  final GlobalKey _blueScoreKey = GlobalKey(debugLabel: "BlueScoreWidget");
  final GlobalKey _yellowScoreKey = GlobalKey(debugLabel: "YellowScoreWidget");
  double tileSize = 22.0;
  Offset? piecePosition;
  PointerDeviceKind? pointerKind;
  bool _lockInputs = true;
  late final ValueNotifier<AppLifecycleState> lifecycleNotifier;
  late final StreamController<BattleEvent> eventBroadcast;
  final AsyncEvent backgroundEvent = AsyncEvent();
  Completer<HandRedraw> redrawCompleter = Completer();

  late final AnimationController _turnFadeController;
  late final AnimationController _scoreFadeController;
  late final Animation<double> turnFade, turnSize, scoreFade, scoreSize;

  late final AnimationController _outroController;
  late final Animation<double> outroScale, outroMove;

  late final AnimationController _specialMoveController;
  late final Animation<double> specialMoveFade, specialMoveScale;
  late final Animation<double> specialMoveImageOffset;

  late final AnimationController _specialMovePulseController;
  late final Animation<Color?> specialMoveYellowPulse, specialMoveBluePulse;

  late final AnimationController _deckShuffleController;
  late final Animation<Offset> shuffleTopCardMove, shuffleBottomCardMove;
  late final Animation<double> shuffleCardRotate;

  late final AnimationController _deckScaleController;
  late final Animation<double> scaleDeckValue;
  late final Animation<Color?> scaleDeckColour;

  late final AnimationController _deckPopupController;
  late final OverlayEntry deckPopupOverlay;

  @override
  void initState() {
    super.initState();
    lifecycleNotifier =
        Provider.of<ValueNotifier<AppLifecycleState>>(context, listen: false);
    lifecycleNotifier.addListener(_setBackgroundFlag);
    _setBackgroundFlag();
    eventBroadcast = StreamController.broadcast();

    if (widget.battle.playerAI != null) {
      widget.controller.playerControlIsLocked.value = true;
      widget.controller.playerControlIsLocked.addListener(_resetPlayerLock);
    } else {
      widget.controller.playerControlIsLocked.value = false;
    }

    _scoreFadeController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    scoreFade = Tween(
      begin: 0.0,
      end: 1.0,
    ).animate(_scoreFadeController);
    scoreSize = Tween(
      begin: 1.3,
      end: 1.0,
    ).chain(CurveTween(curve: Curves.easeOut)).animate(_scoreFadeController);

    _turnFadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    turnFade = Tween(
      begin: 0.0,
      end: 1.0,
    ).chain(CurveTween(curve: Curves.easeOut)).animate(_turnFadeController);
    turnSize = Tween(
      begin: 1.3,
      end: 1.0,
    ).chain(CurveTween(curve: Curves.bounceOut)).animate(_turnFadeController);

    _outroController = AnimationController(
      duration: const Duration(milliseconds: 550),
      vsync: this,
    );
    outroMove = TweenSequence([
      TweenSequenceItem(
        tween: Tween(
          begin: 3.5,
          end: -0.05,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: -0.05,
          end: -3.6,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      )
    ]).animate(_outroController);
    outroScale = TweenSequence([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.3,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.3,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_outroController);

    _specialMoveController = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    );
    _specialMovePulseController = AnimationController(
      duration: const Duration(milliseconds: 175),
      vsync: this,
    );

    specialMoveYellowPulse = ColorTween(
      begin: Colors.yellow,
      end: Colors.orange,
    )
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(_specialMovePulseController);
    specialMoveBluePulse = ColorTween(
      begin: const Color.fromRGBO(69, 53, 157, 1.0),
      end: const Color.fromRGBO(96, 58, 255, 1.0),
    )
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(_specialMovePulseController);
    specialMoveFade = TweenSequence([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0),
        weight: 5,
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: 90,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0),
        weight: 5,
      ),
    ]).animate(_specialMoveController);
    specialMoveScale = TweenSequence([
      TweenSequenceItem(
        tween: Tween(begin: 0.3, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 5,
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: 90,
      ),
      TweenSequenceItem(
        tween:
            Tween(begin: 1.0, end: 0.3).chain(CurveTween(curve: Curves.easeIn)),
        weight: 5,
      ),
    ]).animate(_specialMoveController);
    specialMoveImageOffset = TweenSequence([
      TweenSequenceItem(
        tween: Tween(begin: -1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 5,
      ),
      TweenSequenceItem(
        tween: ConstantTween(0.0),
        weight: 90,
      ),
      TweenSequenceItem(
        tween:
            Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 5,
      ),
    ]).animate(_specialMoveController);

    _deckShuffleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    final startOffset = _CardDeckSlice.DECK_SPACING * 1;
    final endOffset = _CardDeckSlice.DECK_SPACING * -1;
    final topTween = CircularArcOffsetTween(
      begin: startOffset,
      end: endOffset,
      clockwise: false,
      angle: pi * 1.85,
    ).chain(CurveTween(curve: Curves.ease));
    final bottomTween = Tween(
      begin: endOffset,
      end: startOffset,
    ).chain(CurveTween(curve: Curves.easeInOutBack));

    const switchPoint = 0.4;
    final topLayerShuffle = SwitchTween(
      switchPoint: switchPoint,
      first: topTween,
      second: bottomTween,
    );
    final bottomLayerShuffle = SwitchTween(
      switchPoint: switchPoint,
      first: bottomTween,
      second: topTween,
    );

    shuffleTopCardMove = TweenSequence([
      TweenSequenceItem(tween: topLayerShuffle, weight: 200),
      TweenSequenceItem(tween: topLayerShuffle, weight: 200),
      TweenSequenceItem(tween: topLayerShuffle, weight: 200),
      TweenSequenceItem(tween: ConstantTween(startOffset), weight: 200),
      TweenSequenceItem(
          tween: ConstantTween(startOffset + Offset(0.035, -0.09)),
          weight: 100),
      TweenSequenceItem(
          tween: ConstantTween(startOffset + Offset(0.035, -0.09)), weight: 99),
      TweenSequenceItem(tween: ConstantTween(startOffset), weight: 1),
    ]).animate(_deckShuffleController);
    shuffleBottomCardMove = TweenSequence([
      TweenSequenceItem(tween: bottomLayerShuffle, weight: 200),
      TweenSequenceItem(tween: bottomLayerShuffle, weight: 200),
      TweenSequenceItem(tween: bottomLayerShuffle, weight: 200),
      TweenSequenceItem(tween: ConstantTween(endOffset), weight: 400),
    ]).animate(_deckShuffleController);
    const defaultRotation = -0.025;
    shuffleCardRotate = TweenSequence([
      TweenSequenceItem(tween: ConstantTween(defaultRotation), weight: 800),
      TweenSequenceItem(
        tween: Tween(
          begin: defaultRotation,
          end: defaultRotation * 2.5,
        ).chain(CurveTween(curve: Curves.decelerate)),
        weight: 100,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: defaultRotation * 2.5,
          end: defaultRotation,
        ).chain(CurveTween(curve: Curves.decelerate.flipped)),
        weight: 100,
      ),
    ]).animate(_deckShuffleController);

    _deckScaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    scaleDeckValue = Tween(
      begin: 0.6,
      end: 1.0,
    ).animate(_deckScaleController);
    scaleDeckColour = ColorTween(
      begin: const Color.fromRGBO(0, 0, 0, 0.3),
      // setting this to be completely transparent causes flutter web
      // to absolutely shit the bed for some reason
      end: const Color.fromRGBO(0, 0, 0, 0.01),
    ).chain(CurveTween(curve: Curves.easeOut)).animate(_deckScaleController);

    _deckPopupController = AnimationController(
      duration: const Duration(milliseconds: 75),
      vsync: this,
    );
    deckPopupOverlay = OverlayEntry(builder: (_) {
      return TableturfBattle(
        eventStream: eventBroadcast.stream,
        controller: widget.controller,
        child: DeckPopupOverlay(
          popupController: _deckPopupController,
          player: widget.battle.player,
        ),
      );
    });

    _monitorBattleEvents();
    _monitorEventSounds();
    _playInitSequence();
  }

  @override
  void dispose() {
    deckPopupOverlay.remove();
    lifecycleNotifier.removeListener(_setBackgroundFlag);
    widget.controller.playerControlIsLocked.removeListener(_resetPlayerLock);
    eventBroadcast.close();
    _outroController.dispose();
    _turnFadeController.dispose();
    _scoreFadeController.dispose();
    _specialMoveController.dispose();
    _specialMovePulseController.dispose();
    _deckShuffleController.dispose();
    _deckScaleController.dispose();
    _deckPopupController.dispose();
    super.dispose();
  }

  void _resetPlayerLock() {
    widget.controller.playerControlIsLocked.value = true;
  }

  Future<void> _monitorBattleEvents() async {
    await for (final event in widget.battle.eventStream) {
      final battle = widget.battle;
      final controller = widget.controller;
      _log.info("Waiting for background event...");
      await backgroundEvent.wait();
      _log.info("Battle event: ${event.runtimeType.toString()}");
      switch (event) {
        case HandRedraw():
          redrawCompleter.complete(event);
        case MoveConfirm():
          eventBroadcast.add(event);
        case Turn(:final moves, :final events):
          if (moves.values.any((m) => m.special)) {
            await _onSpecialMove(moves);
          }
          final playerMove = moves[controller.player.id]!;
          playerMove.card.hasBeenPlayed = true;
          eventBroadcast.add(TurnStart(moves));
          _checkMusicChange(events);
          for (final turnEvent in events) {
            _log.info("Waiting for background event...");
            await backgroundEvent.wait();
            _log.info("Turn event: ${turnEvent.runtimeType.toString()}");
            switch (turnEvent) {
              case TurnCountTick(:final newTurnCount) when newTurnCount == 0:
                await _onGameEnd();
                return;
              case UpdateHand(:final handIndex, :final deckIndex):
                final handCardNotifier = controller.playerHand[handIndex];
                final deckCard = controller.playerDeck[deckIndex];
                handCardNotifier.value?.isHeld = false;
                deckCard.isHeld = true;
                handCardNotifier.value = deckCard;
                eventBroadcast.add(turnEvent);
              case PlayerSpecialUpdate(:final specialDiffs):
                controller.playerSpecial += specialDiffs[controller.player.id] ?? 0;
                eventBroadcast.add(turnEvent);
              default:
                eventBroadcast.add(turnEvent);
            }
            await Future.delayed(turnEvent.duration);
          }
          controller.reset();
          eventBroadcast.add(const TurnEnd());
          battle.runAI();
      }
    }
  }

  Future<void> _monitorEventSounds() async {
    final audioController = AudioController();
    final controller = widget.controller;
    await for (final event in eventBroadcast.stream) {
      switch (event) {
        case MoveConfirm(:final playerID) when playerID == controller.player.id:
          if (controller.movePassNotifier.value) {
            audioController.playSfx(SfxType.confirmMovePass);
          } else if (controller.moveSpecialNotifier.value) {
            audioController.playSfx(SfxType.confirmMoveSpecial);
          } else {
            audioController.playSfx(SfxType.confirmMoveSucceed);
          }
        case MoveConfirm():
          // TODO: replace with opponent move confirm
          audioController.playSfx(SfxType.confirmMoveSucceed);
        case RevealCards():
          audioController.playSfx(SfxType.cardFlip);
        case BoardTilesUpdate(:final type):
          switch (type) {
            case BoardTileUpdateType.normal:
              audioController.playSfx(SfxType.normalMove);
            case BoardTileUpdateType.overlap:
              audioController.playSfx(SfxType.normalMoveOverlap);
            case BoardTileUpdateType.conflict:
              audioController.playSfx(SfxType.normalMoveConflict);
            case BoardTileUpdateType.special:
              audioController.playSfx(SfxType.specialMove);
            case BoardTileUpdateType.silent:
              break;
          }
        case BoardSpecialUpdate():
          audioController.playSfx(SfxType.specialActivate);
        case ScoreUpdate():
          audioController.playSfx(SfxType.counterUpdate);
        case PlayerSpecialUpdate(:final specialDiffs):
          if (specialDiffs.values.any((s) => s > 0)) {
            audioController.playSfx(SfxType.gainSpecial);
          }
        case ClearMoves():
          audioController.playSfx(SfxType.cardDiscard);
        case TurnCountTick(:final newTurnCount):
          if (newTurnCount > 3) {
            audioController.playSfx(SfxType.turnCountNormal);
          } else {
            audioController.playSfx(SfxType.turnCountEnding);
          }
      }
    }
  }

  Future<void> _checkMusicChange(List<BattleEvent> events) async {
    final turnCountTick = events.firstWhereOrNull((element) => element is TurnCountTick);
    final turnCount = (turnCountTick as TurnCountTick?)?.newTurnCount;
    if (turnCount == 3) {
      final audioController = AudioController();
      const musicOffset = Duration(milliseconds: 500);
      const musicFadeTime = Duration(milliseconds: 1300);
      const musicSilenceTime = Duration(milliseconds: 200);
      final eventsDuration = events.fold(
          Duration.zero,
              (Duration d, e) => d + e.duration
      ) - musicOffset;

      await Future<void>.delayed(eventsDuration - (musicFadeTime + musicSilenceTime));
      await audioController.stopSong(fadeDuration: musicFadeTime);
      await Future.wait([
        audioController.loadSong(SongType.last3Turns),
        Future<void>.delayed(musicSilenceTime),
      ]);
      await audioController.startSong();
    }

  }

  Future<void> _playInitSequence() async {
    final battle = widget.battle;
    // need to give precaching a moment before running, otherwise flutter
    // complains about running markNeedsBuild during a build and dies
    await Future.delayed(const Duration(milliseconds: 100));
    await Future.wait<void>([
      battle.startGame(),
      for (final card in battle.playerDeck)
        precacheImage(AssetImage(card.designSprite), context),
      Future.delayed(const Duration(milliseconds: 500)),
    ]);
    final audioController = AudioController();

    await _deckScaleController.forward(from: 0.0);
    await _dealHand();

    int redrawChoice;
    if (widget.battle.playerAI != null) {
      redrawChoice = 0;
    } else {
      redrawChoice = await showMultiChoicePrompt(
        context,
        title: "Redraw hand?",
        options: ["Hold Steady", "Redraw!"],
        useWave: true,
      );
    }
    if (redrawChoice == 1) {
      for (final card in widget.controller.playerHand) {
        final heldCard = card.value;
        if (heldCard != null) {
          heldCard
            ..isHeld = false
            ..isPlayable = false
            ..isPlayableSpecial = false;
        }
        card.value = null;
      }
      redrawCompleter = Completer();
      battle.requestRedraw();
      await Future<void>.delayed(const Duration(milliseconds: 150));
      await _dealHand();
    }

    await Future<void>.delayed(const Duration(milliseconds: 200));
    _deckScaleController.reverse(from: 1.0);
    _turnFadeController.forward(from: 0.0);
    audioController.playSfx(SfxType.gameStart);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await _scoreFadeController.forward(from: 0.0);
    setState(() {
      _lockInputs = false;
      Overlay.of(context).insert(deckPopupOverlay);
    });
    widget.battle.runAI();
  }

  Future<void> _dealHand() async {
    final controller = widget.controller;

    final handRedraw = await redrawCompleter.future;
    final audioController = AudioController();
    audioController.playSfx(SfxType.dealHand);
    _deckShuffleController.forward(from: 0.0);
    await Future<void>.delayed(const Duration(milliseconds: 800));
    for (final (i, deckIndex) in handRedraw.deckIndexes.indexed) {
      final newCard = controller.playerDeck[deckIndex];
      newCard
        ..isHeld = true
        ..isPlayable = getMoves(controller.board, newCard).isNotEmpty
        ..isPlayableSpecial = false;
      controller.playerHand[i].value = newCard;
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
  }

  void _setBackgroundFlag() {
    final appLifecycleState = lifecycleNotifier.value;
    backgroundEvent.flag = switch (appLifecycleState) {
      AppLifecycleState.paused => false,
      _ => true,
    };
  }

  Future<void> _onSpecialMove(Map<PlayerID, TableturfMove> moves) async {
    _log.info("special move sequence started");
    final overlayState = Overlay.of(context);
    if (lifecycleNotifier.value == AppLifecycleState.paused) {
      // dont even bother rendering it
      return;
    }
    final animationLayer = OverlayEntry(builder: (_) {
      final battle = widget.battle;
      final mediaQuery = MediaQuery.of(context);
      final isLandscape = mediaQuery.orientation == Orientation.landscape;
      final blueMove = moves[battle.opponent.id]!;
      final yellowMove = moves[battle.player.id]!;
      final yellowSpecial = yellowMove.special;
      final blueSpecial = blueMove.special;

      final blueAlignment = yellowSpecial
          ? (isLandscape ? Alignment(0.3, -0.8) : Alignment(0.8, -0.3))
          : (isLandscape ? Alignment(0.15, -0.8) : Alignment(0.8, -0.15));
      final yellowAlignment = blueSpecial
          ? (isLandscape ? Alignment(-0.3, 0.8) : Alignment(-0.8, 0.3))
          : (isLandscape ? Alignment(-0.15, 0.8) : Alignment(-0.8, 0.15));
      final textAlignment = (blueSpecial && !yellowSpecial)
          ? (isLandscape ? Alignment(-0.15, 0.0) : Alignment(0.0, 0.15))
          : (!blueSpecial && yellowSpecial)
              ? (isLandscape ? Alignment(0.15, 0.0) : Alignment(0.0, -0.15))
              : Alignment.center;
      const textStyle = TextStyle(
        fontFamily: "Splatfont1",
        shadows: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.3),
            offset: Offset(1.5, 1.5),
          ),
        ],
      );

      // nice arbitrary constant i got while testing
      // this describes a vertical background
      const specialBackgroundAspectRatio = 0.6794055421802673;

      final designSpriteScale = isLandscape ? 1.0 : 1.4;

      return AnimatedBuilder(
        animation: _specialMoveController,
        builder: (_, __) {
          return Opacity(
            opacity: specialMoveFade.value,
            child: Stack(
              children: [
                SizedBox(
                  width: mediaQuery.size.width,
                  height: mediaQuery.size.height,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        radius: 1.6,
                        colors: [
                          Color.fromRGBO(75, 57, 166, 0.6),
                          Color.fromRGBO(0, 0, 0, 0.4),
                          Color.fromRGBO(0, 0, 0, 0.7),
                        ],
                        stops: [0.2, 0.6, 1.0],
                      ),
                    ),
                  ),
                ),
                if (blueSpecial)
                  Align(
                    alignment: blueAlignment,
                    child: FractionallySizedBox(
                      heightFactor: isLandscape ? 0.6 : null,
                      widthFactor: isLandscape ? null : 0.6,
                      child: AspectRatio(
                        aspectRatio: isLandscape
                            ? specialBackgroundAspectRatio
                            : 1 / specialBackgroundAspectRatio,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Center(
                              child: FractionallySizedBox(
                                heightFactor: isLandscape
                                    ? 1.0
                                    : 1.0 * specialMoveScale.value,
                                widthFactor: isLandscape
                                    ? 1.0 * specialMoveScale.value
                                    : 1.0,
                                child: CustomPaint(
                                  painter: SpecialBackgroundPainter(
                                    isLandscape,
                                    specialMoveBluePulse,
                                  ),
                                ),
                              ),
                            ),
                            Center(
                              child: Transform.translate(
                                offset: Offset(
                                    0.0,
                                    specialMoveImageOffset.value *
                                        mediaQuery.size.height *
                                        (isLandscape ? -0.1 : -0.05)),
                                child: Transform.scale(
                                  scaleX: designSpriteScale *
                                      specialMoveScale.value,
                                  scaleY: designSpriteScale *
                                      (1.3 - (specialMoveScale.value * 0.3)),
                                  child: Transform.rotate(
                                    angle: -0.05 * pi,
                                    child: Stack(
                                      children: [
                                        Transform.translate(
                                            offset: Offset(3, 3),
                                            child: Image.asset(
                                                blueMove.card.designSprite,
                                                color: Color.fromRGBO(
                                                    184, 139, 254, 1.0))),
                                        Image.asset(blueMove.card.designSprite),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (yellowSpecial)
                  Align(
                    alignment: yellowAlignment,
                    child: FractionallySizedBox(
                      heightFactor: isLandscape ? 0.6 : null,
                      widthFactor: isLandscape ? null : 0.6,
                      child: AspectRatio(
                        aspectRatio: isLandscape
                            ? specialBackgroundAspectRatio
                            : 1 / specialBackgroundAspectRatio,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Center(
                              child: AnimatedBuilder(
                                animation: specialMoveYellowPulse,
                                builder: (_, __) {
                                  return CustomPaint(
                                    painter: SpecialBackgroundPainter(
                                      isLandscape,
                                      specialMoveYellowPulse,
                                    ),
                                    willChange: true,
                                    isComplex: true,
                                    child: FractionallySizedBox(
                                      heightFactor: isLandscape
                                          ? 1.0
                                          : 1.0 * specialMoveScale.value,
                                      widthFactor: isLandscape
                                          ? 1.0 * specialMoveScale.value
                                          : 1.0,
                                    ),
                                  );
                                },
                              ),
                            ),
                            Center(
                              child: Transform.translate(
                                offset: Offset(
                                    0.0,
                                    specialMoveImageOffset.value *
                                        mediaQuery.size.height *
                                        (isLandscape ? -0.1 : -0.05)),
                                child: Transform.scale(
                                  scaleX: designSpriteScale *
                                      specialMoveScale.value,
                                  scaleY: designSpriteScale *
                                      (1.3 - (specialMoveScale.value * 0.3)),
                                  child: Transform.rotate(
                                    angle: -0.05 * pi,
                                    child: Stack(
                                      children: [
                                        Transform.translate(
                                            offset: Offset(3, 3),
                                            child: Image.asset(
                                                yellowMove.card.designSprite,
                                                color: Color.fromRGBO(
                                                    236, 255, 55, 1.0))),
                                        Image.asset(
                                            yellowMove.card.designSprite),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                Align(
                  alignment: textAlignment,
                  child: SizedBox(
                    width: isLandscape
                        ? mediaQuery.size.height * 0.7
                        : mediaQuery.size.width * 0.7,
                    child: FittedBox(
                      fit: BoxFit.fitWidth,
                      child: Transform.rotate(
                        angle: isLandscape ? 0.45 * pi : 0.05 * pi,
                        child: DefaultTextStyle(
                          style: textStyle.copyWith(
                            color: (blueSpecial && !yellowSpecial)
                                ? Color.fromRGBO(184, 139, 254, 1.0)
                                : (!blueSpecial && yellowSpecial)
                                    ? Color.fromRGBO(236, 255, 55, 1.0)
                                    : Colors.white,
                          ),
                          child: Text("Special Attack!"),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
    overlayState.insert(animationLayer);
    _specialMovePulseController.repeat(reverse: true);
    await _specialMoveController.forward(from: 0.0);
    animationLayer.remove();
    _specialMovePulseController.stop();
    _specialMovePulseController.value = 0.0;
    _log.info("special move sequence finished");
  }

  Future<void> _onGameEnd() async {
    _log.info("outro sequence started");
    final audioController = AudioController();
    final overlayState = Overlay.of(context);
    final animationLayer = OverlayEntry(builder: (_) {
      final mediaQuery = MediaQuery.of(context);
      return DefaultTextStyle(
        style: const TextStyle(
          fontFamily: "Splatfont2",
          color: Colors.black,
          fontSize: 20,
          letterSpacing: 0.2,
        ),
        child: Center(
          child: ClipRect(
            child: AnimatedBuilder(
              animation: _outroController,
              child: OverflowBox(
                maxWidth: mediaQuery.size.width * 3,
                child: Container(
                  color: Color.fromRGBO(236, 253, 86, 1.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: Iterable.generate(
                        (mediaQuery.size.width / 45).floor(),
                        (_) => Text("GAME!")).toList(),
                  ),
                ),
              ),
              builder: (context, child) {
                return Transform.rotate(
                  angle: -0.2,
                  child: Transform.translate(
                    offset: Offset(mediaQuery.size.width * outroMove.value, 0),
                    child: Transform.scale(
                      scaleX: outroScale.value,
                      child: child,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
    });
    overlayState.insert(animationLayer);

    audioController.playSfx(SfxType.gameEndWhistle);
    _scoreFadeController.reverse(from: 1.0);
    await _outroController.animateTo(0.5);
    await AudioController()
        .stopSong(fadeDuration: const Duration(milliseconds: 700));
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    await _outroController.forward(from: 0.5);
    animationLayer.remove();
    widget.battle.updateScores();
    _log.info("outro sequence done");

    widget.controller.reset();
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) {
        return PlaySessionEnd(
          key: const Key('play session end'),
          sessionCompleter: widget.sessionCompleter,
          battle: widget.battle,
          controller: widget.controller,
          boardHeroTag: widget.boardHeroTag,
          onWin: widget.onWin,
          onLose: widget.onLose,
          onPostGame: widget.onPostGame,
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

  Future<void> _showDeckPopup() async {
    await _deckPopupController.forward();
  }

  Future<void> _hideDeckPopup() async {
    await _deckPopupController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final battle = widget.battle;
    final controller = widget.controller;
    final settings = context.watch<Settings>();
    final mediaQuery = MediaQuery.of(context);

    final boardWidget = buildBoardWidget(
      key: inputAreaKey,
      onTileSize: (ts) => tileSize = ts,
      controller: controller,
      loopAnimation: settings.continuousAnimation.value,
      boardHeroTag: widget.boardHeroTag,
    );

    final turnCounter = RepaintBoundary(
      child: AnimatedBuilder(
        animation: _turnFadeController,
        child: TurnCounter(
          initialTurnCount: widget.battle.turnCount,
        ),
        builder: (_, child) {
          return Transform.scale(
            scale: turnSize.value,
            child: Opacity(
              opacity: turnFade.value,
              child: child,
            ),
          );
        },
      ),
    );
    final blueScore = RepaintBoundary(
      key: _blueScoreKey,
      child: AnimatedBuilder(
        animation: _scoreFadeController,
        child: ScoreCounter(
          initialScore: widget.battle.playerScores[widget.battle.opponent.id]!,
          player: widget.battle.opponent,
        ),
        builder: (_, child) {
          return Transform.scale(
            scale: scoreSize.value,
            child: Opacity(
              opacity: scoreFade.value,
              child: child,
            ),
          );
        },
      ),
    );
    final yellowScore = RepaintBoundary(
      key: _yellowScoreKey,
      child: AnimatedBuilder(
        animation: _scoreFadeController,
        child: ScoreCounter(
          initialScore: widget.battle.playerScores[widget.battle.player.id]!,
          player: widget.battle.player,
        ),
        builder: (_, child) {
          return Transform.scale(
            scale: scoreSize.value,
            child: Opacity(
              opacity: scoreFade.value,
              child: child,
            ),
          );
        },
      ),
    );

    final cardWidgets = Iterable.generate(controller.playerHand.length, (i) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(
              mediaQuery.orientation == Orientation.landscape
                  ? mediaQuery.size.width * 0.005
                  : mediaQuery.size.height * 0.005),
          child: CardWidget(
            cardNotifier: controller.playerHand[i],
          ),
        ),
      );
    }).toList(growable: false);

    final handWidget = Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(child: cardWidgets[0]),
              Expanded(child: cardWidgets[1]),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(child: cardWidgets[2]),
              Expanded(child: cardWidgets[3]),
            ],
          ),
        ),
      ],
    );

    final passButton = GestureDetector(
      onTap: () {
        if (controller.playerControlIsLocked.value) {
          return;
        }
        controller.moveCardNotifier.value = null;
        controller.moveLocationNotifier.value = null;
        controller.movePassNotifier.value = !controller.movePassNotifier.value;
        controller.moveSpecialNotifier.value = false;
      },
      child: AspectRatio(
        aspectRatio: 3.5 / 1,
        child: AnimatedBuilder(
          animation: controller.movePassNotifier,
          builder: (_, __) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: controller.movePassNotifier.value
                    ? Palette.inGameButtonSelected
                    : Palette.inGameButtonUnselected,
                borderRadius: BorderRadius.all(Radius.circular(10)),
                border: Border.all(
                  width: 0.5,
                  color: Colors.black,
                ),
              ),
              child: Center(child: Text("Pass"))),
        ),
      ),
    );

    Widget fadeOnControlLock({Widget? child}) {
      return AnimatedBuilder(
        animation: controller.playerControlIsLocked,
        child: child,
        builder: (context, child) {
          return AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: !controller.playerControlIsLocked.value ? 1.0 : 0.5,
            child: child,
          );
        },
      );
    }

    final specialButton = GestureDetector(
      onTap: () {
        if (controller.playerControlIsLocked.value) {
          return;
        }
        controller.moveCardNotifier.value = null;
        controller.moveLocationNotifier.value = null;
        controller.moveSpecialNotifier.value = !controller.moveSpecialNotifier.value;
        controller.movePassNotifier.value = false;
      },
      child: AspectRatio(
        aspectRatio: 3.5 / 1,
        child: AnimatedBuilder(
          animation: controller.moveSpecialNotifier,
          builder: (_, __) => AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: controller.moveSpecialNotifier.value
                  ? Color.fromRGBO(216, 216, 0, 1)
                  : Color.fromRGBO(109, 161, 198, 1),
              borderRadius: BorderRadius.all(Radius.circular(10)),
              border: Border.all(
                width: 0.5,
                color: Colors.black,
              ),
            ),
            //height: mediaQuery.orientation == Orientation.portrait ? CardWidget.CARD_HEIGHT : 30,
            //width: mediaQuery.orientation == Orientation.landscape ? CardWidget.CARD_WIDTH : 64,
            child: Center(child: Text("Special")),
          ),
        ),
      ),
    );

    final blueCardSelection = CardSelectionWidget(
      key: _blueSelectionKey,
      player: battle.opponent,
      loopAnimation: settings.continuousAnimation.value,
    );
    final yellowCardSelection = CardSelectionConfirmButton(
      key: _yellowSelectionKey,
      loopAnimation: settings.continuousAnimation.value,
    );

    final cardSelectionScaleDown =
        mediaQuery.orientation == Orientation.landscape ? 0.7 : 0.9;
    final cardSelections = RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            flex: 1,
            child: AspectRatio(
              aspectRatio: CardWidget.CARD_WIDTH / CardWidget.CARD_HEIGHT,
              child: FractionallySizedBox(
                heightFactor: cardSelectionScaleDown,
                widthFactor: cardSelectionScaleDown,
                child: Center(
                  child: blueCardSelection,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: AspectRatio(
              aspectRatio: CardWidget.CARD_WIDTH / CardWidget.CARD_HEIGHT,
              child: FractionallySizedBox(
                heightFactor: cardSelectionScaleDown,
                widthFactor: cardSelectionScaleDown,
                child: Center(
                  child: yellowCardSelection,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    final cardDeck = GestureDetector(
      // used to prevent screen from reading the tap
      onTapDown: (_) {},
      child: Listener(
        onPointerDown: (_) => _showDeckPopup(),
        onPointerUp: (_) => _hideDeckPopup(),
        child: AspectRatio(
          aspectRatio: 1.0,
          child: RepaintBoundary(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                return Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color.fromRGBO(21, 0, 96, 1.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black38,
                        blurRadius: width * 0.03,
                      ),
                    ],
                  ),
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _deckScaleController,
                      builder: (_, __) => Transform.scale(
                        scale: scaleDeckValue.value,
                        child: Stack(
                          children: [
                            Center(
                              child: ColorFiltered(
                                colorFilter: ColorFilter.mode(
                                  scaleDeckColour.value!,
                                  BlendMode.srcATop,
                                ),
                                child: AnimatedBuilder(
                                  animation: _deckShuffleController,
                                  builder: (_, __) => Transform.rotate(
                                    angle: shuffleCardRotate.value * 2 * pi,
                                    child: Stack(
                                      children: [
                                        Transform.translate(
                                          offset:
                                              shuffleBottomCardMove.value * width,
                                          child: _CardDeckSlice(
                                            cardSleeve:
                                                battle.player.cardSleeve,
                                            isDarkened: true,
                                            width: width,
                                          ),
                                        ),
                                        Transform.translate(
                                          offset:
                                              (shuffleTopCardMove.value) * width,
                                          child: _CardDeckSlice(
                                            cardSleeve:
                                                battle.player.cardSleeve,
                                            isDarkened: false,
                                            width: width,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Transform.rotate(
                              angle: 0.05 * pi,
                              child: Align(
                                alignment: Alignment(2.0, 1.25),
                                child: FractionallySizedBox(
                                  widthFactor: 0.5,
                                  child: AspectRatio(
                                    aspectRatio: 4 / 3,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        DecoratedBox(
                                          decoration: const BoxDecoration(
                                            gradient: RadialGradient(
                                              center: Alignment.bottomRight,
                                              radius: 1.2,
                                              colors: [
                                                Color.fromRGBO(8, 8, 8, 1.0),
                                                Color.fromRGBO(38, 38, 38, 1.0),
                                              ],
                                            ),
                                          ),
                                          child: Container(),
                                        ),
                                        FittedBox(
                                          fit: BoxFit.contain,
                                          child: AnimatedBuilder(
                                            animation: Listenable.merge(
                                                controller.playerHand),
                                            builder: (_, __) {
                                              int remainingCards = 0;
                                              for (final card
                                                  in controller.playerDeck) {
                                                if (!card.isHeld &&
                                                    !card.hasBeenPlayed) {
                                                  remainingCards += 1;
                                                }
                                              }
                                              return Text(
                                                remainingCards.toString(),
                                                style: TextStyle(
                                                  fontFamily: "Splatfont2",
                                                  letterSpacing: width * 0.05,
                                                  fontSize: width * 0.2,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
    late final Widget screenContents;

    //[0, 576, 768, 992, 1200, 1400],
    const playerNameStyle = TextStyle(
      fontFamily: "Splatfont1",
      fontStyle: FontStyle.italic,
      color: Colors.white,
      height: 1,
      letterSpacing: 0.6,
      shadows: [
        Shadow(
          color: Color.fromRGBO(128, 128, 128, 1),
          offset: Offset(1, 1),
        ),
      ],
    );
    screenContents = AspectRatioBuilder({
      500 / 1000: Padding(
        padding: mediaQuery.padding.copyWith(top: 0).add(
          EdgeInsets.only(bottom: 10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: mediaQuery.padding.top + 5,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  color: Palette.backgroundPlaySessionHeader,
                ),
                child: SizedBox.expand(),
              ),
            ),
            Expanded(
              flex: 3,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: Palette.backgroundPlaySessionHeader,
                ),
                child: Center(
                  child: FractionallySizedBox(
                    widthFactor: 0.95,
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                              width: 5,
                              color: battle.player.traits.normalColour,
                              margin: const EdgeInsets.only(right: 6)),
                          Text(battle.player.name, style: playerNameStyle),
                          const Spacer(),
                          Text(battle.opponent.name, style: playerNameStyle),
                          Container(
                              width: 5,
                              color: battle.opponent.traits.normalColour,
                              margin: const EdgeInsets.only(left: 6)),
                        ]),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 36,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Palette.backgroundPlaySessionHeader,
                      Colors.transparent,
                      Colors.transparent,
                    ],
                    stops: [
                      0.0,
                      0.03,
                      1.0,
                    ],
                  ),
                ),
                child: Center(
                  child: FractionallySizedBox(
                    heightFactor: 0.9,
                    child: boardWidget,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: FractionallySizedBox(
                widthFactor: 0.95,
                child: Row(
                  children: [
                    Container(
                        width: 5,
                        color: battle.player.traits.specialColour,
                        margin: const EdgeInsets.only(right: 6)),
                    RepaintBoundary(
                      child: FractionallySizedBox(
                        heightFactor: 0.5,
                        child: SpecialMeter(
                          player: battle.player,
                          direction: TextDirection.ltr,
                        ),
                      ),
                    ),
                    const Spacer(),
                    RepaintBoundary(
                      child: FractionallySizedBox(
                        heightFactor: 0.5,
                        child: SpecialMeter(
                          player: battle.opponent,
                          direction: TextDirection.rtl,
                        ),
                      ),
                    ),
                    Container(
                        width: 5,
                        color: battle.opponent.traits.specialColour,
                        margin: const EdgeInsets.only(left: 6)),
                  ]),
              ),
            ),
            const Spacer(flex: 1),
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  const Spacer(flex: 2),
                  Expanded(flex: 2, child: turnCounter),
                  const Spacer(flex: 1),
                  Expanded(flex: 2, child: yellowScore),
                  Expanded(flex: 2, child: blueScore),
                  const Spacer(flex: 1),
                  Expanded(flex: 2, child: cardDeck),
                  const Spacer(flex: 2),
                ],
              ),
            ),
            Expanded(
              flex: 18,
              child: RepaintBoundary(
                child: Container(
                  padding: EdgeInsets.all(10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        flex: 3,
                        child: fadeOnControlLock(
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: handWidget,
                              ),
                              Expanded(
                                flex: 1,
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Expanded(child: passButton),
                                    Expanded(child: specialButton)
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: cardSelections,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        )
      ),
      1000 / 1000: Padding(
        padding: mediaQuery.padding.add(EdgeInsets.symmetric(vertical: 5)),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 5.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      flex: 1,
                      child: Align(
                        alignment: Alignment(-0.85, -0.9),
                        child: FractionallySizedBox(
                          heightFactor: 1 / 3,
                          child: SpecialMeter(player: battle.opponent),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 5,
                      child: fadeOnControlLock(
                        child: Column(
                          children: [
                            Expanded(child: handWidget),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Expanded(
                                  child: FractionallySizedBox(
                                    widthFactor: 0.9,
                                    child: passButton,
                                  ),
                                ),
                                Expanded(
                                  child: FractionallySizedBox(
                                    widthFactor: 0.9,
                                    child: specialButton,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Align(
                        alignment: Alignment(-0.85, 0.9),
                        child: FractionallySizedBox(
                          heightFactor: 1 / 3,
                          child: SpecialMeter(player: battle.player),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: FractionallySizedBox(
                widthFactor: 2 / 5,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Spacer(flex: 1),
                    Expanded(
                      flex: 3,
                      child: Center(child: turnCounter),
                    ),
                    const Spacer(flex: 2),
                    Expanded(
                      flex: 10,
                      child: Center(
                        child: FractionallySizedBox(
                          widthFactor: 0.75,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [blueScore, yellowScore, cardDeck],
                          ),
                        ),
                      ),
                    ),
                    Spacer(flex: 1),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: boardWidget,
            ),
            Expanded(
              flex: 2,
              child: cardSelections,
            ),
          ],
        ),
      ),
    });

    return DefaultTextStyle(
      style: const TextStyle(
        fontFamily: "Splatfont2",
        color: Colors.white,
        fontSize: 16,
        letterSpacing: 0.6,
        shadows: [
          Shadow(
            color: Color.fromRGBO(256, 256, 256, 0.4),
            offset: Offset(1, 1),
          ),
        ],
      ),
      child: Focus(
        autofocus: true,
        onKey: handleKeyPress,
        child: MouseRegion(
          onHover: onHover,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: onTap,
            onPanStart: (details) => onDragStart(details, context),
            onPanUpdate: (details) => onDragUpdate(details, context),
            //onPointerHover: (details) => _onPointerHover(details, context),
            child: WillPopScope(
              onWillPop: () async {
                if (_lockInputs) {
                  return false;
                }
                final audioController = AudioController();
                audioController.playSfx(SfxType.giveUpOpen);
                var choice = await showMultiChoicePrompt(
                  context,
                  title: "Give up?",
                  options: ["Yeah", "Nah"],
                  sfx: [SfxType.giveUpSelect, SfxType.menuButtonPress],
                );
                if (choice == 0) {
                  widget.sessionCompleter.complete();
                  return true;
                }
                return false;
              },
              child: Container(
                color: Palette.backgroundPlaySession,
                child: TableturfBattle(
                  controller: widget.controller,
                  eventStream: eventBroadcast.stream,
                  child: screenContents
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DeckPopupOverlay extends StatefulWidget {
  const DeckPopupOverlay({
    super.key,
    required this.popupController,
    required this.player,
  });

  final AnimationController popupController;
  final TableturfPlayer player;

  @override
  State<DeckPopupOverlay> createState() => _DeckPopupOverlayState();
}

class _DeckPopupOverlayState extends State<DeckPopupOverlay> {
  late final SnapshotController snapshotController = SnapshotController(
    allowSnapshotting: true,
  );
  late final TableturfBattleController controller;
  late final Animation<double> deckPopupFade, deckPopupScale;

  @override
  void initState() {
    super.initState();
    controller = TableturfBattle.getControllerOf(context);
    deckPopupFade = widget.popupController.drive(
      Tween(
        begin: 0.0,
        end: 1.0,
      ),
    );
    deckPopupScale = widget.popupController.drive(
      Tween(
        begin: 0.85,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeOut)),
    );
    for (final card in controller.playerHand) {
      card.addListener(_onHandChange);
    }
  }

  @override
  void dispose() {
    for (final card in controller.playerHand) {
      card.removeListener(_onHandChange);
    }
    super.dispose();
  }

  void _onHandChange() {
    snapshotController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    final deckPopupBackground = widget.popupController.drive(
      DecorationTween(
        begin: const BoxDecoration(
          color: Colors.transparent,
        ),
        end: const BoxDecoration(
          color: Color.fromRGBO(0, 0, 0, 0.7),
        ),
      ),
    );
    late final Widget screen;
    if (mediaQuery.orientation == Orientation.portrait) {
      screen = DecoratedBoxTransition(
        decoration: deckPopupBackground,
        child: Padding(
          padding: mediaQuery.padding + EdgeInsets.all(30),
          child: SnapshotWidget(
            controller: snapshotController,
            painter: PopupTransitionPainter(
              popupOpacity: deckPopupFade,
              popupScale: deckPopupScale,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: const Color.fromRGBO(34, 34, 51, 1.0),
                border: Border.all(
                  color: const Color.fromRGBO(0, 215, 208, 1.0),
                  width: 3.0,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.all(8),
              child: ListenableBuilder(
                listenable: Listenable.merge(controller.playerHand),
                builder: (_, __) => ExactGrid(
                  height: 5,
                  width: 3,
                  children: [
                    for (final card in controller.playerDeck)
                      Padding(
                        padding: const EdgeInsets.all(5),
                        child: HandCardWidget(
                          card: card.data,
                          overlayColor: card.hasBeenPlayed
                              ? const Color.fromRGBO(0, 0, 0, 0.4)
                              : null,
                          borderColor: card.isHeld
                              ? Palette.tileYellow
                              : null,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      // TODO: landscape mode deck view
      screen = Container(

      );
    }
    return IgnorePointer(
      child: RepaintBoundary(
        child: screen,
      ),
    );
  }
}
