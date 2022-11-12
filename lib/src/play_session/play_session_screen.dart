// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:tableturf_mobile/src/audio/sounds.dart';
import 'package:tableturf_mobile/src/games_services/score.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart' hide Level;
import 'package:provider/provider.dart';
import 'package:tableturf_mobile/src/play_session/specialmeter.dart';
import 'package:tableturf_mobile/src/play_session/turncounter.dart';

import '../audio/audio_controller.dart';
import '../game_internals/battle.dart';
import '../game_internals/card.dart';
import '../game_internals/player.dart';
import '../game_internals/tile.dart';
import '../style/palette.dart';

import 'boardwidget.dart';
import 'cardwidget.dart';
import 'moveoverlay.dart';
import 'cardselection.dart';
import 'scorecounter.dart';

double getTileSize(double pixelSize, int tileCount, double edgeWidth) {
  final innerSize = (pixelSize - (edgeWidth * (tileCount + 1))) / tileCount;
  return innerSize + (edgeWidth * 2);
}

class PlaySessionScreen extends StatefulWidget {
  final TableturfPlayer yellow, blue;
  final List<List<TableturfTile>> board;

  const PlaySessionScreen({
    super.key,
    required this.yellow,
    required this.blue,
    required this.board,
  });

  @override
  State<PlaySessionScreen> createState() => _PlaySessionScreenState();
}

class _PlaySessionScreenState extends State<PlaySessionScreen> {
  static final _log = Logger('PlaySessionScreenState');
  late final TableturfBattle battle;

  final GlobalKey _key = GlobalKey(debugLabel: "InputArea");
  double tileSize = 22.0;
  Offset? piecePosition;
  bool _tapTimeExceeded = true, _noPointerMovement = true, _buttonPressed = false;
  Timer? tapTimer;
  final ValueNotifier<Offset?> pointerNotifier = ValueNotifier(null);

  void _updateLocation(PointerEvent details, BuildContext rootContext) {
    if (battle.yellowMoveNotifier.value != null && battle.moveCardNotifier.value != null) {
      return;
    }
    final board = battle.board;
    if (piecePosition != null) {
      piecePosition = piecePosition! + details.localDelta;
    }

    final boardContext = _key.currentContext!;
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
    final boardContext = _key.currentContext!;
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
    if (details.kind == PointerDeviceKind.mouse) {
      piecePosition = details.localPosition;
      _updateLocation(details, context);
    }
  }

  void _onPointerMove(PointerEvent details, BuildContext context) {
    if (_buttonPressed) return;
    _updateLocation(details, context);
  }

  void _onPointerDown(PointerEvent details, BuildContext context) {
    if (_buttonPressed) return;
    print("screen pointer down");
    if (details.kind == PointerDeviceKind.mouse) {
      battle.confirmMove();
    } else {
      _resetPiecePosition(context);
      _tapTimeExceeded = false;
      _noPointerMovement = true;
      tapTimer = Timer(const Duration(milliseconds: 300), () {
        print("tap timer exceeded");
        _tapTimeExceeded = true;
      });
      _updateLocation(details, context);
    }
  }

