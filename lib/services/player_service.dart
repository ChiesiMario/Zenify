import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

final playerServiceProvider = Provider<PlayerService>((ref) {
  final service = PlayerService();
  ref.onDispose(() => service.dispose());
  return service;
});

class PlayerService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  AudioPlayer get player => _audioPlayer;
  
  Map<String, dynamic>? currentSong;
  
  Future<void> playSong(String streamUrl, Map<String, dynamic> songData) async {
    currentSong = songData;
    try {
      await _audioPlayer.setUrl(streamUrl);
      _audioPlayer.play();
    } catch (e) {
      // Handle playback error
    }
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }
  
  Future<void> resume() async {
    await _audioPlayer.play();
  }
  
  void dispose() {
    _audioPlayer.dispose();
  }
}
