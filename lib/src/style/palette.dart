// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';

/// A palette of colors to be used in the game.
///
/// The reason we're not going with something like Material Design's
/// `Theme` is simply that this is simpler to work with and yet gives
/// us everything we need for a game.
///
/// Games generally have more radical color palettes than apps. For example,
/// every level of a game can have radically different colors.
/// At the same time, games rarely support dark mode.
///
/// Colors taken from this fun palette:
/// https://lospec.com/palette-list/crayola84
///
/// Colors here are implemented as getters so that hot reloading works.
/// In practice, we could just as easily implement the colors
/// as `static const`. But this way the palette is more malleable:
/// we could allow players to customize colors, for example,
/// or even get the colors from the network.
class Palette {
  const Palette();
  Color get darkPen => const Color(0xFF0050bc);
  Color get ink => const Color(0xee352b42);
  Color get backgroundMain => const Color(0xffffffd1);
  Color get backgroundLevelSelection => const Color(0xffa2dcc7);
  Color get backgroundCardList => const Color.fromRGBO(208, 220, 220, 1.0);
  Color get backgroundDeckList => const Color.fromRGBO(213, 225, 213, 1.0);
  Color get backgroundDeckEditor => const Color.fromRGBO(229, 224, 239, 1.0);
  Color get backgroundMapList => const Color.fromRGBO(43, 43, 73, 1.0);
  Color get backgroundMapEditor => const Color.fromRGBO(40, 40, 44, 1.0);
  Color get backgroundPlaySession => const Color(0xff3f2f93);
  Color get backgroundSettings => const Color(0xffbfc8e3);

  Color get tileUnfilled => const Color.fromRGBO(0, 0, 0, 0.8);
  Color get tileEdge => const Color.fromRGBO(80, 80, 80, 1);
  Color get tileWall => const Color.fromRGBO(160, 160, 160, 1);
  Color get tileYellow => const Color.fromRGBO(255, 255, 17, 1);
  Color get tileYellowSpecial => const Color.fromRGBO(245, 127, 11, 1.0);
  Color get tileYellowSpecialCenter => const Color.fromRGBO(225, 255, 17, 1);
  Color get tileYellowSpecialFlame => const Color.fromRGBO(255, 159, 4, 1);
  Color get tileBlue => const Color.fromRGBO(71, 92, 255, 1);
  Color get tileBlueSpecial => const Color.fromRGBO(21, 234, 234, 1.0);
  Color get tileBlueSpecialCenter => const Color.fromRGBO(240, 255, 255, 1);
  Color get tileBlueSpecialFlame => const Color.fromRGBO(152, 255, 255, 1.0);

  Color get cardBackgroundUnselectable => const Color.fromRGBO(40, 40, 40, 1);
  Color get cardBackgroundSelectable => const Color.fromRGBO(64, 64, 64, 1);
  Color get cardBackgroundSelected => const Color.fromRGBO(140, 140, 140, 1);
  Color get cardEdge => const Color.fromRGBO(0, 0, 0, 1);
  Color get cardTileUnfilled => const Color.fromRGBO(32, 32, 32, 0.4);
  Color get cardTileEdge => const Color.fromRGBO(120, 120, 120, 1);
  Color get mapThumbnailBorder => const Color.fromRGBO(62, 66, 168, 1.0);
  Color get mapThumbnailBackground => const Color.fromRGBO(139, 146, 243, 1.0);

  Color get inGameButtonSelected => const Color.fromRGBO(216, 216, 0, 1);
  Color get inGameButtonUnselected => const Color.fromRGBO(109, 161, 198, 1);

  Color get selectionButtonSelected => const Color.fromRGBO(167, 231, 9, 1.0);
  Color get selectionButtonUnselected => const Color.fromRGBO(71, 16, 175, 1.0);

  Color get xpTitleText => const Color.fromRGBO(206, 56, 226, 1.0);
  Color get xpRankUpText => const Color.fromRGBO(250, 253, 3, 1.0);
  Color get xpAddedPointsGradientStart => const Color.fromRGBO(107, 213, 2, 1.0);
  Color get xpAddedPointsGradientEnd => const Color.fromRGBO(31, 169, 7, 1.0);
}