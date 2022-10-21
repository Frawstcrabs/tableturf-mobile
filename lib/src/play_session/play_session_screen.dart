// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart' hide Level;
import 'package:provider/provider.dart';

import '../ads/ads_controller.dart';
import '../audio/audio_controller.dart';
import '../audio/sounds.dart';
import '../game_internals/level_state.dart';
import '../games_services/games_services.dart';
import '../games_services/score.dart';
import '../in_app_purchase/in_app_purchase.dart';
import '../level_selection/levels.dart';
import '../player_progress/player_progress.dart';
import '../style/confetti.dart';
import '../style/palette.dart';
import '../game_internals/cards.dart';

class PlaySessionScreen extends StatefulWidget {
  final GameLevel level;

  const PlaySessionScreen(this.level, {super.key});

  @override
  State<PlaySessionScreen> createState() => _PlaySessionScreenState();
}

class _PlaySessionScreenState extends State<PlaySessionScreen> {
  static final _log = Logger('PlaySessionScreen');

  static const _celebrationDuration = Duration(milliseconds: 2000);

  static const _preCelebrationDuration = Duration(milliseconds: 500);

  bool _duringCelebration = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();

    List<List<TileState>> boardState = [
      [TileState.Empty, TileState.Empty, TileState.Empty, TileState.Empty, TileState.Empty, TileState.Empty, TileState.Empty, TileState.Empty, TileState.Unfilled, TileState.Empty, TileState.Empty, TileState.Empty, TileState.Empty, TileState.Empty, TileState.Empty, TileState.Empty, TileState.Empty],
      [TileState.Empty, TileState.Empty, TileState.Empty, TileState.Empty, TileState.Empty, TileState.Empty, TileState.Empty, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Empty, TileState.Empty, TileState.Empty, TileState.Empty, TileState.Empty, TileState.Empty, TileState.Empty],
      [TileState.Empty, TileState.Empty, TileState.Empty, TileState.Empty, TileState.Empty, TileState.Empty, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Empty, TileState.Empty, TileState.Empty, TileState.Empty, TileState.Empty, TileState.Empty],
      [TileState.Empty, TileState.Empty, TileState.Empty, TileState.Empty, TileState.Empty, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Empty, TileState.Empty, TileState.Empty, TileState.Empty, TileState.Empty],
      [TileState.Empty, TileState.Empty, TileState.Empty, TileState.Empty, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Empty, TileState.Empty, TileState.Empty, TileState.Empty],
      [TileState.Empty, TileState.Empty, TileState.Empty, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.BlueSpecial, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Empty, TileState.Empty, TileState.Empty],
      [TileState.Empty, TileState.Empty, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Empty, TileState.Empty],
      [TileState.Empty, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Empty],
      [TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled],
      [TileState.Empty, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Empty],
      [TileState.Empty, TileState.Empty, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Empty, TileState.Empty],
      [TileState.Empty, TileState.Empty, TileState.Empty, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Empty, TileState.Empty, TileState.Empty],
      [TileState.Empty, TileState.Empty, TileState.Empty, TileState.Empty, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Empty, TileState.Empty, TileState.Empty, TileState.Empty],
      [TileState.Empty, TileState.Empty, TileState.Empty, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Empty, TileState.Empty, TileState.Empty],
      [TileState.Empty, TileState.Empty, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Empty, TileState.Empty],
      [TileState.Empty, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Empty],
      [TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled],
      [TileState.Empty, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Empty],
      [TileState.Empty, TileState.Empty, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Empty, TileState.Empty],
      [TileState.Empty, TileState.Empty, TileState.Empty, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.YellowSpecial, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Empty, TileState.Empty, TileState.Empty],
      [TileState.Empty, TileState.Empty, TileState.Empty, TileState.Empty, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Empty, TileState.Empty, TileState.Empty, TileState.Empty],
      [TileState.Empty, TileState.Empty, TileState.Empty, TileState.Empty, TileState.Empty, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Empty, TileState.Empty, TileState.Empty, TileState.Empty, TileState.Empty],
      [TileState.Empty, TileState.Empty, TileState.Empty, TileState.Empty, TileState.Empty, TileState.Empty, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Empty, TileState.Empty, TileState.Empty, TileState.Empty, TileState.Empty, TileState.Empty],
      [TileState.Empty, TileState.Empty, TileState.Empty, TileState.Empty, TileState.Empty, TileState.Empty, TileState.Empty, TileState.Unfilled, TileState.Unfilled, TileState.Unfilled, TileState.Empty, TileState.Empty, TileState.Empty, TileState.Empty, TileState.Empty, TileState.Empty, TileState.Empty],
      [TileState.Empty, TileState.Empty, TileState.Empty, TileState.Empty, TileState.Empty, TileState.Empty, TileState.Empty, TileState.Empty, TileState.Unfilled, TileState.Empty, TileState.Empty, TileState.Empty, TileState.Empty, TileState.Empty, TileState.Empty, TileState.Empty, TileState.Empty],
    ];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        SizedBox(
          height: boardState.length * (BoardTile.SIDE_LEN - 0.5),
          width: boardState[0].length * (BoardTile.SIDE_LEN - 0.5),
          child: Stack(
            children: boardState.asMap().entries.expand((entry) {
              int y = entry.key;
              var row = entry.value;
              return row.asMap().entries.map((entry) {
                int x = entry.key;
                var tile = entry.value;
                return Positioned(
                  top: y * (BoardTile.SIDE_LEN - 0.5),
                  left: x * (BoardTile.SIDE_LEN - 0.5),
                  child: BoardTile(tile)
                );
              }).toList(growable: false);
            }).toList(growable: false)
          ),
        ),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            CardWidget(cards[0]),
            CardWidget(cards[1]),
            CardWidget(cards[2]),
            CardWidget(cards[3]),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => GoRouter.of(context).pop(),
              child: const Text('Back'),
            ),
          ),
        ),
      ],
    );
  }
}

