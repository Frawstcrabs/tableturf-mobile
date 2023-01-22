// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

enum SongType {
  battle1,
  last3Turns,
  levelSelect,
  resultWin,
  resultLose,
  itemSelect,
  edit,
}

class Song {
  final String introFilename, loopFilename;
  final Duration introDuration;

  const Song(this.introFilename, this.introDuration, this.loopFilename);
}

const Map<SongType, Song> songMap = {
  SongType.battle1: Song(
    "intro_battle1.mp3",
    Duration(seconds: 8),
    "loop_battle1.mp3",
  ),
  SongType.last3Turns: Song(
    "intro_last3Turns.mp3",
    Duration(seconds: 8),
    "loop_last3Turns.mp3",
  ),
  SongType.levelSelect: Song(
    "intro_levelSelect.mp3",
    Duration(seconds: 5),
    "loop_levelSelect.mp3",
  ),
  SongType.resultWin: Song(
    "intro_resultWin.mp3",
    Duration(seconds: 9),
    "loop_resultWin.mp3",
  ),
  SongType.resultLose: Song(
    "intro_resultLose.mp3",
    Duration(seconds: 3),
    "loop_resultLose.mp3",
  ),
  SongType.itemSelect: Song(
    "intro_itemSelect.mp3",
    Duration(seconds: 6),
    "loop_itemSelect.mp3",
  ),
  SongType.edit: Song(
    "intro_edit.mp3",
    Duration(seconds: 2),
    "loop_edit.mp3",
  ),
};