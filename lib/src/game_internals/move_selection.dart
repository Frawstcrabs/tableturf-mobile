import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import '../audio/audio_controller.dart';
import '../audio/sounds.dart';
import 'opponentAI.dart';
import 'card.dart';
import 'tile.dart';
import 'move.dart';
import 'player.dart';

class TableturfMoveSelection {
  static final _log = Logger('TableturfMoveSelection');

  final ValueNotifier<TableturfCard?> moveCardNotifier = ValueNotifier(null);
  final ValueNotifier<Coords?> moveLocationNotifier = ValueNotifier(null);
  final ValueNotifier<int> moveRotationNotifier = ValueNotifier(0);
  final ValueNotifier<bool> moveSpecialNotifier = ValueNotifier(false);
  final ValueNotifier<bool> movePassNotifier = ValueNotifier(false);
  final ValueNotifier<bool> moveIsValidNotifier = ValueNotifier(false);
  final ValueNotifier<bool> playerControlLock = ValueNotifier(true);

  final TableturfPlayer player;
  final BoardGrid board;

  TableturfMoveSelection({required this.player, required this.board}) {
    moveCardNotifier.addListener(_updateMoveHighlight);
    moveLocationNotifier.addListener(_updateMoveHighlight);
    moveRotationNotifier.addListener(_updateMoveHighlight);
    movePassNotifier.addListener(_updateMoveHighlight);
    moveSpecialNotifier.addListener(_updateMoveHighlight);
  }

  void _updateMoveHighlight() {
    final card = moveCardNotifier.value;
    final rot = moveRotationNotifier.value;
    final location = moveLocationNotifier.value;
    final special = moveSpecialNotifier.value;
    final pass = movePassNotifier.value;
    if (pass) {
      moveIsValidNotifier.value = card != null;
    } else if (location != null
        && card != null) {
      final pattern = rotatePattern(
          card.minPattern,
          rot
      );
      final selectPoint = rotatePatternPoint(
          card.selectPoint,
          card.minPattern.length,
          card.minPattern[0].length,
          rot
      );
      final locationX = location.x - selectPoint.x;
      final locationY = location.y - selectPoint.y;
      if (!(
          locationY >= 0
              && locationY <= board.length - pattern.length
              && locationX >= 0
              && locationX <= board[0].length - pattern[0].length
      )) {
        moveIsValidNotifier.value = false;
        return;
      }
      final move = TableturfMove(
        card: card,
        rotation: rot,
        x: locationX,
        y: locationY,
        special: special,
        traits: player.traits,
      );
      moveIsValidNotifier.value = moveIsValid(board, move);
    }
  }

  void rotateLeft() {
    final audioController = AudioController();
    audioController.playSfx(SfxType.cursorRotate);
    int rot = moveRotationNotifier.value;
    rot -= 1;
    rot %= 4;
    moveRotationNotifier.value = rot;
  }

  void rotateRight() {
    final audioController = AudioController();
    audioController.playSfx(SfxType.cursorRotate);
    int rot = moveRotationNotifier.value;
    rot += 1;
    rot %= 4;
    moveRotationNotifier.value = rot;
  }

  void confirmMove() {
    if (!moveIsValidNotifier.value) {
      return;
    }
    final card = moveCardNotifier.value!;
    final audioController = AudioController();
    if (movePassNotifier.value) {
      audioController.playSfx(SfxType.confirmMovePass);
      yellowMoveNotifier.value = TableturfMove(
        card: card,
        rotation: 0,
        x: 0,
        y: 0,
        pass: movePassNotifier.value,
        special: moveSpecialNotifier.value,
      );
      playerControlLock.value = false;
      return;
    }

    final location = moveLocationNotifier.value;
    if (location == null) {
      return;
    }
    final rot = moveRotationNotifier.value;
    final pattern = rotatePattern(card.minPattern, rot);
    final selectPoint = rotatePatternPoint(
      card.selectPoint,
      card.minPattern.length,
      card.minPattern[0].length,
      rot,
    );
    final locationX = location.x - selectPoint.x;
    final locationY = location.y - selectPoint.y;
    _log.info("trying location $locationX, $locationY");
    if (!(
        locationY >= 0
            && locationY <= board.length - pattern.length
            && locationX >= 0
            && locationX <= board[0].length - pattern[0].length
    )) {
      return;
    }
    audioController.playSfx(SfxType.confirmMoveSucceed);
    yellowMoveNotifier.value = TableturfMove(
      card: card,
      rotation: rot,
      x: locationX,
      y: locationY,
      pass: movePassNotifier.value,
      special: moveSpecialNotifier.value,
    );
    playerControlLock.value = false;
  }

  void resetSelection() {
    moveLocationNotifier.value = null;
    moveCardNotifier.value = null;
    moveRotationNotifier.value = 0;
    movePassNotifier.value = false;
    moveSpecialNotifier.value = false;
    moveIsValidNotifier.value = false;
  }
}