// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';

import '../settings/settings.dart';
import 'songs.dart';
import 'sounds.dart';

const kMaxSfxPlayers = 16;

class AudioController {
  static final _log = Logger('AudioController');

  final AudioPlayer musicStartPlayer, musicLoopPlayer;
  Timer? _musicFadeTimer;

  final List<AudioPlayer> _sfxPlayers;
  int _nextSfxPlayer = 0;
  final AudioCache _sfxCache = AudioCache(prefix: "assets/sfx/");
  final Map<SfxType, List<String>> _sfxSources;

  final Random _random = Random();

  Settings? _settings;

  ValueNotifier<AppLifecycleState>? _lifecycleNotifier;

  static final AudioController _controller = AudioController._internal();

  factory AudioController() {
    return _controller;
  }

  AudioController._internal():
    musicStartPlayer = AudioPlayer(),
    musicLoopPlayer = AudioPlayer(),
    _sfxPlayers = List.generate(kMaxSfxPlayers, (_) => AudioPlayer()),
    _sfxSources = {}
  {}

  void attachLifecycleNotifier(
      ValueNotifier<AppLifecycleState> lifecycleNotifier) {
    _lifecycleNotifier?.removeListener(_handleAppLifecycle);

    lifecycleNotifier.addListener(_handleAppLifecycle);
    _lifecycleNotifier = lifecycleNotifier;
  }

  void attachSettings(Settings settingsController) {
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
    musicLoopPlayer.dispose();
    musicStartPlayer.dispose();
    for (final player in _sfxPlayers) {
      player.dispose();
    }
  }

  /// Preloads all sound effects.
  Future<void> initialize() async {
    for (final sfx in SfxType.values) {
      _sfxSources[sfx] = [];
    }
    await Future.wait([
      for (final sfx in SfxType.values) () async {
        _sfxSources[sfx] = await Future.wait([
          for (final filename in soundTypeToFilename(sfx)) () async {
            await _sfxCache.load(filename);
            return filename;
          }()
        ]);
      }()
    ]);
    for (final player in _sfxPlayers) {
      player.audioCache = _sfxCache;
      //await player.setPlayerMode(PlayerMode.lowLatency);
    }
    musicStartPlayer.onPlayerComplete.listen((_) {
      musicLoopPlayer.resume();
    });
  }

  Future<void> _rebuildSfxPlayer(int index) async {
    final player = AudioPlayer();
    final oldPlayer = _sfxPlayers[index];
    player.audioCache = _sfxCache;
    await player.setPlayerMode(PlayerMode.lowLatency);
    _sfxPlayers[index] = player;
    oldPlayer.dispose();
  }

  Future<void> playSfx(SfxType type) async {
    final muted = _settings?.muted.value ?? true;
    if (muted) {
      _log.info(() => 'Ignoring playing sound because audio is muted.');
      return;
    }
    final soundsOn = _settings?.soundsOn.value ?? false;
    if (!soundsOn) {
      _log.info(() =>
          'Ignoring playing sound because sounds are turned off.');
      return;
    }

    final options = _sfxSources[type]!;
    final index = _random.nextInt(options.length);
    final player = AudioPlayer()..audioCache = _sfxCache;
    await player.play(
      AssetSource(options[index]),
      mode: PlayerMode.lowLatency,
    );
  }

  Future<void> loadSong(SongType type) async {
    _musicFadeTimer?.cancel();
    final song = songMap[type]!;
    await Future.wait([
      () async {
        await musicStartPlayer.release();
        await musicStartPlayer.setSourceAsset(
          "music/${song.introFilename}"
        );
        await musicStartPlayer.pause();
      }(),
      () async {
        await musicLoopPlayer.release();
        await musicLoopPlayer.setSourceAsset(
          "music/${song.loopFilename}"
        );
        await musicLoopPlayer.pause();
        musicLoopPlayer.setReleaseMode(ReleaseMode.loop);
      }(),
    ]);
    _log.info("load complete");
  }

  Future<void> startSong() async {
    assert(musicStartPlayer.source != null && musicLoopPlayer.source != null);
    final muted = _settings?.muted.value ?? true;
    if (muted) {
      _log.info('Ignoring playing sound because audio is muted.');
      return;
    }
    final musicOn = _settings?.musicOn.value ?? false;
    if (!musicOn) {
      _log.info('Ignoring playing song because music is turned off.');
      return;
    }
    _log.info("playing start");
    musicStartPlayer.setVolume(1.0);
    musicLoopPlayer.setVolume(1.0);
    await musicStartPlayer.resume();
  }

  Future<void> playSong(SongType type) async {
    await loadSong(type);
    await startSong();
  }

  Future<void> stopSong({Duration? fadeDuration}) async {
    _musicFadeTimer?.cancel();
    if (fadeDuration == null || fadeDuration <= Duration.zero) {
      await musicStartPlayer.stop();
      await musicLoopPlayer.stop();
      await musicStartPlayer.release();
      await musicLoopPlayer.release();
      return;
    }

    final retFuture = Completer<void>();

    double vol = 1.0;
    final fadeTime = fadeDuration.inMilliseconds;
    int stepLen = max(4, fadeTime ~/ 100);
    int lastTick = DateTime.now().millisecondsSinceEpoch;

    _musicFadeTimer = Timer.periodic(new Duration(milliseconds: stepLen), (t) async {
      var now = DateTime.now().millisecondsSinceEpoch;
      var tick = (now - lastTick) / fadeTime;
      lastTick = now;
      vol -= tick;

      vol = vol.clamp(0.0, 1.0);

      musicStartPlayer.setVolume(vol);
      musicLoopPlayer.setVolume(vol);

      if (vol == 0.0) {
        t.cancel();
        _log.info("clearing music source");
        await musicStartPlayer.stop();
        await musicLoopPlayer.stop();
        await musicStartPlayer.release();
        await musicLoopPlayer.release();
        retFuture.complete();
      }
    });

    return await retFuture.future;
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
    //musicPlayer.play();
  }

  Future<void> _muteSfx() async {
    _log.info("muting sfx");
    for (final player in _sfxPlayers) {
      await player.setVolume(0.0);
    }
  }

  Future<void> _unmuteSfx() async {
    _log.info("unmuting sfx");
    for (final player in _sfxPlayers) {
      await player.setVolume(1.0);
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
    if (musicStartPlayer.state == PlayerState.playing || musicLoopPlayer.state == PlayerState.playing) {
      musicStartPlayer.pause();
      musicLoopPlayer.pause();
    }
    _muteSfx();
  }

  void _stopMusic() {
    _log.info('Stopping music');
    if (musicStartPlayer.state == PlayerState.playing || musicLoopPlayer.state == PlayerState.playing) {
      musicStartPlayer.pause();
      musicLoopPlayer.pause();
    }
  }
}
