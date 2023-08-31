import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:collection/collection.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:tableturf_mobile/src/components/build_board_widget.dart';
import 'package:tableturf_mobile/src/components/tableturf_battle.dart';
import 'package:tableturf_mobile/src/components/tableturf_controller_mixin.dart';
import 'package:tableturf_mobile/src/game_internals/player.dart';

import '../audio/audio_controller.dart';
import '../audio/sounds.dart';
import '../components/card_widget.dart';
import '../components/selection_button.dart';
import '../game_internals/battle.dart';
import '../game_internals/card.dart';
import '../game_internals/move.dart';
import '../game_internals/tile.dart';
import '../style/constants.dart';

class BoardOperation {
  final Map<Coords, (TileState, TileState)> boardDiff;
  final Set<Coords> activatedSpecials;
  final TableturfCard? card;

  const BoardOperation({
    required this.boardDiff,
    required this.activatedSpecials,
    required this.card,
  });
}

class TestingTableturfBattle implements TableturfBattleModel {
  final List<TableturfCard> playerDeck;
  TileGrid board;
  final TileGrid origBoard;
  final List<BoardOperation> moveStack = [];
  int moveStackPtr = 0;
  Set<Coords> activatedSpecials = Set();

  final StreamController<BattleEvent> streamController = StreamController();
  Stream<BattleEvent> get eventStream => streamController.stream;

  TestingTableturfBattle({
    required this.playerDeck,
    required this.board,
  }): origBoard = board.copy() {
    moveStack.add(BoardOperation(
      boardDiff: {},
      activatedSpecials: Set(),
      card: null,
    ));
  }

  @override
  bool checkMoveValidity(TileGrid board, TableturfMove move) {
    return checkMoveIsValid(board, move);
  }

  @override
  void setPlayerMove(PlayerID playerID, TableturfMove move) async {
    move.card.hasBeenPlayed = true;
    move.card.isPlayable = false;

    final List<BattleEvent> events = [];
    final moveChanges = move.boardChanges;
    events.add(BoardTilesUpdate(moveChanges, BoardTileUpdateType.normal));
    final boardDiff = Map.fromEntries(moveChanges.entries.map((entry) {
      final coords = entry.key;
      final before = board[coords.y][coords.x];
      final after = entry.value;
      return MapEntry(coords, (before, after));
    }));
    for (final MapEntry(key: coords, value: state) in moveChanges.entries) {
      board[coords.y][coords.x] = state;
    }

    final specialEvent = countSpecial();
    if (specialEvent != null) {
      activatedSpecials = specialEvent.updates;
      events.add(specialEvent);
    }
    if (moveStackPtr < moveStack.length - 1) {
      // operations were undone, have to clear them to
      // add this to the stack or the order will get fucked
      moveStack.removeRange(moveStackPtr + 1, moveStack.length);
    }
    moveStack.add(BoardOperation(
      boardDiff: boardDiff,
      activatedSpecials: Set.of(activatedSpecials),
      card: move.card,
    ));
    moveStackPtr += 1;
    streamController.add(Turn({}, events));
  }

  BoardSpecialUpdate? countSpecial() {
    final activatedCoordsSet = Set<Coords>();
    for (var y = 0; y < board.length; y++) {
      for (var x = 0; x < board[0].length; x++) {
        final boardTile = board[y][x];
        if (boardTile.isSpecial) {
          bool surrounded = true;
          for (var dy = -1; dy <= 1; dy++) {
            for (var dx = -1; dx <= 1; dx++) {
              final newY = y + dy;
              final newX = x + dx;
              if (newY < 0 || newY >= board.length || newX < 0 ||
                  newX >= board[0].length) {
                continue;
              }
              final adjacentTile = board[newY][newX];
              if (!adjacentTile.isFilled) {
                surrounded = false;
                continue;
              }
            }
          }
          if (surrounded) {
            activatedCoordsSet.add(Coords(x, y));
          }
        }
      }
    }
    if (!const SetEquality<Coords>().equals(activatedCoordsSet, activatedSpecials)) {
      return BoardSpecialUpdate(activatedCoordsSet);
    }
    return null;
  }

