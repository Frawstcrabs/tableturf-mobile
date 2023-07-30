// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tableturf_mobile/src/game_internals/card.dart';
import 'package:tableturf_mobile/src/game_internals/opponentAI.dart';

const rankRequirements = [
   100,  200,  300,  400,  500,  600,  700,  800,  900, 1000,
  1100, 1200, 1300, 1400, 1500, 1600, 1700, 1800, 1900, 2000,
  2100, 2200, 2300, 2400, 2500, 2600, 2700, 2800, 2900, 3000,
  3100, 3200, 3300, 3400, 3500, 3600, 3700, 3800, 3900, 4000,
  4100, 4200, 4300, 4400, 4500, 4600, 4700, 4800, 4900,
];
final maxRankAmount = rankRequirements.reduce((a, b) => a + b);

int calculateXpToRank(int xp) {
  int ret = 1;
  for (final amount in rankRequirements) {
    if (amount > xp) {
      break;
    }
    ret += 1;
    xp -= amount;
  }
  return ret;
}

/// Encapsulates the player's progress.
class PlayerProgress {
  late final SharedPreferences _prefs;
  static const DIFFICULTY_UNLOCK_THRESHOLD = 3;
  static const _commitChanges = !kDebugMode;

  static final PlayerProgress _controller = PlayerProgress._internal();

  factory PlayerProgress() {
    return _controller;
  }

  PlayerProgress._internal() {}

  late Map<String, Map<AILevel, int>> _winCounts;

  late int _xp;
  late List<TableturfCardIdentifier> _unlockedCards;
  late List<String> _unlockedCardSleeves;
  late List<int> _unlockedOpponents;

  int get xp => _xp;
  set xp(int value) {
    _xp = value;
    if (_commitChanges) {
      _prefs.setInt("tableturf-xp", value);
    }
  }

  List<int> get unlockedOpponents => _unlockedOpponents;

  int get rank => calculateXpToRank(_xp);

  /// Asynchronously loads values from the injected persistence store.
  Future<void> loadStateFromPersistence(SharedPreferences prefs) async {
    _prefs = prefs;
    final Map<String, dynamic> winCountJson = jsonDecode(
      _prefs.getString("tableturf-wins") ?? "{}"
    );
    _winCounts = Map.fromEntries(winCountJson.entries.map((entry) {
      final opponentID = entry.key;
      final winCounts = entry.value as Map<String, dynamic>;
      return MapEntry(
        opponentID,
        {
          for (final winEntry in winCounts.entries)
            AILevel.values[int.parse(winEntry.key)]: winEntry.value as int
        }
      );
    }));
    _xp = _prefs.getInt("tableturf-xp") ?? 0;

    final List unlockedOpponentsJson = jsonDecode(
      _prefs.getString("tableturf-unlocked_opponents") ?? "[-1]"
    );
    _unlockedOpponents = unlockedOpponentsJson.map(
        (i) => i as int
    ).toList();
  }

  Future<void> _writeWinCounts() async {
    if (_commitChanges) {
      final encodedJson = jsonEncode({
        for (final entry in _winCounts.entries)
          entry.key: {
            for (final winEntry in entry.value.entries)
              winEntry.key.index.toString(): winEntry.value
          }
      });
      _prefs.setString("tableturf-wins", encodedJson);
    }
  }

  Map<AILevel, int> getWins(String key) {
    if (!_winCounts.containsKey(key)) {
      _winCounts[key] = {
        for (final level in AILevel.values)
          level: 0
      };
    }
    return _winCounts[key]!;
  }

  int incrementWins(String key, AILevel difficulty) {
    final difficultyMap = _winCounts[key]!;
    if (!difficultyMap.containsKey(difficulty)) {
      difficultyMap[difficulty] = 1;
    } else {
      difficultyMap[difficulty] = difficultyMap[difficulty]! + 1;
    }
    _writeWinCounts();
    return difficultyMap[difficulty]!;
  }

  Future<void> _writeUnlockedOpponents() async {
    if (_commitChanges) {
      await _prefs.setString(
        "tableturf-unlocked_opponents",
        jsonEncode(_unlockedOpponents)
      );
    }
  }

  void unlockOpponent(int opponentID) {
    _unlockedOpponents.add(opponentID);
    _writeUnlockedOpponents();
  }

  Future<void> reset() async {
    for (final entry in _winCounts.entries) {
      for (final winEntry in entry.value.entries) {
        entry.value[winEntry.key] = 0;
      }
    }
    _unlockedOpponents = [-1];
    xp = 0;
    _writeWinCounts();
    _writeUnlockedOpponents();
  }
}
