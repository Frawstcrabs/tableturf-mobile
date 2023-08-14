// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:tableturf_mobile/src/player_progress/player_progress.dart';
import 'package:tableturf_mobile/src/style/shaders.dart';

import '../components/deck_thumbnail.dart';
import '../components/exact_grid.dart';
import '../components/list_select_prompt.dart';
import '../components/multi_choice_prompt.dart';
import '../game_internals/card.dart';
import '../game_internals/deck.dart';
import '../game_internals/map.dart';
import '../game_internals/tile.dart';
import '../components/board_widget.dart';
import '../components/selection_button.dart';
import '../style/constants.dart';
import '../test_area/test_area_screen.dart';

class GridPainter extends CustomPainter {
  static const DASH_LENGTH = 0.4;
  static const DASH_RATIO = 2/3;
  final int height, width;

  const GridPainter({
    required this.height,
    required this.width,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const lineColor = Color.fromRGBO(192, 192, 192, 0.6);
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 0.0
      ..style = PaintingStyle.stroke;
    // we assume the size already fits the aspect ratio of the grid
    final tileLength = size.height / height;
    canvas.drawRect(Offset.zero & size, linePaint);

    final shader = Shaders.dashedLine.fragmentShader();
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    shader.setFloat(2, (lineColor.red / 255.0) * lineColor.opacity);
    shader.setFloat(3, (lineColor.green / 255.0) * lineColor.opacity);
    shader.setFloat(4, (lineColor.blue / 255.0) * lineColor.opacity);
    shader.setFloat(5, lineColor.opacity);
    shader.setFloat(6, DASH_RATIO);

    shader.setFloat(7, DASH_LENGTH / height);
    shader.setFloat(8, 0.0);
    for (var i = 1; i < width; i++) {
      canvas.drawLine(
        Offset(i*tileLength, 0),
        Offset(i*tileLength, size.height),
        Paint()..shader = shader
      );
    }
    shader.setFloat(7, DASH_LENGTH / width);
    shader.setFloat(8, 1.0);
    for (var i = 1; i < height; i++) {
      canvas.drawLine(
          Offset(0, i*tileLength),
          Offset(size.width, i*tileLength),
          Paint()..shader = shader
      );
    }
  }

  @override
  bool shouldRepaint(GridPainter other) {
    return height != other.height || width != other.width;
  }
}

class OffsetBoardPainter extends BoardPainter {
  final ValueListenable<TileGrid> boardNotifier;
  final Coords coords;
  final int gridWidth, gridHeight;
  OffsetBoardPainter({
    required this.boardNotifier,
    required this.coords,
    required this.gridWidth,
    required this.gridHeight,
  }): super(board: boardNotifier.value, repaint: boardNotifier);

  @override
  void paint(Canvas canvas, Size size) {
    final tileSideLength = min(
      size.height / gridHeight,
      size.width / gridWidth,
    );
    canvas.translate(coords.x * tileSideLength, coords.y * tileSideLength);
    final boardSize = Size(board[0].length  * tileSideLength, board.length * tileSideLength);
    super.paint(canvas, boardSize);
  }

  @override
  bool shouldRepaint(OffsetBoardPainter other) {
    return super.shouldRepaint(other)
      || this.boardNotifier != other.boardNotifier
      || this.coords != other.coords
      || this.gridWidth != other.gridWidth
      || this.gridHeight != other.gridHeight;
  }
}

class PaintOperationPainter extends CustomPainter {
  final ValueNotifier<Set<Coords>> touchedCoords;
  final ValueNotifier<TileState> tileNotifier;
  final int gridHeight, gridWidth;

  PaintOperationPainter({
    required this.touchedCoords,
    required this.tileNotifier,
    required this.gridHeight,
    required this.gridWidth,
  }): super(repaint: Listenable.merge([touchedCoords, tileNotifier]));

  @override
  void paint(Canvas canvas, Size size) {
    final coordsSet = touchedCoords.value;
    final state = tileNotifier.value;
    final tileSideLength = min(
      size.height / gridHeight,
      size.width / gridWidth,
    );
    final bodyPaint = Paint()
      ..style = PaintingStyle.fill
      ..strokeJoin = StrokeJoin.miter
      ..color = state == TileState.unfilled ? Palette.tileUnfilled
        : state == TileState.yellowSpecial ? Palette.tileYellowSpecial
        : state == TileState.blueSpecial ? Palette.tileBlueSpecial
        : Colors.red.withOpacity(0.7);
    final edgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.miter
      ..strokeWidth = BoardPainter.EDGE_WIDTH
      ..color = Palette.tileEdge;
    for (final coords in coordsSet) {
      final tileRect = Rect.fromLTWH(
          coords.x * tileSideLength,
          coords.y * tileSideLength,
          tileSideLength,
          tileSideLength
      );
      canvas.drawRect(tileRect, bodyPaint);
      canvas.drawRect(tileRect, edgePaint);
    }
  }

