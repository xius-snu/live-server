import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Manages all game audio: background music loop and one-shot SFX.
class AudioService extends ChangeNotifier {
  // Background music player (loops continuously)
  final AudioPlayer _bgmPlayer = AudioPlayer();

  // SFX players (short one-shots, we keep separate instances so they can overlap)
  final AudioPlayer _rollerSfxPlayer = AudioPlayer();
  final AudioPlayer _roundCompleteSfxPlayer = AudioPlayer();

  bool _musicEnabled = false; // TODO: re-enable
  bool _sfxEnabled = true;
  bool _bgmStarted = false;

  bool get musicEnabled => _musicEnabled;
  bool get sfxEnabled => _sfxEnabled;

  AudioService() {
    _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    _bgmPlayer.setVolume(0.3); // background music quieter

    // Configure SFX players to not steal audio focus on Android.
    // This prevents SFX from interrupting BGM or each other.
    _rollerSfxPlayer.setAudioContext(AudioContext(
      android: AudioContextAndroid(
        usageType: AndroidUsageType.game,
        contentType: AndroidContentType.sonification,
        audioFocus: AndroidAudioFocus.none,
      ),
    ));
    _roundCompleteSfxPlayer.setAudioContext(AudioContext(
      android: AudioContextAndroid(
        usageType: AndroidUsageType.game,
        contentType: AndroidContentType.sonification,
        audioFocus: AndroidAudioFocus.none,
      ),
    ));

    // Configure BGM to duck other audio (lower volume of other apps)
    // but keep its own focus stable
    _bgmPlayer.setAudioContext(AudioContext(
      android: AudioContextAndroid(
        usageType: AndroidUsageType.game,
        contentType: AndroidContentType.music,
        audioFocus: AndroidAudioFocus.gainTransientMayDuck,
      ),
    ));

    _rollerSfxPlayer.setVolume(0.6);
    _roundCompleteSfxPlayer.setVolume(0.7);
  }

  /// Start background music. Safe to call multiple times — only starts once.
  Future<void> startBgm() async {
    if (!_musicEnabled || _bgmStarted) return;
    try {
      await _bgmPlayer.play(AssetSource('sfx/backgroundmusicloop.mp3'));
      _bgmStarted = true;
    } catch (e) {
      debugPrint('AudioService: BGM play failed: $e');
    }
  }

  /// Stop background music.
  Future<void> stopBgm() async {
    await _bgmPlayer.stop();
    _bgmStarted = false;
  }

  /// Play the roller sweep-up sound (on each tap/paint stroke).
  Future<void> playRollerSweep() async {
    if (!_sfxEnabled) return;
    try {
      await _rollerSfxPlayer.stop(); // reset if still playing
      await _rollerSfxPlayer.play(
        AssetSource('sfx/rollersweepup.mp3'),
        mode: PlayerMode.lowLatency, // uses SoundPool on Android
      );
    } catch (e) {
      debugPrint('AudioService: roller SFX failed: $e');
    }
  }

  /// Play the round-complete cash register sound.
  /// [streak] controls pitch: each streak level = +1 semitone, max 10.
  Future<void> playRoundComplete({int streak = 0}) async {
    if (!_sfxEnabled) return;
    try {
      final semitones = streak.clamp(0, 10);
      final rate = pow(2, semitones / 12).toDouble();
      await _roundCompleteSfxPlayer.stop();
      await _roundCompleteSfxPlayer.setPlaybackRate(rate);
      await _roundCompleteSfxPlayer.play(
        AssetSource('sfx/roundcomplete_cashregister.mp3'),
        mode: PlayerMode.lowLatency, // uses SoundPool on Android
      );
    } catch (e) {
      debugPrint('AudioService: round-complete SFX failed: $e');
    }
  }

  /// Toggle background music on/off.
  void toggleMusic() {
    _musicEnabled = !_musicEnabled;
    if (_musicEnabled) {
      startBgm();
    } else {
      stopBgm();
    }
    notifyListeners();
  }

  /// Toggle SFX on/off.
  void toggleSfx() {
    _sfxEnabled = !_sfxEnabled;
    notifyListeners();
  }

  /// Pause BGM (e.g. when app goes to background).
  Future<void> pauseBgm() async {
    if (_bgmStarted) {
      await _bgmPlayer.pause();
    }
  }

  /// Resume BGM (e.g. when app comes back to foreground).
  Future<void> resumeBgm() async {
    if (_bgmStarted && _musicEnabled) {
      await _bgmPlayer.resume();
    }
  }

  @override
  void dispose() {
    _bgmPlayer.dispose();
    _rollerSfxPlayer.dispose();
    _roundCompleteSfxPlayer.dispose();
    super.dispose();
  }
}