class BoardTile extends StatelessWidget {
  static const SIDE_LEN = 21.0;
  final TileState state;

  const BoardTile(this.state, {super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();
    return Container(
      decoration: BoxDecoration(
        color: state == TileState.Unfilled ? palette.tileUnfilled
               : state == TileState.Wall ? palette.tileWall
               : state == TileState.Yellow ? palette.tileYellow
               : state == TileState.YellowSpecial ? palette.tileYellowSpecial
               : state == TileState.Blue ? palette.tileBlue
               : state == TileState.BlueSpecial ? palette.tileBlueSpecial
               : Color.fromRGBO(0, 0, 0, 0),
        border: Border.all(
          width: 0.5,
          color: state == TileState.Empty
                 ? Color.fromRGBO(0, 0, 0, 0)
                 : palette.tileEdge
        ),
      ),
      width: SIDE_LEN,
      height: SIDE_LEN,
    );
  }
}

class CardWidget extends StatelessWidget {
  final TableturfCard card;
  static const LAYOUT_TILE_SIZE = 8.0;

  const CardWidget(this.card, {super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();
    var cardWidget = Container(
      decoration: BoxDecoration(
        color: palette.cardBackground,
        border: Border.all(
          width: 1.0,
          color: palette.cardEdge,
        ),
      ),
      width: 80,
      height: 110,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          SizedBox(
            height: card.pattern.length * (CardWidget.LAYOUT_TILE_SIZE - 0.5),
            width: card.pattern[0].length * (CardWidget.LAYOUT_TILE_SIZE - 0.5),
            child: Stack(
              children: card.pattern.asMap().entries.expand((entry) {
                int y = entry.key;
                var row = entry.value;
                return row.asMap().entries.map((entry) {
                  int x = entry.key;
                  var tile = entry.value;
                  return Positioned(
                      top: y * (CardWidget.LAYOUT_TILE_SIZE - 0.5),
                      left: x * (CardWidget.LAYOUT_TILE_SIZE - 0.5),
                      child: Container(
                        decoration: BoxDecoration(
                          color: tile == TileState.Unfilled ? palette.cardTileUnfilled
                              : tile == TileState.Yellow ? palette.tileYellow
                              : tile == TileState.YellowSpecial ? palette.tileYellowSpecial
                              : Color.fromRGBO(0, 0, 0, 0),
                          border: Border.all(
                            width: 0.5,
                            color: palette.cardTileEdge,
                          ),
                        ),
                        width: CardWidget.LAYOUT_TILE_SIZE,
                        height: CardWidget.LAYOUT_TILE_SIZE,
                      )
                  );
                }).toList(growable: false);
              }).toList(growable: false)
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Material(
                color: Colors.transparent,
                child: Container(
                  height: 24,
                  width: 24,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                  ),
                  child: Center(
                    child: Text(
                      card.count.toString(),
                      style: TextStyle(
                        fontFamily: "Splatfont2",
                        color: Colors.white,
                        //fontStyle: FontStyle.italic,
                        fontSize: 12
                      )
                    )
                  )
                ),
              ),
              Row(
                children: Iterable<int>.generate(card.special).map((_) {
                  return Container(
                    decoration: BoxDecoration(
                      color: palette.tileYellowSpecial,
                      border: Border.all(
                        width: 0.5,
                        color: Colors.black,
                      ),
                    ),
                    width: CardWidget.LAYOUT_TILE_SIZE,
                    height: CardWidget.LAYOUT_TILE_SIZE,
                  );
                }).toList(growable: false)
              )
            ],
          ),
        ],
      )
    );
    return Draggable(
      data: card,
      maxSimultaneousDrags: 1,
      child: cardWidget,
      feedback: Transform.scale(
        scale: 0.85,
        child: cardWidget,
      ),
      childWhenDragging: Stack(
        children: [
          cardWidget,
          Container(
            width: 80,
            height: 110,
            decoration: BoxDecoration(
              color: Color.fromRGBO(0, 0, 0, 0.4)
            ),
          )
        ]
      ),
    );
  }
}

