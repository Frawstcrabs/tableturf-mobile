// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

List<String> soundTypeToFilename(SfxType type) {
  switch (type) {
    case SfxType.cursorRotate:
      return const [
        "rotate0.mp3",
        "rotate1.mp3",
        "rotate2.mp3",
        "rotate3.mp3",
        "rotate4.mp3",
      ];
    default:
      return ["${type.name}.mp3"];
  }
}

/// Allows control over loudness of different SFX types.
double soundTypeToVolume(SfxType type) {
  switch (type) {
    /*
    case SfxType.cursorMove:
      return 1.0;
    case SfxType.cursorRotate:
      return 0.7;
    case SfxType.confirmMoveSucceed:
    case SfxType.confirmMovePass:
      return 0.5;
    case SfxType.cardFlip:
      return 0.8;
    case SfxType.gainSpecial:
      return 0.5;

     */
    default:
      return 1.0;
  }
}

enum SfxType {
  menuButtonPress,

  cardPackOpen,
  cardPackBits,

  screenWipe,

  dealHand,
  selectCardNormal,
  cardFlip,
  cardDiscard,
  confirmMoveSucceed,
  confirmMovePass,
  confirmMoveSpecial,
  counterUpdate,
  gameIntro,
  gameIntroExit,
  gameStart,
  gameEndWhistle,
  specialActivate,
  gainSpecial,
  normalMove,
  normalMoveOverlap,
  specialMove,
  normalMoveConflict,
  cursorMove,
  cursorRotate,
  specialCutIn,
  turnCountNormal,
  turnCountEnding,
  giveUpOpen,
  giveUpSelect,
  scoreBarFill,
  scoreBarImpact,
  xpGaugeFill,
  rankUp,
}
