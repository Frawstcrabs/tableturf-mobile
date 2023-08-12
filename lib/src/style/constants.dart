// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';

class Durations {
  // misc
  static const fadeToBlackTransition = Duration(milliseconds: 400);
  static const transitionToGame = Duration(milliseconds: 800);

  // game session
  static const _animateBattleScoreDiff = 1000;
  static const _animateBattleScoreSum = 200;
  static const battleUpdateTiles = Duration(milliseconds: 1000);
  static const battleUpdateSpecials = Duration(milliseconds: 1000);
  static const battleUpdateScores = Duration(milliseconds: _animateBattleScoreDiff + _animateBattleScoreSum + 300);
  static const battleNopEvent = Duration(milliseconds: 1000);
  static const animateInSpecialPoint = Duration(milliseconds: 250);
  static const animateBattleScoreDiff = Duration(milliseconds: _animateBattleScoreDiff);
  static const animateBattleScoreSum = Duration(milliseconds: _animateBattleScoreSum);
  static const animateTurnCounter = Duration(milliseconds: 1300);
  static const turnCounterUpdate = Duration(milliseconds: 360);
  static const turnCounterBounceUp = Duration(milliseconds: 60);

  static const xpBarFill = Duration(milliseconds: 1000);
  static const xpBarPause = Duration(milliseconds: 1000);
}

class Palette {
  static const darkPen = const Color(0xFF0050bc);
  static const ink = const Color(0xee352b42);
  static const backgroundMain = const Color(0xff404040);
  static const backgroundLevelSelection = const Color(0xffa2dcc7);
  static const backgroundCardList = const Color.fromRGBO(208, 220, 220, 1.0);
  static const backgroundDeckList = const Color.fromRGBO(213, 225, 213, 1.0);
  static const backgroundDeckEditor = const Color.fromRGBO(239, 226, 221, 1.0);
  static const backgroundMapList = const Color.fromRGBO(43, 43, 73, 1.0);
  static const backgroundMapEditor = const Color.fromRGBO(40, 40, 44, 1.0);
  static const backgroundPlaySession = const Color(0xff3f2f93);
  static const backgroundPlaySessionHeader = const Color.fromRGBO(0, 0, 0, 0.2);
  static const backgroundSettings = const Color(0xffbfc8e3);

  static const tileUnfilled = const Color.fromRGBO(0, 0, 0, 0.8);
  static const tileEdge = const Color.fromRGBO(80, 80, 80, 1);
  static const tileWall = const Color.fromRGBO(160, 160, 160, 1);
  static const tileYellow = const Color.fromRGBO(255, 255, 17, 1);
  static const tileYellowSpecial = const Color.fromRGBO(255, 149, 51, 1.0);
  static const tileYellowSpecialCenter = const Color.fromRGBO(225, 255, 17, 1);
  static const tileYellowSpecialFlame = const Color.fromRGBO(255, 184, 54, 1.0);
  static const tileBlue = const Color.fromRGBO(71, 92, 255, 1);
  static const tileBlueSpecial = const Color.fromRGBO(21, 234, 234, 1.0);
  static const tileBlueSpecialCenter = const Color.fromRGBO(240, 255, 255, 1);
  static const tileBlueSpecialFlame = const Color.fromRGBO(152, 255, 255, 1.0);

  static const cardBackgroundUnselectable = const Color.fromRGBO(40, 40, 40, 1);
  static const cardBackgroundSelectable = const Color.fromRGBO(64, 64, 64, 1);
  static const cardBackgroundSelected = const Color.fromRGBO(140, 140, 140, 1);
  static const cardEdge = const Color.fromRGBO(0, 0, 0, 1);
  static const cardTileUnfilled = const Color.fromRGBO(32, 32, 32, 0.4);
  static const cardTileEdge = const Color.fromRGBO(120, 120, 120, 1);
  static const mapThumbnailBorder = const Color.fromRGBO(62, 66, 168, 1.0);
  static const mapThumbnailBackground = const Color.fromRGBO(139, 146, 243, 1.0);

  static const inGameButtonSelected = const Color.fromRGBO(216, 216, 0, 1);
  static const inGameButtonUnselected = const Color.fromRGBO(109, 161, 198, 1);
  
  static const selectionButtonSelected = const Color.fromRGBO(167, 231, 9, 1.0);
  static const selectionButtonUnselected = const Color.fromRGBO(71, 16, 175, 1.0);
  
  static const xpTitleText = const Color.fromRGBO(206, 56, 226, 1.0);
  static const xpRankUpText = const Color.fromRGBO(250, 253, 3, 1.0);
  static const xpAddedPointsGradientStart = const Color.fromRGBO(107, 213, 2, 1.0);
  static const xpAddedPointsGradientEnd = const Color.fromRGBO(31, 169, 7, 1.0);
}

const divider = Divider(
  color: Colors.black,
  height: 1.0,
  thickness: 1.0,
);