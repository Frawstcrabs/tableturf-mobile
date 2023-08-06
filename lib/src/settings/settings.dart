// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';


/// An class that holds settings like [playerName] or [musicOn],
/// and saves them to an injected persistence store.
class Settings {
  late final SharedPreferences _prefs;
  static const _commitChanges = !kDebugMode;

  static final Settings _controller = Settings._internal();

  factory Settings() {
    return _controller;
  }

  Settings._internal() {}

  // Whether or not the sound is on at all. This overrides both music and sound.
  ValueNotifier<bool> _muted = ValueNotifier(false);
  ValueNotifier<bool> _soundsOn = ValueNotifier(false);
  ValueNotifier<bool> _musicOn = ValueNotifier(false);
  ValueNotifier<bool> _continuousAnimation = ValueNotifier(false);
  ValueNotifier<String> _playerName = ValueNotifier('Player');

  ValueListenable<bool> get muted => _muted;
  ValueListenable<bool> get soundsOn => _soundsOn;
  ValueListenable<bool> get musicOn => _musicOn;
  ValueListenable<bool> get continuousAnimation => _continuousAnimation;
  ValueListenable<String> get playerName => _playerName;

  /// Asynchronously loads values from the injected persistence store.
  Future<void> loadStateFromPersistence(SharedPreferences prefs) async {
    _prefs = prefs;
    _musicOn.value = _prefs.getBool('musicOn') ?? true;
    _soundsOn.value = _prefs.getBool('soundsOn') ?? true;
    _continuousAnimation.value = _prefs.getBool('continuousAnimation') ?? false;
    _muted.value = _prefs.getBool('muted') ?? kIsWeb;
    _playerName.value = _prefs.getString('playerName') ?? "Player";
  }

  void setPlayerName(String name) {
    _playerName.value = name;
    if (_commitChanges)
      _prefs.setString('playerName', name);
  }

  void toggleMusicOn() {
    _musicOn.value = !_musicOn.value;
    if (_commitChanges)
      _prefs.setBool('musicOn', _musicOn.value);
  }

  void toggleMuted() {
    _muted.value = !_muted.value;
    if (_commitChanges)
      _prefs.setBool('muted', _muted.value);
  }

  void toggleSoundsOn() {
    _soundsOn.value = !_soundsOn.value;
    if (_commitChanges)
      _prefs.setBool('soundsOn', _soundsOn.value);
  }

  void toggleContinuousAnimation() {
    _continuousAnimation.value = !_continuousAnimation.value;
    if (_commitChanges)
      _prefs.setBool('continuousAnimation', _continuousAnimation.value);
  }
}