  void undoMove() {
    if (moveStackPtr == 0) {
      // already at bottom of stack
      return;
    }
    final currentState = moveStack[moveStackPtr];
    currentState.card?.isPlayable = true;
    currentState.card?.hasBeenPlayed = false;
    moveStackPtr -= 1;
    final boardDiff = currentState.boardDiff;
    final boardChanges = Map.fromEntries(boardDiff.entries.map((entry) {
      return MapEntry(entry.key, entry.value.$1);
    }));
    for (final MapEntry(key: coords, value: state) in boardChanges.entries) {
      board[coords.y][coords.x] = state;
    }
    final activatedSpecials = moveStack[moveStackPtr].activatedSpecials;
    streamController.add(BoardTilesUpdate(boardChanges, BoardTileUpdateType.silent));
    streamController.add(BoardSpecialUpdate(activatedSpecials));
  }

  void redoMove() {
    if (moveStackPtr == moveStack.length - 1) {
      // already at top of stack
      return;
    }
    moveStackPtr += 1;
    final nextState = moveStack[moveStackPtr];
    final boardDiff = nextState.boardDiff;
    final boardChanges = Map.fromEntries(boardDiff.entries.map((entry) {
      return MapEntry(entry.key, entry.value.$2);
    }));
    for (final MapEntry(key: coords, value: state) in boardChanges.entries) {
      board[coords.y][coords.x] = state;
    }
    nextState.card?.isPlayable = false;
    nextState.card?.hasBeenPlayed = true;
    streamController.add(BoardTilesUpdate(boardChanges, BoardTileUpdateType.silent));
    streamController.add(BoardSpecialUpdate(nextState.activatedSpecials));
  }

  void reset() {
    activatedSpecials = Set();
    final Map<Coords, TileState> boardChanges = {};
    for (final move in moveStack.reversed) {
      for (final MapEntry(key: coords, value: (before, _)) in move.boardDiff.entries) {
        boardChanges[coords] = before;
      }
      move.card?.hasBeenPlayed = false;
      move.card?.isPlayable = true;
    }
    moveStack.clear();
    moveStack.add(BoardOperation(
      boardDiff: {},
      activatedSpecials: Set(),
      card: null,
    ));
    moveStackPtr = 0;
    for (final MapEntry(key: coords, value: state) in boardChanges.entries) {
      board[coords.y][coords.x] = state;
    }
    streamController.add(BoardTilesUpdate(boardChanges, BoardTileUpdateType.silent));
    streamController.add(BoardSpecialUpdate(activatedSpecials));
  }
}

class TestAreaScreen extends StatefulWidget {
  final List<TableturfCardData> deck;
  final TileGrid board;
  const TestAreaScreen({
    super.key,
    required this.board,
    required this.deck,
  });

  @override
  State<TestAreaScreen> createState() => _TestAreaScreenState();
}

