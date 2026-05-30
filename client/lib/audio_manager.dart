import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioManager {
  final AudioPlayer _movePlayer = AudioPlayer();
  final AudioPlayer _winPlayer = AudioPlayer();
  bool _soundEnabled = true;
  static const _soundKey = 'sound_enabled';

  AudioManager() {
    _initAudio();
  }

  bool get soundEnabled => _soundEnabled;

  Future<void> _initAudio() async {
    // Load sound preference
    final prefs = await SharedPreferences.getInstance();
    _soundEnabled = prefs.getBool(_soundKey) ?? true;

    try {
      await _movePlayer.setAsset('assets/sounds/move.wav');
      await _winPlayer.setAsset('assets/sounds/win.wav');
    } catch (e) {
      // Audio assets may not exist in dev
    }
  }

  Future<void> toggleSound() async {
    _soundEnabled = !_soundEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundKey, _soundEnabled);
  }

  Future<void> playMoveSound() async {
    if (!_soundEnabled) return;
    try {
      await _movePlayer.seek(Duration.zero);
      await _movePlayer.play();
    } catch (_) {}
  }

  Future<void> playWinSound() async {
    if (!_soundEnabled) return;
    try {
      await _winPlayer.seek(Duration.zero);
      await _winPlayer.play();
    } catch (_) {}
  }

  void dispose() {
    _movePlayer.dispose();
    _winPlayer.dispose();
  }
}
