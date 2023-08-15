// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart' as AA;
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart' as JA;
import 'package:soundpool/soundpool.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';

import '../settings/settings.dart';
import 'songs.dart';
import 'sounds.dart';

const kMaxSfxPlayers = 16;

abstract class _MusicPlayer {
  double get volume;
  set volume(double value);
  Timer? musicFadeTimer;

  Future<void> initialize() async {}
  void dispose() {}
  Future<void> loadSong(SongType song);
  Future<void> startSong();
  Future<void> stopSong({Duration? fadeDuration});
  Future<void> playSfx(SfxType sfx);

  Future<void> setVolume(double value, {Duration? fadeDuration}) async {
    musicFadeTimer?.cancel();
    if (fadeDuration == null || fadeDuration <= Duration.zero) {
      volume = value;
      return;
    }

    final retFuture = Completer<void>();

    final startVolume = volume;
    final diff = (value - volume);
    final fadeTime = fadeDuration.inMilliseconds;
    int stepLen = max(4, fadeTime ~/ 100);
    final stopwatch = Stopwatch()..start();

    musicFadeTimer = Timer.periodic(new Duration(milliseconds: stepLen), (t) async {
      final elapsed = stopwatch.elapsedMilliseconds;
      final tick = elapsed / fadeTime;
      final newVolume = (startVolume + (diff * tick)).clamp(0.0, 1.0);
      volume = newVolume;

      if (elapsed >= fadeTime) {
        t.cancel();
        stopwatch.stop();
        volume = value;
        retFuture.complete();
      }
    });

    return await retFuture.future;
  }

  Future<void> mute() async {
    await setVolume(0.0);
  }

  Future<void> unmute() async {
    await setVolume(1.0);
  }

  Future<void> muteSfx();
  Future<void> unmuteSfx();
}

class _MobileMusicPlayer extends _MusicPlayer {
  JA.AudioPlayer musicPlayer = JA.AudioPlayer();
  StreamSubscription<int?>? _musicLoopTimer;
  StreamSubscription<bool>? _musicPlayMonitor;

  Soundpool _sfxPlayer = Soundpool.fromOptions(options: SoundpoolOptions(maxStreams: 8));
  Map<SfxType, List<int>> _sfxSources = {};

  _MobileMusicPlayer() {}

  Future<void> initialize() async {
    await Future.wait([
      for (final sfx in SfxType.values) () async {
        _sfxSources[sfx] = await Future.wait([
          for (final filename in soundTypeToFilename(sfx)) () async {
            final content = await rootBundle.load("assets/sfx/$filename");
            final soundId = await _sfxPlayer.load(content);
            print("loading sfx $filename return sound id $soundId");
            return soundId;
          }()
        ]);
      }()
    ]);
  }

  double _volume = 1.0;
  double get volume => _volume;
  set volume(double value) {
    value = value.clamp(0.0, 1.0);
    _volume = value;
    musicPlayer.setVolume(value);
  }

  @override
  Future<void> playSfx(SfxType sfx) async {
    final options = _sfxSources[sfx]!;
    final index = Random().nextInt(options.length);

    await _sfxPlayer.play(options[index]);
  }

  @override
  Future<void> loadSong(SongType type) async {
    musicFadeTimer?.cancel();
    final song = songMap[type]!;
    await musicPlayer.setAudioSource(
      JA.ConcatenatingAudioSource(children: [
        JA.AudioSource.uri(Uri.parse("asset:///assets/music/${song.introFilename}")),
        JA.AudioSource.uri(Uri.parse("asset:///assets/music/${song.loopFilename}")),
      ])
    );
    await musicPlayer.pause();
    await musicPlayer.setLoopMode(JA.LoopMode.all);
    await musicPlayer.setVolume(1.0);
    _musicLoopTimer = musicPlayer.currentIndexStream.listen((index) {
      if (index == null) {
        _musicLoopTimer?.cancel();
      } else if (index == 1) {
        musicPlayer.setLoopMode(JA.LoopMode.one);
        _musicLoopTimer?.cancel();
      }
    });
  }

  @override
  Future<void> startSong() async {
    assert(musicPlayer.audioSource != null);
    volume = 1.0;
    musicPlayer.play();
  }

  @override
  Future<void> stopSong({Duration? fadeDuration}) async {
    await setVolume(0.0, fadeDuration: fadeDuration);
    await _musicPlayMonitor?.cancel();
    await musicPlayer.stop();
    await musicPlayer.setAudioSource(JA.ConcatenatingAudioSource(children: []));
  }

  @override
  Future<void> muteSfx() async {
    await Future.wait([
      for (final soundId in _sfxSources.values.flattened)
        _sfxPlayer.setVolume(soundId: soundId, volume: 0.0)
    ]);
  }

  @override
  Future<void> unmuteSfx() async {
    await Future.wait([
      for (final MapEntry(key: sfx, value: soundIds) in _sfxSources.entries)
        for (final soundId in soundIds)
          _sfxPlayer.setVolume(soundId: soundId, volume: soundTypeToVolume(sfx))
    ]);
  }

  @override
  void dispose() {
    _sfxPlayer.dispose();
    musicPlayer.dispose();
  }
}