class _TestAreaScreenState extends State<TestAreaScreen>
    with SingleTickerProviderStateMixin, TableturfBattleMixin {
  final GlobalKey inputAreaKey = GlobalKey(debugLabel: "InputArea");
  bool lockInputs = false;
  late final TestingTableturfBattle battle;
  late final TableturfBattleController controller;
  final GlobalKey _screenKey = GlobalKey(debugLabel: "ScreenView");

  double tileSize = 22.0;
  Offset? piecePosition;
  PointerDeviceKind? pointerKind;

  late final AnimationController screenWipeController;
  final ValueNotifier<ui.Image?> screenImageNotifier = ValueNotifier(null);

  final StreamController<BattleEvent> eventBroadcast = StreamController.broadcast();

  @override
  void initState() {
    super.initState();

    final playerDeck = widget.deck.map((card) {
      return TableturfCard(card)
        ..isPlayable = true;
    }).toList();

    battle = TestingTableturfBattle(
      playerDeck: playerDeck,
      board: widget.board.copy(),
    );
    controller = TableturfBattleController(
      board: widget.board.copy(),
      player: TableturfPlayer(
        id: 0,
        name: "Test",
        traits: const YellowTraits(),
      ),
      playerDeck: playerDeck,
      model: battle,
    );
    controller.playerHand.clear();
    controller.playerControlIsLocked.value = false;

    screenWipeController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    _monitorBattleEvents();
  }

  Future<void> _monitorBattleEvents() async {
    final audioController = AudioController();
    await for (final event in battle.eventStream) {
      switch (event) {
        case Turn(:final events):
          eventBroadcast.add(const TurnStart({}));
          for (final turnEvent in events) {
            switch (turnEvent) {
              case BoardTilesUpdate():
                audioController.playSfx(SfxType.normalMove);
              case BoardSpecialUpdate(:final updates):
                controller.activatedSpecials.value = updates;
                audioController.playSfx(SfxType.specialActivate);
            }
            eventBroadcast.add(turnEvent);
            await Future.delayed(turnEvent.duration ~/ 2);
          }
          controller.reset();
          eventBroadcast.add(const TurnEnd());
        default:
          eventBroadcast.add(event);
      }
    }
  }

  @override
  void dispose() {
    screenWipeController.dispose();
    battle.streamController.close();
    eventBroadcast.close();
    super.dispose();
  }

  void _undoMove() {
    battle.undoMove();
    controller.moveCardNotifier.value = null;
    // in case the values were already set to this
    controller.moveCardNotifier.notifyListeners();
  }

  void _redoMove() {
    battle.redoMove();
    controller.moveCardNotifier.value = null;
    // in case the values were already set to this
    controller.moveCardNotifier.notifyListeners();
  }

  Future<void> _resetBoard() async {
    final audioController = AudioController();
    final boundary = _screenKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(
      pixelRatio: MediaQuery.of(context).devicePixelRatio,
    );
    controller.playerControlIsLocked.value = true;
    screenImageNotifier.value = image;
    audioController.playSfx(SfxType.screenWipe);
    screenWipeController.forward(from: 0.0).then((_) async {
      screenImageNotifier.value = null;
      controller.playerControlIsLocked.value = false;
    });
    controller.reset();
    battle.reset();
    controller.moveCardNotifier.notifyListeners();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screen = Column(
      children: [
        Expanded(
          flex: 3,
          child: Center(
            child: Text(
              "Test Deck",
              style: TextStyle(
                fontFamily: "Splatfont1",
                color: Colors.white,
              ),
            ),
          ),
        ),
        divider,
        Expanded(
          flex: 27,
          child: Center(
            child: FractionallySizedBox(
              heightFactor: 0.9,
              child: buildBoardWidget(
                key: inputAreaKey,
                controller: controller,
                onTileSize: (ts) => tileSize = ts,
                loopAnimation: true,
                boardHeroTag: "board",
              ),
            ),
          ),
        ),
        divider,
        Expanded(
          flex: 6,
          child: Center(
            child: ListView(
              scrollDirection: Axis.horizontal,
              prototypeItem: AspectRatio(aspectRatio: CardWidget.CARD_RATIO),
              children: [
                for (final card in battle.playerDeck)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5.0),
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: CardWidget.CARD_RATIO,
                        child: SelectableCard(card: card),
                      ),
                    ),
                  )
              ],
            ),
          ),
        ),
        divider,
        Expanded(
          flex: 3,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: SelectionButton(
                    child: Text(
                      "Reset",
                      style: TextStyle(fontSize: 16),
                    ),
                    designRatio: 0.5,
                    onPressStart: () async {
                      if (lockInputs) {
                        return false;
                      }
                      return true;
                    },
                    onPressEnd: () async {
                      await _resetBoard();
                    },
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _undoMove,
                  child: Center(
                    child: Transform.flip(
                      flipX: true,
                      child: Icon(
                        Icons.refresh,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _redoMove,
                  child: Center(
                    child: Icon(
                      Icons.refresh,
                      color: Colors.white54,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: SelectionButton(
                    child: Text(
                      "Exit",
                      style: TextStyle(fontSize: 16),
                    ),
                    designRatio: 0.5,
                    onPressStart: () async {
                      if (lockInputs) {
                        return false;
                      }
                      lockInputs = true;
                      return true;
                    },
                    onPressEnd: () async {
                      Navigator.of(context).pop();
                      return Future<void>.delayed(const Duration(milliseconds: 100));
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          key: _screenKey,
          child: Scaffold(
            backgroundColor: Palette.backgroundDeckTester,
            body: DefaultTextStyle(
              style: TextStyle(
                fontFamily: "Splatfont2",
                color: Colors.white,
                fontSize: 18,
                letterSpacing: 0.6,
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
                    child: Padding(
                      padding: mediaQuery.padding,
                      child: TableturfBattle(
                        controller: controller,
                        eventStream: eventBroadcast.stream,
                        child: screen,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        RepaintBoundary(
          child: IgnorePointer(
            child: CustomPaint(
              painter: ScreenWipePainter(
                screenImage: screenImageNotifier,
                animation: screenWipeController,
              ),
              child: SizedBox.expand(),
            ),
          ),
        )
      ],
    );
  }
}

class ScreenWipePainter extends CustomPainter {
  final ValueNotifier<ui.Image?> screenImage;
  final Animation<double> animation;

  ScreenWipePainter({
    required this.screenImage,
    required this.animation,
  }): super(repaint: Listenable.merge([screenImage, animation]));

  @override
  void paint(Canvas canvas, Size size) {
    final image = screenImage.value;
    if (image == null || animation.value == 1.0) {
      return;
    }
    const startPoint = 0.05;
    const endPoint = 0.95;
    const angle = pi * 0.25;
    final width = size.width / 15;
    // final angle = atan(size.height / size.width)
    final animValue = ((animation.value - startPoint) / (endPoint - startPoint)).clamp(0, 1);
    final pathWidth = size.height * tan(angle);
    var sweepPath = Path();
    sweepPath.moveTo(0, 0);
    sweepPath.relativeLineTo(-width, 0);
    sweepPath.relativeLineTo(-pathWidth, size.height);
    sweepPath.relativeLineTo(width, 0);
    sweepPath.close();
    sweepPath = sweepPath.shift(Offset((size.width + pathWidth + width) * animValue, 0));
    var clipPath = Path();
    clipPath.moveTo(-width / 2, 0);
    clipPath.relativeLineTo(-pathWidth, size.height);
    clipPath.lineTo(size.width, size.height);
    clipPath.lineTo(size.width, 0);
    clipPath.close();
    clipPath = clipPath.shift(Offset((size.width + pathWidth + width) * animValue, 0));

    canvas.save();
    canvas.clipPath(clipPath, doAntiAlias: false);
    paintImage(
      canvas: canvas,
      rect: Offset.zero & size,
      image: image,
    );
    canvas.restore();
    canvas.drawPath(sweepPath, Paint()..color = Palette.tileYellow);
  }

  @override
  bool shouldRepaint(ScreenWipePainter other) {
    return screenImage != other.screenImage
        || animation != other.animation;
  }
}

class SelectableCard extends StatefulWidget {
  const SelectableCard({
    super.key,
    required this.card,
  });

  final TableturfCard card;

  @override
  State<SelectableCard> createState() => _SelectableCardState();
}

class _SelectableCardState extends State<SelectableCard> {
  late final TableturfBattleController controller;

  @override
  void initState() {
    super.initState();
    controller = TableturfBattle.getControllerOf(context);
  }
  Widget _buildButton(BuildContext context) {
    return Transform.scale(
      scale: 1.05,  // account for the stretch cards do when selected
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Palette.inGameButtonSelected,
          border: Border.all(
            width: 1.0,
            color: Palette.cardEdge,
          ),
        ),
        child: Center(
          child: FractionallySizedBox(
            widthFactor: 0.9,
            child: FittedBox(
              fit: BoxFit.fitWidth,
              child: Text(
                "Confirm",
                style: TextStyle(
                  shadows: [
                    Shadow(
                      color: const Color.fromRGBO(256, 256, 256, 0.4),
                      offset: Offset(1, 1),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: [
        CardWidget(
          cardNotifier: ValueNotifier(widget.card),
        ),
        ValueListenableBuilder(
          valueListenable: controller.moveCardNotifier,
          builder: (_, selectedCard, ___) {
            if (selectedCard != widget.card) {
              return Container();
            }
            return GestureDetector(
              onTap: () {
                controller.confirmMove();
              },
              child: ValueListenableBuilder(
                valueListenable: controller.playerControlIsLocked,
                child: ValueListenableBuilder(
                  valueListenable: controller.moveIsValidNotifier,
                  builder: (_, highlighted, button) => AnimatedOpacity(
                    opacity: highlighted ? 1 : 0,
                    duration: const Duration(milliseconds: 150),
                    child: _buildButton(context),
                  ),
                ),
                builder: (context, isLocked, child) {
                  if (isLocked) {
                    return Container();
                  }
                  return child!;
                },
              ),
            );
          }
        ),
      ],
    );
  }
}
