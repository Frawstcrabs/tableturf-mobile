import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:tableturf_mobile/src/components/build_board_widget.dart';
import 'package:tableturf_mobile/src/game_internals/opponentAI.dart';
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
  final TileGrid board;
  final Set<Coords> activatedSpecials;
  final TableturfCard? card;

  const BoardOperation({
    required this.board,
    required this.activatedSpecials,
    required this.card,
  });
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
    with SingleTickerProviderStateMixin {
  final GlobalKey _boardTileKey = GlobalKey(debugLabel: "InputArea");
  final GlobalKey _screenKey = GlobalKey(debugLabel: "ScreenView");
  final List<BoardOperation> moveStack = [];
  int moveStackPtr = 0;
  late final TableturfBattle battle;

  bool _lockInputs = false;
  double tileSize = 22.0;
  Offset? piecePosition;
  PointerDeviceKind? pointerKind;

  late final AnimationController screenWipeController;
  final ValueNotifier<ui.Image?> screenImageNotifier = ValueNotifier(null);

  void _updateLocation(
      Offset delta,
      PointerDeviceKind? pointerKind,
      BuildContext rootContext,
      ) {
    if (battle.yellowMoveNotifier.value != null &&
        battle.moveCardNotifier.value != null) {
      return;
    }
    final board = battle.board;
    if (piecePosition != null) {
      piecePosition = piecePosition! + delta;
    }

    final boardContext = _boardTileKey.currentContext!;
    // find the coordinates of the board within the input area
    final boardLocation = (boardContext.findRenderObject()! as RenderBox)
        .localToGlobal(Offset.zero, ancestor: rootContext.findRenderObject());
    final boardTileStep = tileSize;
    final newX =
    ((piecePosition!.dx - boardLocation.dx) / boardTileStep).floor();
    final newY =
    ((piecePosition!.dy - boardLocation.dy) / boardTileStep).floor();
    final newCoords = Coords(
      newX.clamp(0, board[0].length - 1),
      newY.clamp(0, board.length - 1),
    );
    if ((newY < 0 ||
        newY >= board.length ||
        newX < 0 ||
        newX >= board[0].length) &&
        pointerKind == PointerDeviceKind.mouse) {
      battle.moveLocationNotifier.value = null;
      // if pointer is touch, let the position remain
    } else if (battle.moveLocationNotifier.value != newCoords) {
      final audioController = AudioController();
      if (battle.moveCardNotifier.value != null &&
          !battle.movePassNotifier.value) {
        audioController.playSfx(SfxType.cursorMove);
      }
      battle.moveLocationNotifier.value = newCoords;
    }
  }

  void _resetPiecePosition(BuildContext rootContext) {
    final boardContext = _boardTileKey.currentContext!;
    final boardTileStep = tileSize;
    final boardLocation =
    (boardContext.findRenderObject()! as RenderBox).localToGlobal(
      Offset.zero,
      ancestor: rootContext.findRenderObject(),
    );
    if (battle.moveLocationNotifier.value == null) {
      battle.moveLocationNotifier.value = Coords(
        battle.board[0].length ~/ 2,
        battle.board.length ~/ 2,
      );
    }
    final pieceLocation = battle.moveLocationNotifier.value!;
    piecePosition = Offset(
      boardLocation.dx +
          (pieceLocation.x * boardTileStep) +
          (boardTileStep / 2),
      boardLocation.dy +
          (pieceLocation.y * boardTileStep) +
          (boardTileStep / 2),
    );
  }

  void _onHover(PointerHoverEvent details) {
    if (_lockInputs) return;

    if (details.kind == PointerDeviceKind.mouse) {
      piecePosition = details.localPosition;
      pointerKind = details.kind;
      _updateLocation(details.delta, details.kind, context);
    }
  }

  void _onDragUpdate(DragUpdateDetails details, BuildContext context) {
    if (_lockInputs) return;
    _updateLocation(details.delta, pointerKind, context);
  }

  void _onDragStart(DragStartDetails details, BuildContext context) {
    if (_lockInputs) return;

    _resetPiecePosition(context);
    pointerKind = details.kind;
    _updateLocation(Offset.zero, pointerKind, context);
  }

  void _onTap() {
    if (battle.playerControlLock.value) {
      if (pointerKind == PointerDeviceKind.mouse) {
        battle.confirmMove();
      } else {
        battle.rotateRight();
      }
    }
  }

  KeyEventResult _handleKeyPress(FocusNode node, RawKeyEvent event) {
    if (_lockInputs) return KeyEventResult.ignored;

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
  void initState() {
    super.initState();
    battle = TableturfBattle(
      yellow: TableturfPlayer(
        name: "Yellow",
        deck: widget.deck.map((card) {
          return TableturfCard(card)..isPlayable = true;
        }).toList(),
        hand: [],  // isnt used
        traits: const YellowTraits(),
      ),
      blue: TableturfPlayer(  // isnt used
        name: "Blue",
        deck: [],
        hand: [],
        traits: const BlueTraits(),
      ),
      board: widget.board.copy(),
      aiLevel: AILevel.level1,
    );
    battle.yellowMoveNotifier.addListener(_playMove);

    moveStack.add(BoardOperation(
      board: battle.board.copy(),
      activatedSpecials: Set(),
      card: null,
    ));

    screenWipeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    battle.yellowMoveNotifier.removeListener(_playMove);
    battle.dispose();
    screenWipeController.dispose();
    super.dispose();
  }

  void _undoMove() {
    if (moveStackPtr == 0) {
      // already at bottom of stack
      return;
    }
    final currentState = moveStack[moveStackPtr];
    currentState.card?.isPlayable = true;
    currentState.card?.hasBeenPlayed = false;
    moveStackPtr -= 1;
    final prevState = moveStack[moveStackPtr];
    for (var y = 0; y < battle.board.length; y++) {
      for (var x = 0; x < battle.board[0].length; x++) {
        battle.board[y][x] = prevState.board[y][x];
      }
    }
    battle.boardChangeNotifier.value = Set();
    battle.activatedSpecialsNotifier.value = prevState.activatedSpecials;
    battle.moveCardNotifier.value = null;
    // in case the values were already set to this
    battle.moveCardNotifier.notifyListeners();
    battle.boardChangeNotifier.notifyListeners();
  }

  void _redoMove() {
    if (moveStackPtr == moveStack.length - 1) {
      // already at top of stack
      return;
    }
    moveStackPtr += 1;
    final nextState = moveStack[moveStackPtr];
    for (var y = 0; y < battle.board.length; y++) {
      for (var x = 0; x < battle.board[0].length; x++) {
        battle.board[y][x] = nextState.board[y][x];
      }
    }
    battle.boardChangeNotifier.value = Set();
    battle.activatedSpecialsNotifier.value = nextState.activatedSpecials;
    nextState.card?.isPlayable = false;
    nextState.card?.hasBeenPlayed = true;
    battle.moveCardNotifier.value = null;
    // in case the values were already set to this
    battle.moveCardNotifier.notifyListeners();
    battle.boardChangeNotifier.notifyListeners();
  }

  Future<void> _playMove() async {
    final move = battle.yellowMoveNotifier.value;
    if (move == null || !battle.moveIsValidNotifier.value) {
      return;
    }
    battle.playerControlLock.value = true;
    move.card.hasBeenPlayed = true;
    move.card.isPlayable = false;
    battle.revealCardsNotifier.value = true;
    final modifiedSpaces = move.boardChanges;
    for (final entry in modifiedSpaces.entries) {
      battle.board[entry.key.y][entry.key.x] = entry.value;
    }
    battle.boardChangeNotifier.value = modifiedSpaces.keys.toSet();
    await Future<void>.delayed(Durations.battleUpdateTiles ~/ 2);
    final specialEvents = battle.countSpecial(battle.board).toList();
    late Set<Coords> activatedSpecials;
    if (specialEvents.isNotEmpty) {
      activatedSpecials = (specialEvents[0] as BoardSpecialUpdate).updates;
      battle.activatedSpecialsNotifier.value = activatedSpecials;
      await Future<void>.delayed(Durations.battleUpdateSpecials ~/ 2);
    } else {
      activatedSpecials = Set();
    }
    if (moveStackPtr < moveStack.length - 1) {
      // operations were undone, have to clear them to
      // add this to the stack or the order will get fucked
      moveStack.removeRange(moveStackPtr + 1, moveStack.length);
    }
    moveStack.add(BoardOperation(
      board: battle.board.copy(),
      activatedSpecials: activatedSpecials,
      card: move.card,
    ));
    moveStackPtr += 1;
    battle.moveLocationNotifier.value = null;
    battle.moveCardNotifier.value = null;
    battle.moveRotationNotifier.value = 0;
    battle.moveIsValidNotifier.value = false;
    battle.revealCardsNotifier.value = false;
    battle.yellowMoveNotifier.value = null;
    battle.playerControlLock.value = true;
  }

  Future<void> _resetBoard() async {
    // TODO: play the reset sound here
    final boundary = _screenKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(
      pixelRatio: MediaQuery.of(context).devicePixelRatio,
    );
    battle.playerControlLock.value = true;
    screenImageNotifier.value = image;
    screenWipeController.forward(from: 0.0).then((_) async {
      screenImageNotifier.value = null;
      battle.playerControlLock.value = false;
    });
    for (var y = 0; y < battle.board.length; y++) {
      for (var x = 0; x < battle.board[0].length; x++) {
        battle.board[y][x] = battle.origBoard[y][x];
      }
    }
    battle.boardChangeNotifier.value = Set();
    battle.activatedSpecialsNotifier.value = Set();
    for (final card in battle.yellow.deck) {
      card.isPlayable = true;
      card.hasBeenPlayed = false;
    }
    battle.moveCardNotifier.value = null;
    // in case the values were already set to this
    battle.moveCardNotifier.notifyListeners();
    battle.boardChangeNotifier.notifyListeners();
    moveStack.clear();
    moveStack.add(BoardOperation(
      board: battle.origBoard.copy(),
      activatedSpecials: Set(),
      card: null,
    ));
    moveStackPtr = 0;
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
                key: _boardTileKey,
                battle: battle,
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
                for (final card in battle.yellow.deck)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5.0),
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: CardWidget.CARD_RATIO,
                        child: SelectableCard(battle: battle, card: card),
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
                      if (_lockInputs) {
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
                      if (_lockInputs) {
                        return false;
                      }
                      _lockInputs = true;
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
                onKey: _handleKeyPress,
                child: MouseRegion(
                  onHover: _onHover,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: _onTap,
                    onPanStart: (details) => _onDragStart(details, context),
                    onPanUpdate: (details) => _onDragUpdate(details, context),
                    child: Padding(
                      padding: mediaQuery.padding,
                      child: screen,
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

class SelectableCard extends StatelessWidget {
  const SelectableCard({
    super.key,
    required this.battle,
    required this.card,
  });

  final TableturfBattle battle;
  final TableturfCard card;

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
        child: Center(child: Text("Confirm")),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: [
        CardWidget(
          battle: battle,
          cardNotifier: ValueNotifier(card),
        ),
        ValueListenableBuilder(
          valueListenable: battle.moveCardNotifier,
          builder: (_, selectedCard, ___) {
            if (selectedCard != card) {
              return Container();
            }
            return GestureDetector(
              onTap: () {
                battle.confirmMove();
              },
              child: AnimatedBuilder(
                animation: battle.yellowMoveNotifier,
                child: ValueListenableBuilder(
                  valueListenable: battle.moveIsValidNotifier,
                  builder: (_, bool highlight, button) => AnimatedOpacity(
                    opacity: highlight ? 1 : 0,
                    duration: const Duration(milliseconds: 150),
                    child: _buildButton(context),
                  ),
                ),
                builder: (context, child) {
                  if (battle.yellowMoveNotifier.value != null) {
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