  @override
  bool shouldRepaint(PaintOperationPainter other) {
    return touchedCoords != other.touchedCoords
        || tileNotifier != other.tileNotifier
        || gridWidth != other.gridWidth
        || gridHeight != other.gridHeight;
  }
}

class BlockOperationPainter extends CustomPainter {
  final ValueNotifier<Coords?> startCoords, endCoords;
  final ValueNotifier<TileState> tileNotifier;
  final int gridHeight, gridWidth;

  BlockOperationPainter({
    required this.startCoords,
    required this.endCoords,
    required this.tileNotifier,
    required this.gridHeight,
    required this.gridWidth,
  }): super(repaint: Listenable.merge([startCoords, endCoords, tileNotifier]));

  static Rect _coordsToRect(Coords point, double tileSideLength) {
    return Rect.fromLTWH(point.x * tileSideLength, point.y * tileSideLength, tileSideLength, tileSideLength);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final start = startCoords.value!;
    final end = endCoords.value!;
    final state = tileNotifier.value;
    final tileSideLength = min(
      size.height / gridHeight,
      size.width / gridWidth,
    );
    final bodyPaint = Paint()
      ..style = PaintingStyle.fill
      ..strokeJoin = StrokeJoin.miter
      ..color = state == TileState.unfilled ? Palette.tileUnfilled
        : state == TileState.yellowSpecial ? Palette.tileYellowSpecial
        : state == TileState.blueSpecial ? Palette.tileBlueSpecial
        : Colors.red.withOpacity(0.7);
    final edgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.miter
      ..strokeWidth = BoardPainter.EDGE_WIDTH
      ..color = state.isSpecial ? Colors.black : Colors.white;
    final overwriteRect = _coordsToRect(start, tileSideLength).expandToInclude(_coordsToRect(end, tileSideLength));
    canvas.drawRect(overwriteRect, bodyPaint);
    for (var d = overwriteRect.left + tileSideLength; d < overwriteRect.right; d += tileSideLength) {
      canvas.drawLine(
        Offset(d, overwriteRect.top),
        Offset(d, overwriteRect.bottom),
        edgePaint
      );
    }
    for (var d = overwriteRect.top + tileSideLength; d < overwriteRect.bottom; d += tileSideLength) {
      canvas.drawLine(
        Offset(overwriteRect.left, d),
        Offset(overwriteRect.right, d),
        edgePaint
      );
    }
    canvas.drawRect(overwriteRect, edgePaint);
  }

  @override
  bool shouldRepaint(BlockOperationPainter other) {
    return startCoords != other.startCoords
        || endCoords != other.endCoords
        || tileNotifier != other.tileNotifier
        || gridWidth != other.gridWidth
        || gridHeight != other.gridHeight;
  }

}

enum BoardOperationType {
  changeWidth,
  changeHeight,
  panBoard,
  drawBlock,
  drawPaint,
}

class BoardState {
  final TileGrid board;
  final Coords boardPosition;
  final int gridWidth, gridHeight;

  const BoardState({
    required this.board,
    required this.boardPosition,
    required this.gridWidth,
    required this.gridHeight,
  });
}

enum EditMode {
  pan,
  paint,
  block,
}

class MapEditorScreen extends StatefulWidget {
  final TableturfMap? map;
  const MapEditorScreen({
    super.key,
    required this.map,
  });

  @override
  State<MapEditorScreen> createState() => _MapEditorScreenState();
}

class _MapEditorScreenState extends State<MapEditorScreen> {
  static const int MAX_BOARD_HEIGHT = 30;
  static const int MAX_BOARD_WIDTH = 30;
  late ValueNotifier<TileGrid> boardNotifier;
  ValueNotifier<Coords> boardPositionNotifier = ValueNotifier(Coords.zero);
  ValueNotifier<Coords> opStartCoords = ValueNotifier(Coords.zero);
  ValueNotifier<Coords> opEndCoords = ValueNotifier(Coords.zero);
  ValueNotifier<Set<Coords>> opTouchedCoords = ValueNotifier(Set());
  final boardKey = GlobalKey();

