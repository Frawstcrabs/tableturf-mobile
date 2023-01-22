import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tableturf_mobile/src/audio/sounds.dart';
import 'package:logging/logging.dart' hide Level;
import 'package:provider/provider.dart';

import 'package:tableturf_mobile/src/audio/audio_controller.dart';
import 'package:tableturf_mobile/src/game_internals/battle.dart';
import 'package:tableturf_mobile/src/game_internals/card.dart';
import 'package:tableturf_mobile/src/game_internals/move.dart';
import 'package:tableturf_mobile/src/game_internals/player.dart';
import 'package:tableturf_mobile/src/style/palette.dart';
import 'package:tableturf_mobile/src/style/my_transition.dart';

import 'session_end.dart';
import 'components/arc_tween.dart';
import 'components/build_board_widget.dart';
import 'components/special_meter.dart';
import 'components/turn_counter.dart';
import 'components/board_widget.dart';
import 'components/card_widget.dart';
import 'components/card_selection.dart';
import 'components/score_counter.dart';

class SpecialBackgroundPainter extends CustomPainter {
  final bool isLandscape;
  final Animation<Color?> paintColor;

  static const shortSideSize = 3/4;

  const SpecialBackgroundPainter(this.isLandscape, this.paintColor):
    super(repaint: paintColor)
  ;

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
    canvas.drawShadow(path.shift(Offset(5, 5)), const Color.fromRGBO(0, 0, 0, 0.4), 5, false);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(SpecialBackgroundPainter oldPainter) {
    return false;
  }
}

class SelectionBackgroundPainter extends CustomPainter {
  final Animation<double> waveAnimation;
  final Orientation orientation;

  static const WAVE_WIDTH = 1/8.5;
  static const WAVE_HEIGHT = 0.2;
  static const SCREEN_DIST = 0.7;

  SelectionBackgroundPainter({
    required this.waveAnimation,
    required this.orientation,
  }):
    super(repaint: waveAnimation)
  ;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(Colors.black38, BlendMode.srcOver);

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeJoin = StrokeJoin.miter
      ..color = Colors.black38;
    final waveWidth = size.height * WAVE_WIDTH;
    final waveHeight = waveWidth * WAVE_HEIGHT;
    final path = Path();

    var d = (waveWidth * -2) * (1 - waveAnimation.value);
    if (orientation == Orientation.landscape) {
      path.moveTo(size.width, size.height);
      path.lineTo(size.width, 0.0);
      path.lineTo(size.width * (1.0 - SCREEN_DIST), d);
      var outWave = true;

      for (; d < size.height; d += waveWidth) {
        path.relativeQuadraticBezierTo(
          outWave ? waveHeight : -waveHeight, waveWidth / 2,
          0.0, waveWidth,
        );
        outWave = !outWave;
      }
    } else {
      path.moveTo(size.width, 0.0);
      path.lineTo(0.0, 0.0);
      path.lineTo(d, size.height * SCREEN_DIST);
      //path.moveTo(size.width, size.height);
      //path.lineTo(size.width, 0.0);
      //path.lineTo(size.width * (1.0 - SCREEN_DIST), d);
      var outWave = true;

      for (; d < size.height; d += waveWidth) {
        path.relativeQuadraticBezierTo(
          waveWidth / 2, outWave ? waveHeight : -waveHeight,
          waveWidth, 0.0,
        );
        outWave = !outWave;
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(SelectionBackgroundPainter oldDelegate) {
    return this.orientation != oldDelegate.orientation;
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
                    borderRadius: BorderRadius.circular(20/CardWidget.CARD_HEIGHT * width),
                    color: Colors.black,
                  ),
                )
            ),
          ),
          Transform.translate(
            offset: (DECK_SPACING * -0.5) * width,
            child: AspectRatio(
                aspectRatio: CardWidget.CARD_WIDTH / CardWidget.CARD_HEIGHT,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20/CardWidget.CARD_HEIGHT * width),
                    color: Colors.grey[900],
                  ),
                )
            ),
          ),
          Transform.translate(
            offset: (DECK_SPACING * 0.0) * width,
            child: AspectRatio(
                aspectRatio: CardWidget.CARD_WIDTH / CardWidget.CARD_HEIGHT,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20/CardWidget.CARD_HEIGHT * width),
                    color: Colors.black,
                  ),
                )
            ),
          ),
          Transform.translate(
            offset: (DECK_SPACING * 0.5) * width,
            child: AspectRatio(
              aspectRatio: CardWidget.CARD_WIDTH / CardWidget.CARD_HEIGHT,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20/CardWidget.CARD_HEIGHT * width),
                  color: Colors.grey[900],
                ),
              )
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
                child: Image.asset(cardSleeve)
            )
                : Image.asset(cardSleeve),
          ),
        ]
    );
  }
}

