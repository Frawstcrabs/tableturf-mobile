// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';

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
import '../game_internals/player.dart';
import '../style/palette.dart';

import 'boardwidget.dart';
import 'cardwidget.dart';
import 'moveoverlay.dart';
import 'cardselection.dart';
import 'scorecounter.dart';

class PlaySessionScreen extends StatefulWidget {
  final TableturfBattle battle;

  const PlaySessionScreen(this.battle, {super.key});

  @override
  State<PlaySessionScreen> createState() => _PlaySessionScreenState();
}

double getTileSize(double pixelSize, int tileCount, double edgeWidth) {
  final innerSize = (pixelSize - (edgeWidth * (tileCount + 1))) / tileCount;
  return innerSize + (edgeWidth * 2);
}

class _PlaySessionScreenState extends State<PlaySessionScreen> {
  static final _log = Logger('PlaySessionScreenState');

  @override
  void initState() {
    super.initState();
    _playInitSequence();
  }

  Future<void> _playInitSequence() async {
    _startMusic();
    await Future<void>.delayed(const Duration(milliseconds: 1300));
    await _dealHand();
    widget.battle.runBlueAI();
  }

  Future<void> _dealHand() async {
    final yellow = widget.battle.yellow;
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
        widget.battle.rotateLeft();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyE) {
        widget.battle.rotateRight();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();
    final mediaQuery = MediaQuery.of(context);
    final audioController = AudioController();
    final battle = widget.battle;

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
              print(constraints);
              final tileSize = min(
                min(
                  getTileSize(constraints.maxHeight, board.length, BoardTile.EDGE_WIDTH),
                  getTileSize(constraints.maxWidth, board[0].length, BoardTile.EDGE_WIDTH),
                ),
                22.0
              );
              print("calculated a tile size of ${tileSize}px");

              return Center(
                child: SizedBox(
                  height: board.length * (tileSize - BoardTile.EDGE_WIDTH) + BoardTile.EDGE_WIDTH,
                  width: board[0].length * (tileSize - BoardTile.EDGE_WIDTH) + BoardTile.EDGE_WIDTH,
                  child: Stack(
                    children: [
                      BoardWidget(
                        battle,
                        tileSize: tileSize,
                      ),
                      MoveOverlayWidget(
                        battle,
                        tileSize: tileSize,
                      )
                    ]
                  ),
                ),
              );
            }
          ),
        ),
        SizedBox(
          height: 310,
          child: Container(
            padding: EdgeInsets.all(10),
            child: Column(
              children: [
                Row(
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
        child: screen,
      ),
    );
  }
}