  late final TextEditingController _textEditingController;
  ValueNotifier<BoardOperationType?> operationNotifier = ValueNotifier(null);
  BoardState? prevState = null;
  ValueNotifier<EditMode> modeNotifier = ValueNotifier(EditMode.block);
  ValueNotifier<TileState> tileNotifier = ValueNotifier(TileState.unfilled);
  late List<BoardState> operationStack;
  int operationStackPtr = 0;
  late ValueNotifier<int> gridWidthNotifier, gridHeightNotifier;
  bool _lockButtons = false;
  Future<int>? exitPopup = null;
  Future<TableturfDeck?>? deckSelectPopup = null;

  @override
  void initState() {
    super.initState();
    final playerProgress = PlayerProgress();
    boardNotifier = ValueNotifier(
      widget.map?.board.copy() ?? [[TileState.empty]]
    );
    gridWidthNotifier = ValueNotifier(widget.map?.board[0].length ?? 15);
    gridHeightNotifier = ValueNotifier(widget.map?.board.length ?? 15);
    final name = widget.map?.name ?? "New Map ${playerProgress.maps.length + 1}";
    _textEditingController = TextEditingController(text: name);
    operationStack = [BoardState(
      board: boardNotifier.value.copy(),
      boardPosition: boardPositionNotifier.value,
      gridWidth: gridWidthNotifier.value,
      gridHeight: gridHeightNotifier.value,
    )];
    operationNotifier.addListener(_monitorOperation);
  }

  @override
  void dispose() {
    operationNotifier.removeListener(_monitorOperation);
    super.dispose();
  }

  void _monitorOperation() {
    if (operationNotifier.value == null) {
      print("operation ended");
      final newState = BoardState(
        board: boardNotifier.value.copy(),
        boardPosition: boardPositionNotifier.value,
        gridWidth: gridWidthNotifier.value,
        gridHeight: gridHeightNotifier.value,
      );
      final prevState = operationStack.last;
      if (const ListEquality<List<TileState>>(ListEquality()).equals(prevState.board, newState.board)
          && prevState.boardPosition == newState.boardPosition
          && prevState.gridWidth == newState.gridWidth
          && prevState.gridHeight == newState.gridHeight) {
        // no actual change made
        print("no change");
        return;
      }
      if (operationStackPtr < operationStack.length - 1) {
        // operations were undone, have to clear them to
        // add this to the stack or the order will get fucked
        operationStack.removeRange(operationStackPtr + 1, operationStack.length);
      }
      operationStack.add(newState);
      operationStackPtr += 1;
    }
  }

  void _undoOperation() {
    if (operationStackPtr == 0) {
      // already at bottom of stack
      return;
    }
    operationStackPtr -= 1;
    final prevState = operationStack[operationStackPtr];
    boardNotifier.value = prevState.board.copy();
    boardNotifier.notifyListeners();
    boardPositionNotifier.value = prevState.boardPosition;
    gridHeightNotifier.value = prevState.gridHeight;
    gridWidthNotifier.value = prevState.gridWidth;
  }

  void _redoOperation() {
    if (operationStackPtr == operationStack.length - 1) {
      // already at top of stack
      return;
    }
    operationStackPtr += 1;
    final nextState = operationStack[operationStackPtr];
    boardNotifier.value = nextState.board.copy();
    boardNotifier.notifyListeners();
    boardPositionNotifier.value = nextState.boardPosition;
    gridHeightNotifier.value = nextState.gridHeight;
    gridWidthNotifier.value = nextState.gridWidth;
  }

  void _changeHeight(int height) {
    final board = boardNotifier.value;
    final op = operationNotifier.value;
    if (op != BoardOperationType.changeHeight) {
      return;
    }
    final maxHeight = boardPositionNotifier.value.y + board.length;
    if (height < maxHeight) {
      return;
    }
    gridHeightNotifier.value = height;
  }

  void _changeWidth(int width) {
    final board = boardNotifier.value;
    final op = operationNotifier.value;
    if (op != BoardOperationType.changeWidth) {
      return;
    }
    final maxWidth = boardPositionNotifier.value.x + board[0].length;
    if (width < maxWidth) {
      return;
    }
    gridWidthNotifier.value = width;
  }