class _SelectionButton extends StatefulWidget {
  final void Function() onSelect;
  final double designRatio;
  final Widget child;
  const _SelectionButton({
    super.key,
    required this.onSelect,
    required this.designRatio,
    required this.child,
  });

  @override
  State<_SelectionButton> createState() => _SelectionButtonState();
}

class _SelectionButtonState extends State<_SelectionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _selectController;
  late final Animation<double> selectScale;
  late final Animation<Color?> selectColor, selectTextColor;

  @override
  void initState() {
    super.initState();

    _selectController = AnimationController(
      duration: const Duration(milliseconds: 125),
      vsync: this
    );
    const selectDownscale = 0.9;
    selectScale = TweenSequence([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: selectDownscale)
          .chain(CurveTween(curve: Curves.decelerate)),
        weight: 50
      ),
      TweenSequenceItem(
        tween: Tween(begin: selectDownscale, end: 1.05)
          .chain(CurveTween(curve: Curves.decelerate.flipped)),
        weight: 50
      ),
    ]).animate(_selectController);
    selectColor = ColorTween(
        begin: const Color.fromRGBO(71, 16, 175, 1.0),
        end: const Color.fromRGBO(167, 231, 9, 1.0)
    )
        .animate(_selectController);
    selectTextColor = ColorTween(
        begin: Colors.white,
        end: Colors.black
    )
        .animate(_selectController);
  }

  @override
  void dispose() {
    _selectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await _selectController.forward(from: 0.0);
        await Future<void>.delayed(const Duration(milliseconds: 50));
        widget.onSelect();
      },
      child: AnimatedBuilder(
        animation: _selectController,
        builder: (_, __) {
          final textStyle = DefaultTextStyle.of(context).style.copyWith(
            color: selectTextColor.value
          );
          return AspectRatio(
            aspectRatio: 2/1,
            child: Transform.scale(
              scale: selectScale.value,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: selectColor.value,
                  borderRadius: BorderRadius.circular(20 * widget.designRatio),
                  border: Border.all(
                    color: Colors.black,
                    width: 1.0 * widget.designRatio,
                  ),
                ),
                child: Center(
                  child: DefaultTextStyle(
                    style: textStyle,
                    child: widget.child
                  )
                )
              ),
            )
          );
        }
      ),
    );
  }
}


class PlaySessionScreen extends StatefulWidget {
  final TableturfBattle battle;

  const PlaySessionScreen({
    super.key,
    required this.battle,
  });

  @override
  State<PlaySessionScreen> createState() => _PlaySessionScreenState();
}

