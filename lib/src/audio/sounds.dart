// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

List<String> soundTypeToFilename(SfxType type) {
  switch (type) {
    case SfxType.cursorRotate:
      return const [
        "rotate0.ogg",
        "rotate1.ogg",
        "rotate2.ogg",
        "rotate3.ogg",
        "rotate4.ogg",
      ];
    default:
      return ["${type.toString().split('.').last}.ogg"];
  }
}

/// Allows control over loudness of different SFX types.
double soundTypeToVolume(SfxType type) {
  switch (type) {
    case SfxType.cursorMove:
      return 1.0;
    case SfxType.cursorRotate:
      return 0.7;
    case SfxType.confirmMoveSucceed:
    case SfxType.confirmMovePass:
      return 0.4;
    case SfxType.cardFlip:
      return 0.5;
    default:
      return 1.0;
  }
}

enum SfxType {
  dealHand,
  selectCardNormal,
  cardFlip,
  cardDiscard,
  confirmMoveSucceed,
  confirmMovePass,
  counterUpdate,
  specialActivate,
  gainSpecial,
  normalMove,
  normalMoveOverlap,
  specialMove,
  normalMoveConflict,
  cursorMove,
  cursorRotate,
  turnCountNormal,
  turnCountEnding,
}
