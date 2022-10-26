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
  Color get pen => const Color(0xff1d75fb);
  Color get darkPen => const Color(0xFF0050bc);
  Color get redPen => const Color(0xFFd10841);
  Color get inkFullOpacity => const Color(0xff352b42);
  Color get ink => const Color(0xee352b42);
  Color get backgroundMain => const Color(0xffffffd1);
  Color get backgroundLevelSelection => const Color(0xffa2dcc7);
  Color get backgroundPlaySession => const Color(0xff3f2f93);
  Color get background4 => const Color(0xffffd7ff);
  Color get backgroundSettings => const Color(0xffbfc8e3);
  Color get trueWhite => const Color(0xffffffff);

  Color get tileUnfilled => const Color.fromRGBO(0, 0, 32, 1);
  Color get tileEdge => const Color.fromRGBO(80, 80, 80, 1);
  Color get tileWall => const Color.fromRGBO(160, 160, 160, 1);
  Color get tileYellow => const Color.fromRGBO(255, 255, 17, 1);
  Color get tileYellowSpecial => const Color.fromRGBO(255, 159, 4, 1);
  Color get tileBlue => const Color.fromRGBO(71, 92, 255, 1);
  Color get tileBlueSpecial => const Color.fromRGBO(10, 255, 255, 1);

  Color get cardBackground => const Color.fromRGBO(48, 48, 48, 1);
  Color get cardBackgroundSelected => const Color.fromRGBO(130, 130, 130, 1);
  Color get cardEdge => const Color.fromRGBO(0, 0, 0, 1);
  Color get cardTileUnfilled => const Color.fromRGBO(32, 32, 32, 0.7);
  Color get cardTileEdge => const Color.fromRGBO(120, 120, 120, 1);

  Color get buttonSelected => const Color.fromRGBO(216, 216, 0, 1);
  Color get buttonUnselected => const Color.fromRGBO(109, 161, 198, 1);
}