class _DesktopMusicPlayer extends _MusicPlayer {
  AA.AudioPlayer musicStartPlayer, musicLoopPlayer;
  Timer? _musicFadeTimer;

  final AA.AudioCache _sfxCache = AA.AudioCache(prefix: "assets/sfx/");
  final Map<SfxType, List<String>> _sfxSources;
  bool _sfxIsMuted = false;

  _DesktopMusicPlayer():
    musicStartPlayer = AA.AudioPlayer(),
    musicLoopPlayer = AA.AudioPlayer(),
    _sfxSources = {} {
    musicStartPlayer.onPlayerComplete.listen((_) {
      musicLoopPlayer.resume();
    });
  }

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
  }

  double _volume = 1.0;
  double get volume => _volume;
  set volume(double value) {
    value = value.clamp(0.0, 1.0);
    _volume = value;
    musicStartPlayer.setVolume(value);
    musicLoopPlayer.setVolume(value);
  }


  @override
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
        musicLoopPlayer.setReleaseMode(AA.ReleaseMode.loop);
      }(),
    ]);
  }

  @override
  Future<void> startSong() async {
    assert(musicStartPlayer.source != null && musicLoopPlayer.source != null);
    volume = 1.0;
    await musicStartPlayer.resume();
  }

  @override
  Future<void> stopSong({Duration? fadeDuration}) async {
    await setVolume(0.0, fadeDuration: fadeDuration);
    await musicStartPlayer.stop();
    await musicLoopPlayer.stop();
    //await musicStartPlayer.release();
    //await musicLoopPlayer.release();
  }

  @override
  Future<void> playSfx(SfxType sfx) async {
    if (_sfxIsMuted) return;
    final options = _sfxSources[sfx]!;
    final index = Random().nextInt(options.length);
    final player = AA.AudioPlayer()..audioCache = _sfxCache;
    await player.play(
      AA.AssetSource(options[index]),
      mode: AA.PlayerMode.lowLatency,
    );
  }

  @override
  Future<void> muteSfx() async {
    _sfxIsMuted = true;
  }

  @override
  Future<void> unmuteSfx() async {
    _sfxIsMuted = false;
  }
}

class AudioController {
  static final _log = Logger('AudioController');

  late final _MusicPlayer _musicPlayer;

  Settings? _settings;

  ValueNotifier<AppLifecycleState>? _lifecycleNotifier;

  static final AudioController _controller = AudioController._internal();

  factory AudioController() {
    return _controller;
  }

  AudioController._internal() {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      _log.info("loading mobile music player");
      _musicPlayer = _MobileMusicPlayer();
    } else {
      _log.info("loading desktop music player");
      _musicPlayer = _DesktopMusicPlayer();
    }
  }

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
    _muteMusic();
    _muteSfx();
    _musicPlayer.dispose();
  }

  /// Preloads all sound effects.
  Future<void> initialize() async {
    await _musicPlayer.initialize();
  }

  Future<void> playSfx(SfxType sfx) async {
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
    _musicPlayer.playSfx(sfx);
  }

  Future<void> loadSong(SongType type) async {
    await _musicPlayer.loadSong(type);
    _log.info("load complete");
  }

  Future<void> startSong() async {
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
    await _musicPlayer.startSong();
  }

  Future<void> playSong(SongType type) async {
    await loadSong(type);
    await startSong();
  }

  Future<void> stopSong({Duration? fadeDuration}) async {
    await _musicPlayer.stopSong(fadeDuration: fadeDuration);
  }

  Future<void> setVolume(double value, {Duration? fadeDuration}) async {
    await _musicPlayer.setVolume(value, fadeDuration: fadeDuration);
  }

  void _handleAppLifecycle() {
    switch (_lifecycleNotifier!.value) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _muteAll();
        break;
      case AppLifecycleState.resumed:
        if (!_settings!.muted.value) {
          if (_settings!.musicOn.value) {
            _unmuteMusic();
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
      _unmuteMusic();
    } else {
      _muteMusic();
    }
  }

  void _mutedHandler() {
    if (_settings!.muted.value) {
      // All sound just got muted.
      _muteAll();
    } else {
      // All sound just got un-muted.
      if (_settings!.musicOn.value) {
        _unmuteMusic();
      }
      if (_settings!.soundsOn.value) {
        _unmuteSfx();
      }
    }
  }

  void _muteMusic() {
    _log.info('Muting music');
    _musicPlayer.mute();
  }

  Future<void> _unmuteMusic() async {
    _log.info('Unmuting music');
    _musicPlayer.unmute();
  }

  void _muteAll() {
    _muteMusic();
    _muteSfx();
  }

  Future<void> _muteSfx() async {
    _log.info("muting sfx");
    _musicPlayer.muteSfx();
  }

  Future<void> _unmuteSfx() async {
    _log.info("unmuting sfx");
    _musicPlayer.unmuteSfx();
  }

  void _soundsOnHandler() {
    if (!_settings!.muted.value && _settings!.soundsOn.value) {
      _unmuteSfx();
    } else {
      _muteSfx();
    }
  }
}
