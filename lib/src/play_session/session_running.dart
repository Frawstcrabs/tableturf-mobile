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
import 'components/build_board_widget.dart';
import 'components/special_meter.dart';
import 'components/turn_counter.dart';
import 'components/board_widget.dart';
import 'components/card_widget.dart';
import 'components/card_selection.dart';
import 'components/score_counter.dart';

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
  final GlobalKey _blueSelectionKey = GlobalKey(debugLabel: "BlueSelectionWidget");
  final GlobalKey _yellowSelectionKey = GlobalKey(debugLabel: "YellowSelectionWidget");
  final GlobalKey _blueScoreKey = GlobalKey(debugLabel: "BlueScoreWidget");
  final GlobalKey _yellowScoreKey = GlobalKey(debugLabel: "YellowScoreWidget");
  double tileSize = 22.0;
  Offset? piecePosition;
  bool _tapTimeExceeded = true,
      _noPointerMovement = true,
      _buttonPressed = false,
      _lockInputs = true;
  Timer? tapTimer;

  late final AnimationController _outroController, _turnFadeController, _scoreFadeController;
  late final Animation<double> scoreFade, scoreSize, turnFade, turnSize;
  late final Animation<double> outroScale, outroMove;

  @override
  void initState() {
    super.initState();
    widget.battle.endOfGameNotifier.addListener(_onGameEnd);

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
    ).chain(
        CurveTween(curve: Curves.easeOut)
    ).animate(_scoreFadeController);

    _turnFadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this
    );
    turnFade = Tween(
      begin: 0.0,
      end: 1.0,
    ).chain(
      CurveTween(curve: Curves.easeOut)
    ).animate(_turnFadeController);
    turnSize = Tween(
      begin: 1.3,
      end: 1.0,
    ).chain(
      CurveTween(curve: Curves.bounceOut)
    ).animate(_turnFadeController);

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
    _playInitSequence();
  }

  FutureOr<void> _playInitSequence() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    await _dealHand();
    _turnFadeController.forward(from: 0.0);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await _scoreFadeController.forward(from: 0.0);
    setState(() {
      _lockInputs = false;
    });
    widget.battle.runBlueAI();
    //widget.battle.runYellowAI();
  }

  Future<void> _dealHand() async {
    final battle = widget.battle;
    final yellow = battle.yellow;
    final audioController = AudioController();
    audioController.playSfx(SfxType.dealHand);
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
    super.dispose();
  }

  Future<void> _onGameEnd() async {
    _log.info("outro sequence started");
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

    _scoreFadeController.reverse(from: 1.0);
    await _outroController.animateTo(0.5);
    await AudioController().stopSong(
      fadeDuration: const Duration(milliseconds: 1000)
    );
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    await _outroController.forward(from: 0.5);
    animationLayer.remove();
    widget.battle.countBoard();
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
    final boardTileStep = tileSize - BoardTile.EDGE_WIDTH;
    final newX = ((piecePosition!.dx - boardLocation.dx) / boardTileStep).floor();
    final newY = ((piecePosition!.dy - boardLocation.dy) / boardTileStep).floor();
    if (
    newY < 0 ||
        newY >= board.length ||
        newX < 0 ||
        newX >= board[0].length
    ) {
      if (details.kind == PointerDeviceKind.mouse) {
        battle.moveLocationNotifier.value = null;
      }
      // if pointer is touch, let the position remain
    } else {
      final newCoords = Coords(newX, newY);
      if (battle.moveLocationNotifier.value != newCoords) {
        _noPointerMovement = false;
        final audioController = AudioController();
        audioController.playSfx(SfxType.cursorMove);
      }
      battle.moveLocationNotifier.value = newCoords;
    }
  }

  void _resetPiecePosition(BuildContext rootContext) {
    final battle = widget.battle;
    final boardContext = _boardTileKey.currentContext!;
    final boardTileStep = tileSize - BoardTile.EDGE_WIDTH;
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
      battle.confirmMove();
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
    final battle = widget.battle;
    final palette = context.watch<Palette>();
    final mediaQuery = MediaQuery.of(context);

    final boardWidget = buildBoardWidget(
      battle: battle,
      key: _boardTileKey,
      onTileSize: (ts) => tileSize = ts,
      flightIdentifier: "session",
    );

    final turnCounter = AnimatedBuilder(
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
    );
    var blueScore = AnimatedBuilder(
      animation: _scoreFadeController,
      child: ScoreCounter(
          key: _blueScoreKey,
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
    );
    final yellowScore = AnimatedBuilder(
      animation: _scoreFadeController,
      child: ScoreCounter(
        key: _yellowScoreKey,
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
      child: AnimatedBuilder(
        animation: battle.movePassNotifier,
        builder: (_, __) => AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: battle.movePassNotifier.value
                ? palette.buttonSelected
                : palette.buttonUnselected,
            borderRadius: BorderRadius.all(Radius.circular(4)),
            border: Border.all(
              width: BoardTile.EDGE_WIDTH,
              color: Colors.black,
            ),
          ),
          height: mediaQuery.orientation == Orientation.portrait ? CardWidget.CARD_HEIGHT : 30,
          width: mediaQuery.orientation == Orientation.landscape ? CardWidget.CARD_WIDTH : 64,
          child: Center(child: Text("Pass"))
        )
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
      child: AnimatedBuilder(
        animation: battle.moveSpecialNotifier,
        builder: (_, __) => AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: battle.moveSpecialNotifier.value
                ? Color.fromRGBO(216, 216, 0, 1)
                : Color.fromRGBO(109, 161, 198, 1),
            borderRadius: BorderRadius.all(Radius.circular(4)),
            border: Border.all(
              width: BoardTile.EDGE_WIDTH,
              color: Colors.black,
            ),
          ),
          height: mediaQuery.orientation == Orientation.portrait ? CardWidget.CARD_HEIGHT : 30,
          width: mediaQuery.orientation == Orientation.landscape ? CardWidget.CARD_WIDTH : 64,
          child: Center(child: Text("Special")),
        )
      )
    );

    final blueCardSelection = CardSelectionWidget(
      key: _blueSelectionKey,
      battle: battle,
      moveNotifier: battle.blueMoveNotifier,
      tileColour: palette.tileBlue,
      tileSpecialColour: palette.tileBlueSpecial,
    );
    final yellowCardSelection = CardSelectionConfirmButton(
      key: _yellowSelectionKey,
      battle: battle
    );

    late final screenContents;
    if (mediaQuery.orientation == Orientation.portrait) {
      screenContents = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: mediaQuery.padding.top + 10
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    blueScore,
                    Container(width: 5),
                    SpecialMeter(player: battle.blue),
                  ],
                ),
                turnCounter,
              ]
            ),
          ),
          Expanded(
            flex: 3,
            child: boardWidget,
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              children: [
                yellowScore,
                Container(width: 5),
                SpecialMeter(player: battle.yellow),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: blockCursorMovement(
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
                                    children: [passButton, specialButton],
                                  ),
                                ),
                              ],
                            )
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [blueCardSelection, yellowCardSelection]
                        ),
                      )
                    ]
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
                  flex: 3,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 5.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        SpecialMeter(player: battle.blue),
                        Expanded(
                          child: blockCursorMovement(
                            child: fadeOnControlLock(
                              child: Column(
                                children: [
                                  Expanded(
                                      child: handWidget
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [passButton, specialButton],
                                  )
                                ]
                              ),
                            ),
                          ),
                        ),
                        SpecialMeter(player: battle.yellow),
                      ],
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [turnCounter, blueScore, yellowScore],
                ),
                Expanded(
                  flex: 7,
                  child: boardWidget
                ),
                Expanded(
                  flex: 2,
                  child: blockCursorMovement(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [blueCardSelection, yellowCardSelection]
                    ),
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
          child: screen
        ),
      ),
    );
  }
}