class _PlaySessionScreenState extends State<PlaySessionScreen>
    with TickerProviderStateMixin {
  static final _log = Logger('PlaySessionScreenState');

  final GlobalKey _boardTileKey = GlobalKey(debugLabel: "InputArea");
  final GlobalKey _bluebattleKey = GlobalKey(debugLabel: "BluebattleWidget");
  final GlobalKey _yellowbattleKey = GlobalKey(debugLabel: "YellowbattleWidget");
  final GlobalKey _blueScoreKey = GlobalKey(debugLabel: "BlueScoreWidget");
  final GlobalKey _yellowScoreKey = GlobalKey(debugLabel: "YellowScoreWidget");
  double tileSize = 22.0;
  Offset? piecePosition;
  bool _tapTimeExceeded = true,
      _noPointerMovement = true,
      _buttonPressed = false,
      _lockInputs = true;
  Timer? tapTimer;

  late final AnimationController _turnFadeController, _scoreFadeController;
  late final Animation<double> scoreFade, scoreSize, turnFade, turnSize;

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

  late final AnimationController _redrawSelectionController;
  late final AnimationController _redrawSelectionWaveController;
  late final Animation<double> redrawSelectionOpacity, redrawSelectionScale, redrawSelectionRotate;
  late final Animation<Offset> redrawSelectionOffset;

  @override
  void initState() {
    super.initState();
    widget.battle.endOfGameNotifier.addListener(_onGameEnd);
    widget.battle.specialMoveNotifier.addListener(_onSpecialMove);

    _scoreFadeController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this
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
      vsync: this
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
      vsync: this
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
      )
    ]).animate(_outroController);

    _specialMoveController = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this
    );
    _specialMovePulseController = AnimationController(
      duration: const Duration(milliseconds: 175),
      vsync: this
    )..repeat(reverse: true);

    specialMoveYellowPulse = ColorTween(
      begin: Colors.yellow,
      end: Colors.orange,
    ).chain(CurveTween(curve: Curves.easeInOut)).animate(_specialMovePulseController);
    specialMoveBluePulse = ColorTween(
      begin: const Color.fromRGBO(69, 53, 157, 1.0),
      end: const Color.fromRGBO(96, 58, 255, 1.0),
    ).chain(CurveTween(curve: Curves.easeInOut)).animate(_specialMovePulseController);
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
        tween: Tween(begin: 1.0, end: 0.3)
            .chain(CurveTween(curve: Curves.easeIn)),
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
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 5,
      ),
    ]).animate(_specialMoveController);

    _deckShuffleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this
    );
    final startOffset = _CardDeckSlice.DECK_SPACING * 1;
    final endOffset = _CardDeckSlice.DECK_SPACING * -1;
    final topTween = CircularArcOffsetTween(
        begin: startOffset,
        end: endOffset,
        clockwise: false,
        angle: pi*1.85
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
      TweenSequenceItem(tween: ConstantTween(startOffset + Offset(0.035, -0.09)), weight: 100),
      TweenSequenceItem(tween: ConstantTween(startOffset + Offset(0.035, -0.09)), weight: 99),
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
        weight: 100
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: defaultRotation * 2.5,
          end: defaultRotation,
        ).chain(CurveTween(curve: Curves.decelerate.flipped)),
        weight: 100
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
    )
        .chain(CurveTween(curve: Curves.easeOut))
        .animate(_deckScaleController);

    _redrawSelectionController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this
    );
    _redrawSelectionWaveController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this
    );
    redrawSelectionOpacity = TweenSequence([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0),
        weight: 50
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0),
        weight: 35
      ),
      TweenSequenceItem(
        tween: ConstantTween(0.0),
        weight: 15
      ),
    ]).animate(_redrawSelectionController);
    redrawSelectionScale = TweenSequence([
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: 50
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.9),
        weight: 50
      ),
    ]).animate(_redrawSelectionController);
    redrawSelectionOffset = TweenSequence([
      TweenSequenceItem(
        tween: Tween(
          begin: Offset(0.0, -100.0),
          end: Offset(0.0, 20.0),
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 42
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: Offset(0.0, 20.0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 8
      ),
      TweenSequenceItem(
        tween: ConstantTween(Offset.zero),
        weight: 50
      ),
    ]).animate(_redrawSelectionController);
    const defaultRotate = -0.005 * pi;
    redrawSelectionRotate = TweenSequence([
      TweenSequenceItem(
        tween: Tween(begin: 0.01 * pi, end: defaultRotate),
        weight: 50
      ),
      TweenSequenceItem(
        tween: ConstantTween(defaultRotate),
        weight: 50
      ),
    ]).animate(_redrawSelectionController);
    _redrawSelectionWaveController.repeat();

    _playInitSequence();
  }

  Future<void> _playInitSequence() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final audioController = AudioController();

    await _deckScaleController.forward(from: 0.0);
    await _dealHand();

    final shouldRedraw = await _checkRedrawHand();
    if (shouldRedraw) {
      for (final card in widget.battle.yellow.hand) {
        final heldCard = card.value;
        if (heldCard != null) {
          heldCard.isHeld = false;
          heldCard.isPlayable = false;
          heldCard.isPlayableSpecial = false;
        }
        card.value = null;
      }
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
    });
    widget.battle.runBlueAI();
    //widget.battle.runYellowAI();
  }

  Future<bool> _checkRedrawHand() async {
    _log.info("special move sequence started");
    final overlayState = Overlay.of(context)!;
    final completer = Completer<bool>();
    late final OverlayEntry selectionLayer;

    void Function() createTapCallback(bool ret) {
      return () async {
        print("Callback with $ret");
        await _redrawSelectionController.forward();
        selectionLayer.remove();
        completer.complete(ret);
      };
    }

    selectionLayer = OverlayEntry(builder: (context) {
      final mediaQuery = MediaQuery.of(context);
      final isLandscape = mediaQuery.orientation == Orientation.landscape;
      return AnimatedBuilder(
        animation: _redrawSelectionController,
        builder: (_, __) {
          return Opacity(
            opacity: redrawSelectionOpacity.value,
            child: CustomPaint(
              painter: SelectionBackgroundPainter(
                waveAnimation: _redrawSelectionWaveController,
                orientation: mediaQuery.orientation,
              ),
              child: Align(
                alignment: isLandscape ? Alignment(0.4, 0.0) : Alignment(0.0, -0.4),
                child: FractionallySizedBox(
                  heightFactor: isLandscape ? 0.5 : null,
                  widthFactor: isLandscape ? null : 0.8,
                  child: AspectRatio(
                    aspectRatio: 4/3,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        const designWidth = 646;
                        final designRatio = constraints.maxWidth / designWidth;
                        return DefaultTextStyle(
                          style: TextStyle(
                            fontFamily: "Splatfont2",
                            color: Colors.white,
                            fontSize: 25 * designRatio,
                          ),
                          child: Transform.translate(
                            offset: redrawSelectionOffset.value * designRatio,
                            child: Transform.scale(
                              scale: redrawSelectionScale.value,
                              child: Transform.rotate(
                                angle: redrawSelectionRotate.value,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[850],
                                    borderRadius: BorderRadius.circular(60 * designRatio),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Center(
                                          child: Text(
                                            "Redraw hand?",
                                            style: TextStyle(
                                              fontSize: 35 * designRatio,
                                            ),
                                          )
                                        )
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: FractionallySizedBox(
                                          heightFactor: 0.7,
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                            children: [
                                              _SelectionButton(
                                                onSelect: createTapCallback(false),
                                                designRatio: designRatio,
                                                child: Text("Hold Steady")
                                              ),
                                              _SelectionButton(
                                                onSelect: createTapCallback(true),
                                                designRatio: designRatio,
                                                child: Text("Redraw!")
                                              ),
                                            ]
                                          ),
                                        )
                                      )
                                    ]
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                    ),
                  ),
                )
              )
            )
          );
        }
      );
    });
    overlayState.insert(selectionLayer);
    await _redrawSelectionController.animateTo(0.5);

    return completer.future;
  }

  Future<void> _dealHand() async {
    final battle = widget.battle;
    final yellow = battle.yellow;

    final audioController = AudioController();
    audioController.playSfx(SfxType.dealHand);
    _deckShuffleController.forward(from: 0.0);
    await Future<void>.delayed(const Duration(milliseconds: 800));
    for (var i = 0; i < 4; i++) {
      final newCard = yellow.deck.where((card) => !card.isHeld && !card.hasBeenPlayed).toList().random();
      newCard.isHeld = true;
      newCard.isPlayable = getMoves(battle.board, newCard).isNotEmpty;
      newCard.isPlayableSpecial = false;
      yellow.hand[i].value = newCard;
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
  }

  @override
  void dispose() {
    AudioController().musicPlayer.stop();
    widget.battle.endOfGameNotifier.removeListener(_onGameEnd);
    widget.battle.specialMoveNotifier.removeListener(_onSpecialMove);
    _outroController.dispose();
    _turnFadeController.dispose();
    _scoreFadeController.dispose();
    _specialMoveController.dispose();
    _specialMovePulseController.dispose();
    _deckShuffleController.dispose();
    _deckScaleController.dispose();
    _redrawSelectionController.dispose();
    _redrawSelectionWaveController.dispose();
    super.dispose();
  }

  Future<void> _onSpecialMove() async {
    _log.info("special move sequence started");
    final overlayState = Overlay.of(context)!;
    final animationLayer = OverlayEntry(builder: (_) {
      final mediaQuery = MediaQuery.of(context);
      final isLandscape = mediaQuery.orientation == Orientation.landscape;
      final blueMove = widget.battle.blueMoveNotifier.value!;
      final yellowMove = widget.battle.yellowMoveNotifier.value!;
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
      final textStyle = const TextStyle(
        fontFamily: "Splatfont1",
        shadows: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.3),
            offset: Offset(1.5, 1.5),
          )
        ]
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
                        stops: [
                          0.2,
                          0.6,
                          1.0
                        ]
                      )
                    )
                  ),
                ),
                if (blueSpecial) Align(
                    alignment: blueAlignment,
                    child: FractionallySizedBox(
                      heightFactor: isLandscape ? 0.6 : null,
                      widthFactor: isLandscape ? null : 0.6,
                      child: AspectRatio(
                        aspectRatio: isLandscape ? specialBackgroundAspectRatio : 1/specialBackgroundAspectRatio,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Center(
                              child: AnimatedBuilder(
                                  animation: specialMoveBluePulse,
                                  builder: (_, __) {
                                    return FractionallySizedBox(
                                      heightFactor: isLandscape ? 1.0 : 1.0 * specialMoveScale.value,
                                      widthFactor: isLandscape ? 1.0 * specialMoveScale.value : 1.0,
                                      child: CustomPaint(
                                          painter: SpecialBackgroundPainter(
                                            isLandscape,
                                            specialMoveBluePulse,
                                          )
                                      ),
                                    );
                                  }
                              ),
                            ),
                            Center(
                              child: Transform.translate(
                                offset: Offset(
                                  0.0,
                                  specialMoveImageOffset.value * mediaQuery.size.height * (isLandscape ? -0.1 : -0.05)
                                ),
                                child: Transform.scale(
                                  scaleX: designSpriteScale * specialMoveScale.value,
                                  scaleY: designSpriteScale * (1.3 - (specialMoveScale.value * 0.3)),
                                  child: Transform.rotate(
                                      angle: -0.05 * pi,
                                      child: Stack(
                                        children: [
                                          Transform.translate(
                                              offset: Offset(3, 3),
                                              child: Image.asset(
                                                  blueMove.card.designSprite,
                                                  color: Color.fromRGBO(184, 139, 254, 1.0)
                                              )
                                          ),
                                          Image.asset(blueMove.card.designSprite),
                                        ],
                                      )
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    )
                ),
                if (yellowSpecial) Align(
                    alignment: yellowAlignment,
                    child: FractionallySizedBox(
                      heightFactor: isLandscape ? 0.6 : null,
                      widthFactor: isLandscape ? null : 0.6,
                      child: AspectRatio(
                        aspectRatio: isLandscape ? specialBackgroundAspectRatio : 1/specialBackgroundAspectRatio,
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
                                        heightFactor: isLandscape ? 1.0 : 1.0 * specialMoveScale.value,
                                        widthFactor: isLandscape ? 1.0 * specialMoveScale.value : 1.0,
                                      ),
                                    );
                                  }
                              ),
                            ),
                            Center(
                              child: Transform.translate(
                                offset: Offset(
                                  0.0,
                                  specialMoveImageOffset.value * mediaQuery.size.height * (isLandscape ? -0.1 : -0.05)
                                ),
                                child: Transform.scale(
                                  scaleX: designSpriteScale * specialMoveScale.value,
                                  scaleY: designSpriteScale * (1.3 - (specialMoveScale.value * 0.3)),
                                  child: Transform.rotate(
                                      angle: -0.05 * pi,
                                      child: Stack(
                                        children: [
                                          Transform.translate(
                                              offset: Offset(3, 3),
                                              child: Image.asset(
                                                  yellowMove.card.designSprite,
                                                  color: Color.fromRGBO(236, 255, 55, 1.0)
                                              )
                                          ),
                                          Image.asset(yellowMove.card.designSprite),
                                        ],
                                      )
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    )
                ),
                Align(
                  alignment: textAlignment,
                  child: SizedBox(
                    width: isLandscape ? mediaQuery.size.height * 0.7 : mediaQuery.size.width * 0.7,
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
              ]
            ),
          );
        }
      );
    });
    overlayState.insert(animationLayer);
    await _specialMoveController.forward(from: 0.0);
    animationLayer.remove();
    _log.info("special move sequence finished");
  }

  Future<void> _onGameEnd() async {
    _log.info("outro sequence started");
    final audioController = AudioController();
    final overlayState = Overlay.of(context)!;
    final animationLayer = OverlayEntry(builder: (_) {
      final mediaQuery = MediaQuery.of(context);
      return DefaultTextStyle(
        style: TextStyle(
          fontFamily: "Splatfont2",
          color: Colors.black,
          fontSize: 20,
          letterSpacing: 0.2,
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _outroController,
            child: UnconstrainedBox(
              child: Container(
                width: mediaQuery.size.width * 3,
                color: Color.fromRGBO(236, 253, 86, 1.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: Iterable.generate(
                    (mediaQuery.size.width / 45).floor(),
                    (_) => Text("GAME!")
                  ).toList()
                )
              ),
            ),
            builder: (context, child) {
              return Transform.rotate(
                angle: -0.2,
                child: Transform.translate(
                  offset: Offset(
                    mediaQuery.size.width * outroMove.value,
                    0
                  ),
                  child: Transform.scale(
                    scaleX: outroScale.value,
                    child: child,
                  ),
                ),
              );
            }
          ),
        ),
      );
    });
    overlayState.insert(animationLayer);

    audioController.playSfx(SfxType.gameEndWhistle);
    _scoreFadeController.reverse(from: 1.0);
    await _outroController.animateTo(0.5);
    await AudioController().stopSong(
      fadeDuration: const Duration(milliseconds: 1000)
    );
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    await _outroController.forward(from: 0.5);
    animationLayer.remove();
    widget.battle.updateScores();
    _log.info("outro sequence done");

    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) {
        return PlaySessionEnd(
          key: const Key('play session end'),
          battle: widget.battle
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

  void _updateLocation(PointerEvent details, BuildContext rootContext) {
    final battle = widget.battle;
    if (battle.yellowMoveNotifier.value != null && battle.moveCardNotifier.value != null) {
      return;
    }
    final board = battle.board;
    if (piecePosition != null) {
      piecePosition = piecePosition! + details.localDelta;
    }

    final boardContext = _boardTileKey.currentContext!;
    // find the coordinates of the board within the input area
    final boardLocation = (boardContext.findRenderObject()! as RenderBox).localToGlobal(
        Offset.zero,
        ancestor: rootContext.findRenderObject()
    );
    final boardTileStep = tileSize;
    final newX = ((piecePosition!.dx - boardLocation.dx) / boardTileStep).floor();
    final newY = ((piecePosition!.dy - boardLocation.dy) / boardTileStep).floor();
    final newCoords = Coords(
        clamp(newX, 0, board[0].length - 1),
        clamp(newY, 0, board.length - 1),
    );
    if ((
    newY < 0 ||
        newY >= board.length ||
        newX < 0 ||
        newX >= board[0].length
    ) && details.kind == PointerDeviceKind.mouse) {
      battle.moveLocationNotifier.value = null;
      // if pointer is touch, let the position remain
    } else if (battle.moveLocationNotifier.value != newCoords) {
      _noPointerMovement = false;
      final audioController = AudioController();
      if (battle.moveCardNotifier.value != null && !battle.movePassNotifier.value) {
        audioController.playSfx(SfxType.cursorMove);
      }
      battle.moveLocationNotifier.value = newCoords;
    }
  }

  void _resetPiecePosition(BuildContext rootContext) {
    final battle = widget.battle;
    final boardContext = _boardTileKey.currentContext!;
    final boardTileStep = tileSize;
    final boardLocation = (boardContext.findRenderObject()! as RenderBox).localToGlobal(
        Offset.zero,
        ancestor: rootContext.findRenderObject()
    );
    if (battle.moveLocationNotifier.value == null) {
      battle.moveLocationNotifier.value = Coords(
          battle.board[0].length ~/ 2,
          battle.board.length ~/ 2
      );
    }
    final pieceLocation = battle.moveLocationNotifier.value!;
    piecePosition = Offset(
        boardLocation.dx + (pieceLocation.x * boardTileStep) + (boardTileStep / 2),
        boardLocation.dy + (pieceLocation.y * boardTileStep) + (boardTileStep / 2)
    );
  }

  void _onPointerHover(PointerEvent details, BuildContext context) {
    if (_lockInputs) return;

    if (details.kind == PointerDeviceKind.mouse) {
      piecePosition = details.localPosition;
      _updateLocation(details, context);
    }
  }

  void _onPointerMove(PointerEvent details, BuildContext context) {
    if (_lockInputs) return;

    if (_buttonPressed) return;
    _updateLocation(details, context);
  }

  void _onPointerDown(PointerEvent details, BuildContext context) {
    if (_lockInputs) return;

    final battle = widget.battle;
    if (_buttonPressed) return;
    if (details.kind == PointerDeviceKind.mouse) {
      if (battle.playerControlLock.value) {
        battle.confirmMove();
      }
    } else {
      _resetPiecePosition(context);
      _tapTimeExceeded = false;
      _noPointerMovement = true;
      tapTimer = Timer(const Duration(milliseconds: 300), () {
        _tapTimeExceeded = true;
      });
      _updateLocation(details, context);
    }
  }

  void _onPointerUp(PointerEvent details, BuildContext context) {
    if (_lockInputs) return;

    final battle = widget.battle;
    if (_buttonPressed) {
      _buttonPressed = false;
    } else {
      if (details.kind == PointerDeviceKind.touch) {
        tapTimer?.cancel();
        tapTimer = null;
        if (!_tapTimeExceeded && _noPointerMovement && battle.playerControlLock.value) {
          battle.rotateRight();
        }
      }
    }
  }

  KeyEventResult _handleKeyPress(FocusNode node, RawKeyEvent event) {
    if (_lockInputs) return KeyEventResult.ignored;

    final battle = widget.battle;
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.keyQ) {
        if (!battle.playerControlLock.value) {
          return KeyEventResult.ignored;
        }
        battle.rotateLeft();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyE) {
        if (!battle.playerControlLock.value) {
          return KeyEventResult.ignored;
        }
        battle.rotateRight();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    print("screen building");
    final battle = widget.battle;
    final palette = context.watch<Palette>();
    final mediaQuery = MediaQuery.of(context);
    print(mediaQuery.devicePixelRatio);

    final boardWidget = buildBoardWidget(
      battle: battle,
      key: _boardTileKey,
      onTileSize: (ts) => tileSize = ts,
    );

    final turnCounter = RepaintBoundary(
      child: AnimatedBuilder(
        animation: _turnFadeController,
        child: TurnCounter(
          battle: battle,
        ),
        builder: (_, child) {
          return Transform.scale(
            scale: turnSize.value,
            child: Opacity(
              opacity: turnFade.value,
              child: child,
            ),
          );
        }
      ),
    );
    final blueScore = RepaintBoundary(
      key: _blueScoreKey,
      child: AnimatedBuilder(
        animation: _scoreFadeController,
        child: ScoreCounter(
            scoreNotifier: battle.blueCountNotifier,
            traits: const BlueTraits()
        ),
        builder: (_, child) {
          return Transform.scale(
            scale: scoreSize.value,
            child: Opacity(
              opacity: scoreFade.value,
              child: child,
            ),
          );
        }
      ),
    );
    final yellowScore = RepaintBoundary(
      key: _yellowScoreKey,
      child: AnimatedBuilder(
        animation: _scoreFadeController,
        child: ScoreCounter(
          scoreNotifier: battle.yellowCountNotifier,
          traits: const YellowTraits()
        ),
        builder: (_, child) {
          return Transform.scale(
            scale: scoreSize.value,
            child: Opacity(
              opacity: scoreFade.value,
              child: child,
            ),
          );
        }
      ),
    );

    final cardWidgets = Iterable.generate(battle.yellow.hand.length, (i) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(
            mediaQuery.orientation == Orientation.landscape
              ? mediaQuery.size.width * 0.005
              : mediaQuery.size.height * 0.005
          ),
          child: CardWidget(
            cardNotifier: battle.yellow.hand[i],
            battle: battle,
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
            ]
          )
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(child: cardWidgets[2]),
              Expanded(child: cardWidgets[3]),
            ]
          )
        ),
      ]
    );

    final passButton = GestureDetector(
      onTap: () {
        if (!battle.playerControlLock.value) {
          return;
        }
        battle.moveCardNotifier.value = null;
        battle.moveLocationNotifier.value = null;
        battle.movePassNotifier.value = !battle.movePassNotifier.value;
        battle.moveSpecialNotifier.value = false;
      },
      child: AspectRatio(
        aspectRatio: 3.5/1,
        child: AnimatedBuilder(
          animation: battle.movePassNotifier,
          builder: (_, __) => AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: battle.movePassNotifier.value
                  ? palette.buttonSelected
                  : palette.buttonUnselected,
              borderRadius: BorderRadius.all(Radius.circular(10)),
              border: Border.all(
                width: BoardTile.EDGE_WIDTH,
                color: Colors.black,
              ),
            ),
            child: Center(child: Text("Pass"))
          )
        ),
      )
    );

    Widget blockCursorMovement({Widget? child}) {
      return IgnorePointer(
        ignoring: _lockInputs,
        child: Listener(
          onPointerDown: (details) {
            _buttonPressed = true;
          },
          onPointerUp: (details) {},
          child: child,
        )
      );
    }

    Widget fadeOnControlLock({Widget? child}) {
      return AnimatedBuilder(
        animation: battle.playerControlLock,
        child: child,
        builder: (context, child) {
          return AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: battle.playerControlLock.value ? 1.0 : 0.5,
            child: child,
          );
        }
      );
    }

    final specialButton = GestureDetector(
      onTap: () {
        if (!battle.playerControlLock.value) {
          return;
        }
        battle.moveCardNotifier.value = null;
        battle.moveLocationNotifier.value = null;
        battle.moveSpecialNotifier.value = !battle.moveSpecialNotifier.value;
        battle.movePassNotifier.value = false;
      },
      child: AspectRatio(
        aspectRatio: 3.5/1,
        child: AnimatedBuilder(
          animation: battle.moveSpecialNotifier,
          builder: (_, __) => AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: battle.moveSpecialNotifier.value
                  ? Color.fromRGBO(216, 216, 0, 1)
                  : Color.fromRGBO(109, 161, 198, 1),
              borderRadius: BorderRadius.all(Radius.circular(10)),
              border: Border.all(
                width: BoardTile.EDGE_WIDTH,
                color: Colors.black,
              ),
            ),
            //height: mediaQuery.orientation == Orientation.portrait ? CardWidget.CARD_HEIGHT : 30,
            //width: mediaQuery.orientation == Orientation.landscape ? CardWidget.CARD_WIDTH : 64,
            child: Center(child: Text("Special")),
          )
        ),
      )
    );

    final blueCardbattle = CardSelectionWidget(
      key: _bluebattleKey,
      battle: battle,
      player: battle.blue,
      moveNotifier: battle.blueMoveNotifier,
      tileColour: palette.tileBlue,
      tileSpecialColour: palette.tileBlueSpecial,
    );
    final yellowCardbattle = CardSelectionConfirmButton(
      key: _yellowbattleKey,
      battle: battle
    );

    final cardbattleScaleDown = mediaQuery.orientation == Orientation.landscape ? 0.7 : 0.9;
    final cardbattles = RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            flex: 1,
            child: AspectRatio(
              aspectRatio: CardWidget.CARD_WIDTH/CardWidget.CARD_HEIGHT,
              child: FractionallySizedBox(
                heightFactor: cardbattleScaleDown,
                widthFactor: cardbattleScaleDown,
                child: Center(
                  child: blueCardbattle,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: AspectRatio(
              aspectRatio: CardWidget.CARD_WIDTH/CardWidget.CARD_HEIGHT,
              child: FractionallySizedBox(
                heightFactor: cardbattleScaleDown,
                widthFactor: cardbattleScaleDown,
                child: Center(
                  child: yellowCardbattle,
                ),
              ),
            ),
          ),
        ]
      ),
    );

    final cardDeck = AspectRatio(
      aspectRatio: 1.0,
      child: RepaintBoundary(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            print(constraints);
            return Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color.fromRGBO(21, 0, 96, 1.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black38,
                      blurRadius: width * 0.03,
                    )
                  ]
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
                                        offset: shuffleBottomCardMove.value * width,
                                        child: _CardDeckSlice(
                                          cardSleeve: widget.battle.yellow.cardSleeve,
                                          isDarkened: true,
                                          width: width
                                        ),
                                      ),
                                      Transform.translate(
                                        offset: (shuffleTopCardMove.value) * width,
                                        child: _CardDeckSlice(
                                          cardSleeve: widget.battle.yellow.cardSleeve,
                                          isDarkened: false,
                                          width: width
                                        ),
                                      ),
                                    ]
                                  ),
                                )
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
                                aspectRatio: 4/3,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: RadialGradient(
                                          center: Alignment.bottomRight,
                                          radius: 1.2,
                                          colors: const [
                                            Color.fromRGBO(8, 8, 8, 1.0),
                                            Color.fromRGBO(38, 38, 38, 1.0),
                                          ]
                                        )
                                      ),
                                      child: Container(),
                                    ),
                                    FittedBox(
                                      fit: BoxFit.contain,
                                      child: AnimatedBuilder(
                                        animation: Listenable.merge(battle.yellow.hand),
                                        builder: (_, __) {
                                          int remainingCards = 0;
                                          for (final card in battle.yellow.deck) {
                                            if (!card.isHeld && !card.hasBeenPlayed) {
                                              remainingCards += 1;
                                            }
                                          }
                                          return Text(remainingCards.toString(), style: TextStyle(
                                            fontFamily: "Splatfont2",
                                            letterSpacing: width * 0.05,
                                            fontSize: width * 0.2,
                                          ));
                                        }
                                      )
                                    ),
                                  ],
                                ),
                              )
                            ),
                          ),
                        )
                      ],
                    ),
                  )
                ),
              )
            );
          }
        ),
      ),
    );

    late final Widget screenContents;
    if (mediaQuery.orientation == Orientation.portrait) {
      screenContents = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: mediaQuery.padding.top + 10
          ),
          Expanded(
            flex: 1,
            child: FractionallySizedBox(
              widthFactor: 0.95,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        blueScore,
                        Container(width: 20),
                        Expanded(child: RepaintBoundary(child: SpecialMeter(player: battle.blue))),
                      ],
                    ),
                  ),
                  turnCounter,
                ]
              ),
            ),
          ),
          Expanded(
            flex: 12,
            child: FractionallySizedBox(
              heightFactor: 0.9,
              child: boardWidget
            ),
          ),
          Expanded(
            flex: 1,
            child: FractionallySizedBox(
              widthFactor: 0.95,
              child: Row(
                children: [
                  yellowScore,
                  Container(width: 20),
                  Expanded(child: RepaintBoundary(child: SpecialMeter(player: battle.yellow))),
                  cardDeck,
                ],
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: blockCursorMovement(
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
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [Expanded(child: passButton), Expanded(child: specialButton)],
                                    ),
                                  ),
                                ],
                              )
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: cardbattles,
                        )
                      ]
                  ),
                ),
              ),
            ),
          ),
          Container(
            height: mediaQuery.padding.bottom + 5,
          )
        ],
      );
    } else {
      screenContents = Column(
        children: [
          Container(
            height: mediaQuery.padding.top + 10
          ),
          Expanded(
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
                              heightFactor: 1/3,
                              child: SpecialMeter(player: battle.blue)
                            )
                          )
                        ),
                        Expanded(
                          flex: 5,
                          child: blockCursorMovement(
                            child: fadeOnControlLock(
                              child: Column(
                                children: [
                                  Expanded(
                                      child: handWidget
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Expanded(
                                        child: FractionallySizedBox(
                                          widthFactor: 0.9,
                                          child: passButton,
                                        )
                                      ),
                                      Expanded(
                                          child: FractionallySizedBox(
                                            widthFactor: 0.9,
                                            child: specialButton,
                                          )
                                      )
                                    ],
                                  )
                                ]
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Align(
                            alignment: Alignment(-0.85, 0.9),
                            child: FractionallySizedBox(
                              heightFactor: 1/3,
                              child: SpecialMeter(player: battle.yellow)
                            )
                          )
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: FractionallySizedBox(
                    widthFactor: 2/5,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [turnCounter, blueScore, yellowScore, cardDeck],
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: boardWidget
                ),
                Expanded(
                  flex: 2,
                  child: blockCursorMovement(
                    child: cardbattles,
                  )
                )
              ]
            ),
          ),
          Container(
            height: mediaQuery.padding.bottom + 5,
          )
        ],
      );
    }

    final screen = Container(
      color: palette.backgroundPlaySession,
      child: screenContents,
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
      child: Focus(
        autofocus: true,
        onKey: _handleKeyPress,
        child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (details) => _onPointerDown(details, context),
          onPointerMove: (details) => _onPointerMove(details, context),
          onPointerHover: (details) => _onPointerHover(details, context),
          onPointerUp: (details) => _onPointerUp(details, context),
          child: WillPopScope(
            onWillPop: () async => !_lockInputs,
            child: screen
          ),
        ),
      ),
    );
  }
}