/*
class MyHomePage extends StatefulWidget {
  MyHomePage({super.key});
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  MyDraggableController<String> draggableController = MyDraggableController<String>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Draggable Test'),
      ),
      body: Column(
        children: <Widget>[
          Container(
            height: 400,
            width: double.infinity,
            child: Container(
              width: 100,
              height: 100,
              child: Center(
                child: Stack(
                  children: <Widget>[
                    Positioned(
                      left: 30,
                      top: 30,
                      child: MyDraggable<String>(
                        draggableController,
                        'Test1',
                      ),
                    ),
                    Positioned(
                      left: 230,
                      top: 230,
                      child: MyDraggable<String>(
                        draggableController,
                        'Test2',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          DragTarget<String>(
            builder: (context, list, list2) {
              return Container(
                height: 100,
                width: double.infinity,
                color: Colors.blueGrey,
                child: Center(
                  child: Text('TARGET ZONE'),
                ),
              );
            },
            onWillAccept: (item) {
              debugPrint('draggable is on the target $item');
              this.draggableController.onTarget(true, item);
              return true;
            },
            onLeave: (item) {
              debugPrint('draggable has left the target $item');
              this.draggableController.onTarget(false, item);
            },
          ),
        ],
      ),
    );
  }
}

class MyDraggable<T> extends StatefulWidget {
  final MyDraggableController<T> controller;
  final T data;
  MyDraggable(this.controller, this.data, {super.key});
  @override
  _MyDraggableState createState() =>
      _MyDraggableState<T>(this.controller, this.data);
}

class _MyDraggableState<T> extends State<MyDraggable> {
  MyDraggableController<T> controller;
  T data;
  bool isOnTarget = false;
  _MyDraggableState(this.controller, this.data);
  FeedbackController? feedbackController;
  @override
  void initState() {
    feedbackController = FeedbackController();

    this.controller.subscribeToOnTargetCallback(onTargetCallbackHandler);

    super.initState();
  }

  void onTargetCallbackHandler(bool t, T? data) {
    this.isOnTarget = t && data != null && data == this.data;
    this.feedbackController?.updateFeedback(this.isOnTarget);
  }

  @override
  void dispose() {
    this.controller.unSubscribeFromOnTargetCallback(onTargetCallbackHandler);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Draggable<T>(
      data: this.data,
      feedback: FeedbackWidget(feedbackController),
      childWhenDragging: Container(
        height: 100,
        width: 100,
        color: Colors.blue[50],
      ),
      child: Container(
        height: 100,
        width: 100,
        color: (this.isOnTarget ?? false) ? Colors.green : Colors.blue,
      ),
      onDraggableCanceled: (v, f) => setState(
            () {
          this.isOnTarget = false;
          this.feedbackController?.updateFeedback(this.isOnTarget);
        },
      ),
    );
  }
}

class FeedbackController {
  Function(bool)? feedbackNeedsUpdateCallback;

  void updateFeedback(bool isOnTarget) {
    feedbackNeedsUpdateCallback?.call(isOnTarget);
  }
}

class FeedbackWidget extends StatefulWidget {
  final FeedbackController? controller;
  FeedbackWidget(this.controller);
  @override
  _FeedbackWidgetState createState() => _FeedbackWidgetState();
}

class _FeedbackWidgetState extends State<FeedbackWidget> {
  bool? isOnTarget;

  @override
  void initState() {
    this.isOnTarget = false;
    this.widget.controller?.feedbackNeedsUpdateCallback = feedbackNeedsUpdateCallbackHandler;
    super.initState();
  }

  void feedbackNeedsUpdateCallbackHandler(bool t) {
    setState(() {
      this.isOnTarget = t;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      width: 100,
      color: this.isOnTarget ?? false ? Colors.green : Colors.red,
    );
  }

  @override
  void dispose() {
    this.widget.controller?.feedbackNeedsUpdateCallback = null;
    super.dispose();
  }
}

class DraggableInfo<T> {
  bool isOnTarget;
  T data;
  DraggableInfo(this.isOnTarget, this.data);
}

class MyDraggableController<T> {
  List<Function(bool, T?)> _targetUpdateCallbacks = [];

  MyDraggableController();

  void onTarget(bool onTarget, T? data) {
    _targetUpdateCallbacks.forEach((f) => f(onTarget, data));
  }

  void subscribeToOnTargetCallback(Function(bool, T?) f) {
    _targetUpdateCallbacks.add(f);
  }

  void unSubscribeFromOnTargetCallback(Function(bool, T?) f) {
    _targetUpdateCallbacks.remove(f);
  }
}
*/