  void _onPointerUp(PointerEvent details, BuildContext context) {
    if (_buttonPressed) {
      _buttonPressed = false;
    } else {
      print("screen pointer up");
      if (details.kind == PointerDeviceKind.touch) {
        tapTimer?.cancel();
        tapTimer = null;
        if (!_tapTimeExceeded && _noPointerMovement) {
          battle.rotateRight();
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    battle = TableturfBattle(
      yellow: widget.yellow,
      blue: widget.blue,
      board: widget.board
    );
    _playInitSequence();
  }

  Future<void> _playInitSequence() async {
    _startMusic();
    await Future<void>.delayed(const Duration(milliseconds: 1300));
    await _dealHand();
    battle.runBlueAI();
  }

  Future<void> _dealHand() async {
    final yellow = battle.yellow;
    final audioController = AudioController();
    audioController.playSfx(SfxType.dealHand);
    await Future<void>.delayed(const Duration(milliseconds: 800));
    for (var i = 0; i < 4; i++) {
      yellow.hand[i].value = yellow.deck.removeAt(Random().nextInt(yellow.deck.length));
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
  }

  Future<void> _startMusic() async {
    final musicPlayer = AudioController().musicPlayer;
    await musicPlayer.setAudioSource(
      ConcatenatingAudioSource(
        children: [
          AudioSource.uri(Uri.parse("asset:///assets/music/intro_battle.mp3")),
          AudioSource.uri(Uri.parse("asset:///assets/music/loop_battle.mp3")),
        ]
      )
    );
    await musicPlayer.setLoopMode(LoopMode.all);
    musicPlayer.play();
    await Future<void>.delayed(const Duration(seconds: 8));
    await musicPlayer.setLoopMode(LoopMode.one);
  }

  @override
  void dispose() {
    AudioController().musicPlayer.stop();
    super.dispose();
  }

  KeyEventResult _handleKeyPress(FocusNode node, RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.keyQ) {
        battle.rotateLeft();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyE) {
        battle.rotateRight();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();
    final mediaQuery = MediaQuery.of(context);

    final screen = Column(
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
                    ScoreCounter(
                        scoreNotifier: battle.blueCountNotifier,
                        traits: const BlueTraits()
                    ),
                    Container(width: 5),
                    SpecialMeter(player: battle.blue),
                  ],
                ),
                TurnCounter(
                  battle: battle,
                )
              ]
          ),
        ),
        Expanded(
          child: LayoutBuilder(
              builder: (_, constraints) {
                final board = battle.board;
                final boardTileSize = min(
                  min(
                    getTileSize(constraints.maxHeight, board.length, BoardTile.EDGE_WIDTH),
                    (mediaQuery.size.height * 0.8) / board.length,
                  ),
                  min(
                    getTileSize(constraints.maxWidth, board[0].length, BoardTile.EDGE_WIDTH),
                    (mediaQuery.size.width * 0.8) / board[0].length,
                  )
                );

                print("calculated a tile size of ${boardTileSize}px");
                tileSize = boardTileSize;

                return Center(
                  child: SizedBox(
                    key: _key,
                    height: board.length * (boardTileSize - BoardTile.EDGE_WIDTH) + BoardTile.EDGE_WIDTH,
                    width: board[0].length * (boardTileSize - BoardTile.EDGE_WIDTH) + BoardTile.EDGE_WIDTH,
                    child: Stack(
                        children: [
                          BoardWidget(
                            battle,
                            tileSize: boardTileSize,
                          ),
                          MoveOverlayWidget(
                            battle,
                            tileSize: boardTileSize,
                          )
                        ]
                    ),
                  ),
                );
              }
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 15),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ScoreCounter(
                        scoreNotifier: battle.yellowCountNotifier,
                        traits: const YellowTraits()
                    ),
                    Container(width: 5),
                    SpecialMeter(player: battle.yellow),
                  ],
                ),
              ]
          ),
        ),
        Listener(
          onPointerDown: (details) {
            print("ui pointer down");
            _buttonPressed = true;
          },
          onPointerUp: (details) {
            print("ui pointer up");
          },
          child: SizedBox(
            height: 310,
            child: Container(
              padding: EdgeInsets.all(10),
              child: Column(
                children: [
                  AnimatedBuilder(
                    animation: battle.playerControlLock,
                    child: Row(
                      //mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              //physics: NeverScrollableScrollPhysics(),
                              childAspectRatio: (CardWidget.CARD_WIDTH + 20) / (CardWidget.CARD_HEIGHT + 20),
                              children: Iterable.generate(battle.yellow.hand.length, (i) {
                                return Center(
                                  child: CardWidget(
                                    cardNotifier: battle.yellow.hand[i],
                                    battle: battle,
                                  ),
                                );
                              }).toList(growable: false)
                            ),
                          ),
                          Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        if (!battle.playerControlLock.value) {
                                          return;
                                        }
                                        battle.rotateLeft();
                                      },
                                      child: Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                            borderRadius: BorderRadius.all(Radius.circular(999)),
                                            border: Border.all(
                                              color: Colors.black,
                                              width: BoardTile.EDGE_WIDTH,
                                            ),
                                            color: Color.fromRGBO(109, 161, 198, 1)
                                        ),
                                        child: Center(
                                            child: Text("L")
                                        )
                                      )
                                    ),
                                    Container(
                                      width: 10,
                                    ),
                                    GestureDetector(
                                        onTap: () {
                                          if (!battle.playerControlLock.value) {
                                            return;
                                          }
                                          battle.rotateRight();
                                        },
                                        child: Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                                borderRadius: BorderRadius.all(Radius.circular(999)),
                                                border: Border.all(
                                                  color: Colors.black,
                                                  width: BoardTile.EDGE_WIDTH,
                                                ),
                                                color: Color.fromRGBO(109, 161, 198, 1)
                                            ),
                                            child: Center(
                                                child: Text("R")
                                            )
                                        )
                                    ),
                                  ]
                                ),
                                GestureDetector(
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
                                        builder: (_, __) => Container(
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
                                            height: 80,
                                            width: 64,
                                            child: Center(child: Text("Pass"))
                                        )
                                    )
                                ),
                                GestureDetector(
                                    onTap: () {
                                      if (!battle.playerControlLock.value) {
                                        return;
                                      }
                                      battle.moveSpecialNotifier.value = !battle.moveSpecialNotifier.value;
                                      battle.movePassNotifier.value = false;
                                    },
                                    child: AnimatedBuilder(
                                        animation: battle.moveSpecialNotifier,
                                        builder: (_, __) => Container(
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
                                          height: 80,
                                          width: 64,
                                          child: Center(child: Text("Special")),
                                        )
                                    )
                                ),
                                //Container(height: 1)
                              ]
                          ),
                          Container(
                            margin: EdgeInsets.only(left: 15),
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  CardSelectionWidget(
                                    battle: battle,
                                    moveNotifier: battle.blueMoveNotifier,
                                    tileColour: palette.tileBlue,
                                    tileSpecialColour: palette.tileBlueSpecial,
                                  ),
                                  CardSelectionConfirmButton(
                                      battle: battle
                                  )
                                ]
                            ),
                          )
                        ]
                    ),
                    builder: (_, child) => Expanded(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: battle.playerControlLock.value ? 1.0 : 0.5,
                        child: child,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Container(
          height: mediaQuery.padding.bottom + 5,
        )
      ],
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
