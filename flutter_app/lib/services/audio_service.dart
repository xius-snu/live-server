import 'dart:io' show Platform;
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether we're running on a desktop platform (Windows/macOS/Linux).
bool get _isDesktop =>
    !kIsWeb &&
    (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

/// A pool of AudioPlayer instances that allows overlapping one-shot SFX.
/// Each play() grabs the next player in the pool (round-robin), so multiple
/// sounds can be active at once without cancelling each other.
class _SfxPool {
  final int size;
  final double volume;
  late final List<AudioPlayer> _players;
  int _index = 0;

  _SfxPool({this.size = 4, this.volume = 0.6}) {
    _players = List.generate(size, (_) {
      final p = AudioPlayer();
      p.setVolume(volume);
      // On Android, prevent SFX from stealing audio focus
      if (!kIsWeb && Platform.isAndroid) {
        p.setAudioContext(AudioContext(
          android: AudioContextAndroid(
            usageType: AndroidUsageType.game,
            contentType: AndroidContentType.sonification,
            audioFocus: AndroidAudioFocus.none,
          ),
        ));
      }
      return p;
    });
  }

  Future<void> play(String asset, {double playbackRate = 1.0}) async {
    final player = _players[_index];
    _index = (_index + 1) % size;
    // On desktop, avoid lowLatency mode which can cause single-channel issues
    final mode = _isDesktop ? PlayerMode.mediaPlayer : PlayerMode.lowLatency;
    await player.stop();
    if (playbackRate != 1.0) {
      await player.setPlaybackRate(playbackRate);
    }
    await player.play(AssetSource(asset), mode: mode);
  }

  void dispose() {
    for (final p in _players) {
      p.dispose();
    }
  }
}

/// Manages all game audio: background music loop and one-shot SFX.
class AudioService extends ChangeNotifier {
  // Background music player (loops continuously)
  final AudioPlayer _bgmPlayer = AudioPlayer();

  // SFX pools allow overlapping sounds
  final _SfxPool _rollerSfxPool = _SfxPool(size: 4, volume: 0.6);
  final _SfxPool _roundCompleteSfxPool = _SfxPool(size: 3, volume: 0.7);

  bool _musicEnabled = false;
  bool _sfxEnabled = true;
  bool _hapticEnabled = true;
  bool _bgmStarted = false;

  bool get musicEnabled => _musicEnabled;
  bool get sfxEnabled => _sfxEnabled;
  bool get hapticEnabled => _hapticEnabled;

  AudioService() {
    _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    _bgmPlayer.setVolume(0.3);

    // Configure BGM audio context on Android
    if (!kIsWeb && Platform.isAndroid) {
      _bgmPlayer.setAudioContext(AudioContext(
        android: AudioContextAndroid(
          usageType: AndroidUsageType.game,
          contentType: AndroidContentType.music,
          audioFocus: AndroidAudioFocus.gainTransientMayDuck,
        ),
      ));
    }

    loadPrefs();
  }

  /// Load persisted audio/haptic preferences from SharedPreferences.
  Future<void> loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _musicEnabled = prefs.getBool('audio_musicEnabled') ?? false;
    _sfxEnabled = prefs.getBool('audio_sfxEnabled') ?? true;
    _hapticEnabled = prefs.getBool('audio_hapticEnabled') ?? true;
    if (_musicEnabled) startBgm();
    notifyListeners();
  }

  /// Save current audio/haptic preferences to SharedPreferences.
  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('audio_musicEnabled', _musicEnabled);
    await prefs.setBool('audio_sfxEnabled', _sfxEnabled);
    await prefs.setBool('audio_hapticEnabled', _hapticEnabled);
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
      await _rollerSfxPool.play('sfx/rollersweepup.mp3');
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
      await _roundCompleteSfxPool.play(
        'sfx/roundcomplete_cashregister.mp3',
        playbackRate: rate,
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
    _savePrefs();
    notifyListeners();
  }

  /// Toggle SFX on/off.
  void toggleSfx() {
    _sfxEnabled = !_sfxEnabled;
    _savePrefs();
    notifyListeners();
  }

  /// Toggle haptic feedback on/off.
  void toggleHaptic() {
    _hapticEnabled = !_hapticEnabled;
    _savePrefs();
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
    _rollerSfxPool.dispose();
    _roundCompleteSfxPool.dispose();
    super.dispose();
  }
}
