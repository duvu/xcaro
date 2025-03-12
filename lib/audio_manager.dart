import 'package:just_audio/just_audio.dart';

class AudioManager {
  final AudioPlayer _movePlayer = AudioPlayer();
  final AudioPlayer _winPlayer = AudioPlayer();

  AudioManager() {
    _initAudio();
  }

  Future<void> _initAudio() async {
    try {
      await _movePlayer.setAsset('assets/sounds/move.wav');
      await _winPlayer.setAsset('assets/sounds/win.wav');
    } catch (e) {
      print('Error initializing audio: $e');
    }
  }

  Future<void> playMoveSound() async {
    try {
      await _movePlayer.seek(Duration.zero);
      await _movePlayer.play();
    } catch (e) {
      print('Error playing move sound: $e');
    }
  }

  Future<void> playWinSound() async {
    try {
      await _winPlayer.seek(Duration.zero);
      await _winPlayer.play();
    } catch (e) {
      print('Error playing win sound: $e');
    }
  }

  void dispose() {
    _movePlayer.dispose();
    _winPlayer.dispose();
  }
}
