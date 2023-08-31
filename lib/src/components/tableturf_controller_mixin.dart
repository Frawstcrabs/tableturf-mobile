import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tableturf_mobile/src/game_internals/battle.dart';

import '../audio/audio_controller.dart';
import '../audio/sounds.dart';
import '../game_internals/card.dart';

mixin TableturfBattleMixin<T extends StatefulWidget> on State<T> {
  TableturfBattleController get controller;
  GlobalKey get inputAreaKey;
  double tileSize = 22.0;
  Offset? piecePosition;
  PointerDeviceKind? pointerKind;
  bool lockInputs = false;

  void _updateLocation(
      Offset delta,
      PointerDeviceKind? pointerKind,
      BuildContext rootContext,
      ) {
    if (controller.playerControlIsLocked.value ||
        controller.moveCardNotifier.value == null) {
      return;
    }
    final board = controller.board;
    if (piecePosition != null) {
      piecePosition = piecePosition! + delta;
    }

    final boardContext = inputAreaKey.currentContext!;
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
      controller.moveLocationNotifier.value = null;
      // if pointer is touch, let the position remain
    } else if (controller.moveLocationNotifier.value != newCoords) {
      final audioController = AudioController();
      if (controller.moveCardNotifier.value != null &&
          !controller.movePassNotifier.value) {
        audioController.playSfx(SfxType.cursorMove);
      }
      controller.moveLocationNotifier.value = newCoords;
    }
  }

  void _resetPiecePosition(BuildContext rootContext) {
    final boardContext = inputAreaKey.currentContext!;
    final boardTileStep = tileSize;
    final boardLocation =
    (boardContext.findRenderObject()! as RenderBox).localToGlobal(
      Offset.zero,
      ancestor: rootContext.findRenderObject(),
    );
    if (controller.moveLocationNotifier.value == null) {
      controller.moveLocationNotifier.value = Coords(
        controller.board[0].length ~/ 2,
        controller.board.length ~/ 2,
      );
    }
    final pieceLocation = controller.moveLocationNotifier.value!;
    piecePosition = Offset(
      boardLocation.dx +
          (pieceLocation.x * boardTileStep) +
          (boardTileStep / 2),
      boardLocation.dy +
          (pieceLocation.y * boardTileStep) +
          (boardTileStep / 2),
    );
  }

  void onHover(PointerHoverEvent details) {
    if (lockInputs) return;

    if (details.kind == PointerDeviceKind.mouse) {
      piecePosition = details.localPosition;
      pointerKind = details.kind;
      _updateLocation(details.delta, details.kind, context);
    }
  }

  void onDragUpdate(DragUpdateDetails details, BuildContext context) {
    if (lockInputs) return;
    _updateLocation(details.delta, pointerKind, context);
  }

  void onDragStart(DragStartDetails details, BuildContext context) {
    if (lockInputs) return;

    _resetPiecePosition(context);
    pointerKind = details.kind;
    _updateLocation(Offset.zero, pointerKind, context);
  }

  void onTap() {
    if (!controller.playerControlIsLocked.value) {
      if (pointerKind == PointerDeviceKind.mouse) {
        controller.confirmMove();
      } else {
        controller.rotateClockwise();
      }
    }
  }

  KeyEventResult handleKeyPress(FocusNode node, RawKeyEvent event) {
    if (lockInputs) return KeyEventResult.ignored;

    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.keyQ) {
        if (controller.playerControlIsLocked.value) {
          return KeyEventResult.ignored;
        }
        controller.rotateCounterClockwise();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyE) {
        if (controller.playerControlIsLocked.value) {
          return KeyEventResult.ignored;
        }
        controller.rotateClockwise();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }
}