// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:game_template/src/games_services/score.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart' hide Level;
import 'package:provider/provider.dart';

import '../game_internals/battle.dart';
import '../game_internals/player.dart';
import '../style/palette.dart';

import 'boardwidget.dart';
import 'cardwidget.dart';
import 'moveoverlay.dart';
import 'cardselection.dart';
import 'textwidget.dart';
import 'scorecounter.dart';

class PlaySessionScreen extends StatefulWidget {
  final TableturfBattle battle;

  const PlaySessionScreen(this.battle, {super.key});

  @override
  State<PlaySessionScreen> createState() => _PlaySessionScreenState();
}

class _PlaySessionScreenState extends State<PlaySessionScreen> {
  static final _log = Logger('PlaySessionScreenState');

  @override
  void initState() {
    super.initState();
    _playInitSequence();
  }

  Future<void> _playInitSequence() async {
    final yellow = widget.battle.yellow;
    await Future<void>.delayed(const Duration(milliseconds: 1000));
    for (var i = 0; i < 4; i++) {
      yellow.hand[i].value = yellow.deck.removeAt(Random().nextInt(yellow.deck.length));
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    widget.battle.runBlueAI();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();
    final battle = widget.battle;
    final boardState = battle.board;
    final boardTileStep = BoardTile.SIDE_LEN - BoardTile.EDGE_WIDTH;
    final boardHeight = boardState.length * boardTileStep + BoardTile.EDGE_WIDTH;
    final boardWidth = boardState[0].length * boardTileStep + BoardTile.EDGE_WIDTH;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          height: 30
        ),
        const Spacer(),
        SizedBox(
          height: boardHeight,
          width: boardWidth,
          child: Stack(
            children: [
              BoardWidget(
                battle,
              ),
              MoveOverlayWidget(
                battle
              )
            ]
          )
        ),
        /*
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () {
                  int rot = battle.moveRotationNotifier.value;
                  rot -= 1;
                  rot %= 4;
                  battle.moveRotationNotifier.value = rot;
                },
                child: const Text('Rotate Left'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    battle.player1.hand[Random().nextInt(4)] = cards[Random().nextInt(cards.length)];
                  });
                },
                child: const Text('Change Card'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () {
                  var rot = battle.moveRotationNotifier.value;
                  rot += 1;
                  rot %= 4;
                  battle.moveRotationNotifier.value = rot;
                },
                child: const Text('Rotate Right'),
              ),
            ),
          ]
        ),
        */
        const Spacer(),
        SizedBox(
          height: 310,
          child: Container(
            padding: EdgeInsets.all(10),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ScoreCounter(
                      scoreNotifier: battle.blueCountNotifier,
                      traits: const BlueTraits()
                    ),
                    AnimatedBuilder(
                      animation: battle.turnCountNotifier,
                      builder: (_, __) => Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.all(Radius.circular(999)),
                              color: Color.fromRGBO(191, 191, 191, 1)
                          ),
                          child: Scaffold(
                            backgroundColor: Colors.transparent,
                            body: Transform.translate(
                              offset: Offset(-2, -1),
                              child: Center(
                                  child: Text(
                                      battle.turnCountNotifier.value.toString(),
                                      style: TextStyle(
                                          fontFamily: "Splatfont1",
                                          color: battle.turnCountNotifier.value > 3
                                              ? Colors.white
                                              : Colors.red,
                                          fontSize: 20,
                                          letterSpacing: 0.6,
                                          shadows: [
                                            Shadow(
                                              color: Color.fromRGBO(128, 128, 128, 1),
                                              offset: Offset(2, 2),
                                            )
                                          ]
                                      )
                                  )
                              ),
                            ),
                          )
                      ),
                    ),
                    ScoreCounter(
                      scoreNotifier: battle.yellowCountNotifier,
                      traits: const YellowTraits()
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
                                                child: buildTextWidget("L")
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
                                          int rot = battle.moveRotationNotifier.value;
                                          rot += 1;
                                          rot %= 4;
                                          battle.moveRotationNotifier.value = rot;
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
                                                child: buildTextWidget("R")
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
                                          child: Scaffold(
                                            backgroundColor: Colors.transparent,
                                            body: Center(
                                                child: buildTextWidget("Pass")
                                            ),
                                          )
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
                                        child: buildTextWidget("Special"),
                                      )
                                  )
                              ),
                              //Container(height: 1)
                            ]
                        ),
                        //const Spacer(),
                        //SpeenWidget(),
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
        /*
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => GoRouter.of(context).pop(),
              // onPressed: _drawAllMoves,
              child: const Text('Back'),
            ),
          ),
        ),
        */
        Container(
          height: 20,
        )
      ],
    );
  }
}
