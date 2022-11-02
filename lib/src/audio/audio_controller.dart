// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:soundpool/soundpool.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';

import '../settings/settings.dart';
import 'songs.dart';
import 'sounds.dart';

class AudioController {
  static final _log = Logger('AudioController');

  final AudioPlayer musicPlayer;

  final Soundpool _sfxPlayer;
  final Map<SfxType, List<int>> _sfxSources;

  final Random _random = Random();

  SettingsController? _settings;

  ValueNotifier<AppLifecycleState>? _lifecycleNotifier;

  static final AudioController _controller = AudioController._internal();

  factory AudioController() {
    return _controller;
  }

  AudioController._internal():
        musicPlayer = AudioPlayer(),
        _sfxPlayer = Soundpool.fromOptions(options: SoundpoolOptions(maxStreams: 8)),
        _sfxSources = {} {
  }

  void attachLifecycleNotifier(
      ValueNotifier<AppLifecycleState> lifecycleNotifier) {
    _lifecycleNotifier?.removeListener(_handleAppLifecycle);

    lifecycleNotifier.addListener(_handleAppLifecycle);
    _lifecycleNotifier = lifecycleNotifier;
  }

  void attachSettings(SettingsController settingsController) {
    if (_settings == settingsController) {
      // Already attached to this instance. Nothing to do.
      return;
    }

    // Remove handlers from the old settings controller if present
    final oldSettings = _settings;
    if (oldSettings != null) {
      oldSettings.muted.removeListener(_mutedHandler);
      oldSettings.musicOn.removeListener(_musicOnHandler);
      oldSettings.soundsOn.removeListener(_soundsOnHandler);
    }

    _settings = settingsController;

    // Add handlers to the new settings controller
    settingsController.muted.addListener(_mutedHandler);
    settingsController.musicOn.addListener(_musicOnHandler);
    settingsController.soundsOn.addListener(_soundsOnHandler);
  }

  void dispose() {
    _lifecycleNotifier?.removeListener(_handleAppLifecycle);
    _stopAllSound();
    musicPlayer.dispose();
    _sfxPlayer.dispose();
  }

  /// Preloads all sound effects.
  Future<void> initialize() async {
    for (final sfx in SfxType.values) {
      _sfxSources[sfx] = [];
      final volume = soundTypeToVolume(sfx);
      for (final filename in soundTypeToFilename(sfx)) {
        final content = await rootBundle.load("assets/sfx/$filename");
        final soundId = await _sfxPlayer.load(content);
        print("loading sfx $filename return sound id $soundId");
        await _sfxPlayer.setVolume(soundId: soundId, volume: volume);
        _sfxSources[sfx]!.add(soundId);
      }
    }
  }

  Future<void> playSfx(SfxType type) async {
    final muted = _settings?.muted.value ?? true;
    if (muted) {
      _log.info(() => 'Ignoring playing sound ($type) because audio is muted.');
      return;
    }
    final soundsOn = _settings?.soundsOn.value ?? false;
    if (!soundsOn) {
      _log.info(() =>
          'Ignoring playing sound ($type) because sounds are turned off.');
      return;
    }

    final options = _sfxSources[type]!;
    final index = _random.nextInt(options.length);

    _sfxPlayer.play(options[index]);
  }

  void _handleAppLifecycle() {
    switch (_lifecycleNotifier!.value) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _stopAllSound();
        break;
      case AppLifecycleState.resumed:
        if (!_settings!.muted.value) {
          if (_settings!.musicOn.value) {
            _resumeMusic();
          }
          if (_settings!.soundsOn.value) {
            _unmuteSfx();
          }
        }
        break;
      case AppLifecycleState.inactive:
        // No need to react to this state change.
        break;
    }
  }

  void _musicOnHandler() {
    if (!_settings!.muted.value && _settings!.musicOn.value) {
      _resumeMusic();
    } else {
      _stopMusic();
    }
  }

  void _mutedHandler() {
    if (_settings!.muted.value) {
      // All sound just got muted.
      _stopAllSound();
    } else {
      // All sound just got un-muted.
      if (_settings!.musicOn.value) {
        _resumeMusic();
      }
      if (_settings!.soundsOn.value) {
        _unmuteSfx();
      }
    }
  }

  Future<void> _resumeMusic() async {
    _log.info('Resuming music');
    musicPlayer.play();
  }

  Future<void> _muteSfx() async {
    for (final soundIds in _sfxSources.values) {
      for (final soundId in soundIds) {
        _sfxPlayer.setVolume(soundId: soundId, volume: 0.0);
      }
    }
  }

  Future<void> _unmuteSfx() async {
    for (final entry in _sfxSources.entries) {
      final sfx = entry.key;
      final soundIds = entry.value;
      final volume = soundTypeToVolume(sfx);
      for (final soundId in soundIds) {
        await _sfxPlayer.setVolume(soundId: soundId, volume: volume);
      }
    }
  }

  void _soundsOnHandler() {
    if (!_settings!.muted.value && _settings!.soundsOn.value) {
      _unmuteSfx();
    } else {
      _muteSfx();
    }
  }

  void _stopAllSound() {
    if (musicPlayer.playing) {
      musicPlayer.pause();
    }
    _muteSfx();
  }

  void _stopMusic() {
    _log.info('Stopping music');
    if (musicPlayer.playing) {
      musicPlayer.pause();
    }
  }
}