  Coords _calculateBoardCoords(Offset position) {
    Size boardSize = boardKey.currentContext!.size!;
    final tileSideLength = min(
      boardSize.height / gridHeightNotifier.value,
      boardSize.width / gridWidthNotifier.value,
    );
    return Coords(position.dx ~/ tileSideLength, position.dy ~/ tileSideLength);
  }

  void _onPanStart(DragStartDetails details) {
    if (operationNotifier.value != null) return;
    final startCoords = _calculateBoardCoords(details.localPosition);
    switch (modeNotifier.value) {
      case EditMode.pan:
        print("pan start");
        operationNotifier.value = BoardOperationType.panBoard;
        opStartCoords.value = boardPositionNotifier.value;
        opEndCoords.value = startCoords;
        break;
      case EditMode.paint:
        print("paint start");
        operationNotifier.value = BoardOperationType.drawPaint;
        opTouchedCoords.value.add(startCoords);
        opTouchedCoords.notifyListeners();
        break;
      case EditMode.block:
        print("block start");
        operationNotifier.value = BoardOperationType.drawBlock;
        opStartCoords.value = startCoords;
        opEndCoords.value = startCoords;
        break;
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final reachedCoords = _calculateBoardCoords(details.localPosition);
    switch (modeNotifier.value) {
      case EditMode.pan:
        if (operationNotifier.value != BoardOperationType.panBoard) return;
        final oldCoords = opEndCoords.value;
        final oldBoardCoords = boardPositionNotifier.value;
        final newBoardCoords = Coords(oldBoardCoords.x + reachedCoords.x - oldCoords.x, oldBoardCoords.y + reachedCoords.y - oldCoords.y);
        final board = boardNotifier.value;
        if (newBoardCoords.x >= 0 && newBoardCoords.x <= gridWidthNotifier.value - board[0].length
            && newBoardCoords.y >= 0 && newBoardCoords.y <= gridHeightNotifier.value - board.length) {
          boardPositionNotifier.value = newBoardCoords;
        }
        opEndCoords.value = reachedCoords;
        break;
      case EditMode.paint:
        if (operationNotifier.value != BoardOperationType.drawPaint) return;
        if (!opTouchedCoords.value.contains(reachedCoords)
            && (reachedCoords.x >= 0 && reachedCoords.x < gridWidthNotifier.value)
            && (reachedCoords.y >= 0 && reachedCoords.y < gridHeightNotifier.value)) {
          opTouchedCoords.value.add(reachedCoords);
          opTouchedCoords.notifyListeners();
        }
        break;
      case EditMode.block:
        if (operationNotifier.value != BoardOperationType.drawBlock) return;
        opEndCoords.value = Coords(
          reachedCoords.x.clamp(0, gridWidthNotifier.value - 1),
          reachedCoords.y.clamp(0, gridHeightNotifier.value - 1),
        );
        break;
    }
  }

  void _onPanEnd(DragEndDetails details) {
    switch (modeNotifier.value) {
      case EditMode.pan:
        if (operationNotifier.value != BoardOperationType.panBoard) return;
        print("pan complete, ${opStartCoords.value} to ${boardPositionNotifier.value}");
        _commitPan();
        opStartCoords.value = Coords.zero;
        opEndCoords.value = Coords.zero;
        break;
      case EditMode.paint:
        if (operationNotifier.value != BoardOperationType.drawPaint) return;
        print("paint complete, touched ${opTouchedCoords.value}");
        _commitPaint();
        opTouchedCoords.value = Set();
        break;
      case EditMode.block:
        if (operationNotifier.value != BoardOperationType.drawBlock) return;
        print("block complete, covered ${opStartCoords.value} to ${opEndCoords.value}");
        _commitBlock();
        opStartCoords.value = Coords.zero;
        opEndCoords.value = Coords.zero;
        break;
    }
    operationNotifier.value = null;
  }

  void _commitPan() {
    // pretty much already done lmao
  }

  void _commitPaint() {
    final coordsSet = opTouchedCoords.value;
    final state = tileNotifier.value;
    final board = boardNotifier.value;
    int left = gridWidthNotifier.value;
    int right = 0;
    int top = gridHeightNotifier.value;
    int bottom = 0;
    for (final coords in coordsSet) {
      if (left > coords.x) {
        left = coords.x;
      }
      if (right < coords.x) {
        right = coords.x;
      }
      if (bottom < coords.y) {
        bottom = coords.y;
      }
      if (top > coords.y) {
        top = coords.y;
      }
    }
    final newBoardPosition = _padBoard(Coords(left, top), Coords(right, bottom));
    boardPositionNotifier.value = newBoardPosition;
    for (final coords in coordsSet) {
      board[coords.y - newBoardPosition.y][coords.x - newBoardPosition.x] = state;
    }
    _trimBoard();
    boardNotifier.notifyListeners();
  }

  void _commitBlock() {
    final startPoint = opStartCoords.value;
    final endPoint = opEndCoords.value;
    final state = tileNotifier.value;
    final board = boardNotifier.value;
    final newBoardPosition = _padBoard(startPoint, endPoint);
    final start = Coords(
      min(startPoint.x, endPoint.x),
      min(startPoint.y, endPoint.y),
    );
    final end = Coords(
      max(startPoint.x, endPoint.x),
      max(startPoint.y, endPoint.y),
    );
    for (int y = start.y; y <= end.y; y++) {
      for (int x = start.x; x <= end.x; x++) {
        board[y - newBoardPosition.y][x - newBoardPosition.x] = state;
      }
    }
    _trimBoard();
    boardNotifier.notifyListeners();
  }

  Coords _padBoard(Coords a, Coords b) {
    final board = boardNotifier.value;
    final boardPosition = boardPositionNotifier.value;
    final start = Coords(
      min(a.x, b.x),
      min(a.y, b.y),
    );
    final end = Coords(
      max(a.x, b.x),
      max(a.y, b.y),
    );
    // pad out board to allow painting
    final topPadding = max(0, boardPosition.y - start.y);
    final bottomPadding = max(0, end.y - (boardPosition.y + board.length - 1));
    final leftPadding = max(0, boardPosition.x - start.x);
    final rightPadding = max(0, end.x - (boardPosition.x + board[0].length - 1));
    if (topPadding > 0) {
      board.insertAll(
          0,
          Iterable.generate(topPadding, (_) => [
            for (var i = 0; i < board[0].length; i++)
              TileState.empty
          ])
      );
    }
    if (bottomPadding > 0) {
      board.addAll(
          Iterable.generate(bottomPadding, (_) => [
            for (var i = 0; i < board[0].length; i++)
              TileState.empty
          ])
      );
    }
    if (leftPadding > 0) {
      for (final row in board) {
        row.insertAll(
            0,
            Iterable.generate(leftPadding, (_) => TileState.empty)
        );
      }
    }
    if (rightPadding > 0) {
      for (final row in board) {
        row.addAll(
            Iterable.generate(rightPadding, (_) => TileState.empty)
        );
      }
    }
    final newBoardPosition = Coords(
      min(start.x, boardPosition.x),
      min(start.y, boardPosition.y),
    );
    boardPositionNotifier.value = newBoardPosition;
    return newBoardPosition;
  }

  void _trimBoard() {
    final board = boardNotifier.value;
    final boardPosition = boardPositionNotifier.value;
    var newTop = boardPosition.y;
    var newLeft = boardPosition.x;

    // trim top edge
    while (board.isNotEmpty) {
      final edge = board[0];
      if (edge.every((e) => e == TileState.empty)) {
        newTop += 1;
        board.removeAt(0);
      } else {
        break;
      }
    }

    // trim bottom edge
    while (board.isNotEmpty) {
      final edge = board.last;
      if (edge.every((e) => e == TileState.empty)) {
        board.removeLast();
      } else {
        break;
      }
    }

    // trim left edge
    while (board.isNotEmpty) {
      final edge = board.map((row) => row[0]);
      if (edge.every((e) => e == TileState.empty)) {
        newLeft += 1;
        for (final row in board) {
          row.removeAt(0);
        }
      } else {
        break;
      }
    }

    // trim right edge
    while (board.isNotEmpty) {
      final edge = board.map((row) => row.last);
      if (edge.every((e) => e == TileState.empty)) {
        for (final row in board) {
          row.removeLast();
        }
      } else {
        break;
      }
    }
    if (board.isEmpty) {
      boardNotifier.value = [[TileState.empty]];
      boardPositionNotifier.value = Coords.zero;
    } else {
      boardPositionNotifier.value = Coords(newLeft, newTop);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final playerProgress = PlayerProgress();

    final boardGrid = GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: RepaintBoundary(
        child: ListenableBuilder(
          key: boardKey,
          listenable: Listenable.merge([gridHeightNotifier, gridWidthNotifier]),
          builder: (_, __) {
            return Stack(
              children: [
                CustomPaint(
                  painter: GridPainter(
                    height: gridHeightNotifier.value,
                    width: gridWidthNotifier.value,
                  ),
                  child: AspectRatio(
                    aspectRatio: gridWidthNotifier.value / gridHeightNotifier.value,
                  ),
                  isComplex: true,
                ),
                RepaintBoundary(
                  child: ListenableBuilder(
                    listenable: Listenable.merge([boardNotifier, boardPositionNotifier]),
                    builder: (_, __) {
                      final width = gridWidthNotifier.value;
                      final height = gridHeightNotifier.value;
                      final coords = boardPositionNotifier.value;
                      return CustomPaint(
                        painter: OffsetBoardPainter(
                          boardNotifier: boardNotifier,
                          coords: coords,
                          gridHeight: height,
                          gridWidth: width,
                        ),
                        child: AspectRatio(
                          aspectRatio: gridWidthNotifier.value / gridHeightNotifier.value,
                        ),
                        isComplex: true,
                      );
                    }
                  ),
                ),
                RepaintBoundary(
                  child: ListenableBuilder(
                    listenable: operationNotifier,
                    builder: (_, __) {
                      var sizedChild = AspectRatio(
                        aspectRatio: gridWidthNotifier.value / gridHeightNotifier.value,
                      );
                      switch (operationNotifier.value) {
                        case BoardOperationType.drawBlock:
                          return CustomPaint(
                            painter: BlockOperationPainter(
                              startCoords: opStartCoords,
                              endCoords: opEndCoords,
                              tileNotifier: tileNotifier,
                              gridHeight: gridHeightNotifier.value,
                              gridWidth: gridWidthNotifier.value,
                            ),
                            child: sizedChild,
                            willChange: false,
                          );
                        case BoardOperationType.drawPaint:
                          return CustomPaint(
                            painter: PaintOperationPainter(
                              touchedCoords: opTouchedCoords,
                              tileNotifier: tileNotifier,
                              gridHeight: gridHeightNotifier.value,
                              gridWidth: gridWidthNotifier.value,
                            ),
                            child: sizedChild,
                            willChange: false,
                          );
                        default:
                          return sizedChild;
                      }
                    }
                  )
                )
              ],
            );
          }
        ),
      ),
    );
    final editor = Column(
      children: [
        Expanded(
          flex: 1,
          child: Row(
            children: [
              const Spacer(flex: 9),
              Expanded(
                flex: 1,
                child: RepaintBoundary(
                  child: ValueListenableBuilder(
                    valueListenable: gridHeightNotifier,
                    builder: (_, int height, __) {
                      return Center(
                        child: Text(
                          height.toString(),
                          //style: TextStyle(height: 1)
                        ),
                      );
                    }
                  ),
                )
              )
            ]
          )
        ),
        Expanded(
          flex: 13,
          child: Row(
            children: [
              const Spacer(flex: 1),
              Expanded(
                flex: 8,
                child: Center(
                  child: boardGrid
                ),
              ),
              Expanded(
                flex: 1,
                child: RotatedBox(
                  quarterTurns: 1,
                  child: RepaintBoundary(
                    child: ListenableBuilder(
                      listenable: gridHeightNotifier,
                      builder: (_, __) {
                        final height = gridHeightNotifier.value;
                        return Slider.adaptive(
                          value: height.toDouble(),
                          max: MAX_BOARD_HEIGHT.toDouble(),
                          min: 1,
                          divisions: MAX_BOARD_HEIGHT - 1,
                          onChangeStart: (newHeight) {
                            if (operationNotifier.value == null) {
                              operationNotifier.value = BoardOperationType.changeHeight;
                            }
                          },
                          onChanged: (newHeight) {
                            _changeHeight(newHeight.floor());
                          },
                          onChangeEnd: (newHeight) {
                            if (operationNotifier.value == BoardOperationType.changeHeight) {
                              operationNotifier.value = null;
                            }
                          },
                        );
                      }
                    ),
                  )
                )
              ),
            ],
          ),
        ),
        Expanded(
          flex: 1,
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: RepaintBoundary(
                  child: ValueListenableBuilder(
                    valueListenable: gridWidthNotifier,
                    builder: (_, int width, __) {
                      return Center(
                        child: Text(
                          width.toString(),
                          //style: TextStyle(height: 1.5)
                        ),
                      );
                    }
                  ),
                )
              ),
              Expanded(
                flex: 8,
                child: RepaintBoundary(
                  child: ListenableBuilder(
                      listenable: gridWidthNotifier,
                      builder: (_, __) {
                        final width = gridWidthNotifier.value;
                        return Slider(
                          value: width.toDouble(),
                          max: MAX_BOARD_WIDTH.toDouble(),
                          min: 1,
                          divisions: MAX_BOARD_WIDTH - 1,
                          onChangeStart: (newWidth) {
                            if (operationNotifier.value == null) {
                              operationNotifier.value = BoardOperationType.changeWidth;
                            }
                          },
                          onChanged: (newWidth) {
                            _changeWidth(newWidth.floor());
                          },
                          onChangeEnd: (newWidth) {
                            if (operationNotifier.value == BoardOperationType.changeWidth) {
                              operationNotifier.value = null;
                            }
                          },
                        );
                      }
                  ),
                )
              ),
              const Spacer(flex: 1),
            ]
          )
        ),
      ],
    );
    final screen = Column(
      children: [
        Expanded(
          flex: 1,
          child: Row(
            children: [
              Flexible(
                child: TextField(
                  controller: _textEditingController,
                  style: TextStyle(
                    fontFamily: "Splatfont2",
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    border: UnderlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.all(0),
                  ),
                ),
              ),
            ],
          ),
        ),
        divider,
        Expanded(
          flex: 9,
          child: editor,
        ),
        Expanded(
          flex: 2,
          child: Row(
            children: [
              Expanded(
                child: RepaintBoundary(
                  child: ValueListenableBuilder(
                    valueListenable: modeNotifier,
                    builder: (context, EditMode currentMode, ___) {
                      final makeModeButton = (EditMode mode, IconData icon) => GestureDetector(
                        onTap: () {
                          modeNotifier.value = mode;
                        },
                        child: Container(
                          margin: EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey, width: 0.0),
                            borderRadius: BorderRadius.circular(8),
                            color: currentMode == mode ? Colors.white54 : Colors.black54
                          ),
                          child: AspectRatio(
                            aspectRatio: 2,
                            child: FractionallySizedBox(
                              heightFactor: 0.8,
                              widthFactor: 0.8,
                              child: FittedBox(
                                alignment: Alignment.center,
                                child: Icon(
                                  icon,
                                  color: currentMode == mode ? Colors.black87 : Colors.white54
                                )
                              ),
                            ),
                          ),
                        ),
                      );
                      return ExactGrid(
                        height: 2,
                        width: 2,
                        children: [
                          makeModeButton(EditMode.block, Icons.check_box_outline_blank),
                          makeModeButton(EditMode.paint, Icons.brush),
                          makeModeButton(EditMode.pan, Icons.tab_unselected),
                        ]
                      );
                    },
                  ),
                )
              ),
              const VerticalDivider(color: Colors.black),
              Expanded(
                child: ValueListenableBuilder(
                  valueListenable: tileNotifier,
                  builder: (context, TileState currentTile, ___) {
                    final makeTileButton = (TileState tile, Widget icon) => GestureDetector(
                      onTap: () {
                        tileNotifier.value = tile;
                      },
                      child: Container(
                        margin: EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey, width: 0.0),
                          borderRadius: BorderRadius.circular(8),
                          color: currentTile == tile ? Colors.white54 : Colors.black54
                        ),
                        child: AspectRatio(
                          aspectRatio: 2,
                          child: Center(child: icon),
                        ),
                      ),
                    );
                    return ExactGrid(
                      height: 2,
                      width: 2,
                      children: [
                        makeTileButton(TileState.blueSpecial, FractionallySizedBox(
                          heightFactor: 0.5,
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Palette.tileBlueSpecial,
                                border: Border.all(
                                    color: Palette.tileEdge,
                                    width: BoardPainter.EDGE_WIDTH
                                ),
                              ),
                            )
                          ),
                        )),
                        makeTileButton(TileState.yellowSpecial, FractionallySizedBox(
                          heightFactor: 0.5,
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Palette.tileYellowSpecial,
                                border: Border.all(
                                    color: Palette.tileEdge,
                                    width: BoardPainter.EDGE_WIDTH
                                ),
                              ),
                            )
                          ),
                        )),
                        makeTileButton(TileState.unfilled, FractionallySizedBox(
                          heightFactor: 0.5,
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Palette.tileUnfilled,
                                border: Border.all(
                                  color: Palette.tileEdge,
                                  width: BoardPainter.EDGE_WIDTH
                                ),
                              ),
                            )
                          ),
                        )),
                        makeTileButton(TileState.empty, Center(
                          child: Icon(
                            Icons.close,
                            color: currentTile == TileState.empty ? Colors.black87 : Colors.white54
                          ),
                        )),
                      ]
                    );
                  }
                ),
              ),
            ],
          )
        ),
        divider,
        Expanded(
          flex: 1,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: SelectionButton(
                    child: Text(
                      "Test",
                      style: TextStyle(fontSize: 16),
                    ),
                    designRatio: 0.5,
                    onPressStart: () async {
                      if (_lockButtons) {
                        return false;
                      }
                      deckSelectPopup = showListSelectPrompt(
                        context,
                        title: "Select Deck",
                        builder: (context, exitPopup) => ListView.builder(
                          itemCount: playerProgress.decks.length,
                          padding: const EdgeInsets.all(10.0),
                          itemBuilder: (_, i) {
                            var deck = playerProgress.decks[i].value;
                            final widget = AspectRatio(
                              aspectRatio: DeckThumbnail.THUMBNAIL_RATIO,
                              child: DeckThumbnail(deck: deck),
                            );
                            if (deck.cards.any((c) => c == null)) {
                              return ColorFiltered(
                                colorFilter: ColorFilter.mode(
                                  const Color.fromRGBO(0, 0, 0, 0.3),
                                  BlendMode.srcATop,
                                ),
                                child: widget,
                              );
                            } else {
                              return GestureDetector(
                                onTap: () {
                                  exitPopup(deck);
                                },
                                child: widget,
                              );
                            }
                          },
                        ),
                      );
                      return true;
                    },
                    onPressEnd: () async {
                      final selectedDeck = await deckSelectPopup!;
                      deckSelectPopup = null;
                      if (selectedDeck == null) {
                        return;
                      }
                      await Future<void>.delayed(const Duration(milliseconds: 150));
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) {
                          return TestAreaScreen(
                            board: boardNotifier.value,
                            deck: selectedDeck.cards
                                .whereNotNull()
                                .map(playerProgress.identToCard)
                                .toList(),
                          );
                        },
                      ));
                      return Future<void>.delayed(const Duration(milliseconds: 100));
                    },
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _undoOperation,
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
                  onTap: _redoOperation,
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
                      if (_lockButtons) {
                        return false;
                      }
                      _lockButtons = true;
                      exitPopup = showMultiChoicePrompt(
                        context,
                        title: "Save changes?",
                        options: ["Back to Edit", "Save!", "Don't Save"],
                        defaultResult: 0,
                      );
                      return true;
                    },
                    onPressEnd: () async {
                      final choice = await exitPopup!;
                      exitPopup = null;
                      switch (choice) {
                        case 0:
                          _lockButtons = false;
                          return;
                        case 1:
                          if (widget.map == null) {
                            playerProgress.createMap(
                              name: _textEditingController.text,
                              board: boardNotifier.value.copy(),
                            );
                          } else {
                            playerProgress.updateMap(
                              mapID: widget.map!.mapID,
                              name: _textEditingController.text,
                              board: boardNotifier.value.copy(),
                            );
                          }
                          Navigator.of(context).pop(true);
                          return Future<void>.delayed(const Duration(milliseconds: 100));
                        case 2:
                          Navigator.of(context).pop(false);
                          return Future<void>.delayed(const Duration(milliseconds: 100));
                      }
                    },
                  ),
                ),
              ),
            ],
          )
        ),
      ],
    );

    return WillPopScope(
      onWillPop: () async => true,
      child: Scaffold(
        backgroundColor: Palette.backgroundMapEditor,
        body: DefaultTextStyle(
          style: TextStyle(
            fontFamily: "Splatfont2",
            color: Colors.white,
            fontSize: 18,
            letterSpacing: 0.6,
            shadows: [
              Shadow(
                color: const Color.fromRGBO(256, 256, 256, 0.4),
                offset: Offset(1, 1),
              )
            ]
          ),
          child: Padding(
            padding: mediaQuery.padding,
            child: screen
          ),
        )
      ),
    );
  }
}
