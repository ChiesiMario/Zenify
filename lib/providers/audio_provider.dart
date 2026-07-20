import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:zenify/providers/app_providers.dart';

class AudioState {
  final List<dynamic> queue;
  final int currentIndex;
  final bool isPlaying;
  final bool isBuffering;
  final Duration position;
  final Duration duration;

  AudioState({
    this.queue = const [],
    this.currentIndex = -1,
    this.isPlaying = false,
    this.isBuffering = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
  });

  dynamic get currentSong => (currentIndex >= 0 && currentIndex < queue.length) ? queue[currentIndex] : null;

  AudioState copyWith({
    List<dynamic>? queue,
    int? currentIndex,
    bool? isPlaying,
    bool? isBuffering,
    Duration? position,
    Duration? duration,
  }) {
    return AudioState(
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      position: position ?? this.position,
      duration: duration ?? this.duration,
    );
  }
}

class AudioNotifier extends Notifier<AudioState> {
  final AudioPlayer _player = AudioPlayer();

  @override
  AudioState build() {
    _init();
    ref.onDispose(() {
      _player.dispose();
    });
    return AudioState();
  }

  void _init() {
    _player.playerStateStream.listen((playerState) {
      this.state = this.state.copyWith(
        isPlaying: playerState.playing,
        isBuffering: playerState.processingState == ProcessingState.buffering || playerState.processingState == ProcessingState.loading,
      );

      if (playerState.processingState == ProcessingState.completed) {
        if (state.currentIndex >= 0 && state.currentIndex < state.queue.length - 1) {
          skipToNext();
        } else {
          _player.stop();
          this.state = AudioState(); // 什麼都不做，清空播放狀態
        }
      }
    });

    _player.positionStream.listen((pos) {
      this.state = this.state.copyWith(position: pos);
    });

    _player.durationStream.listen((dur) {
      if (dur != null) {
        this.state = this.state.copyWith(duration: dur);
      }
    });
  }

  Future<void> playQueue(List<dynamic> songs, int initialIndex) async {
    this.state = this.state.copyWith(
      queue: songs,
    );
    await _playIndex(initialIndex);
  }

  Future<void> _playIndex(int index) async {
    if (index < 0 || index >= state.queue.length) return;
    
    try {
      final api = ref.read(subsonicApiProvider);
      if (api == null) return;
      
      this.state = this.state.copyWith(currentIndex: index);
      final song = state.queue[index];
      final url = api.getStreamUrl(song['id'].toString());
      final coverId = song['coverArt'] ?? song['albumId'];
      final coverUrl = coverId != null ? api.getCoverArtUrl(coverId) : null;
      
      final mediaItem = MediaItem(
        id: song['id'].toString(),
        album: song['album']?.toString(),
        title: song['title']?.toString() ?? 'Unknown',
        artist: song['artist']?.toString(),
        artUri: coverUrl != null ? Uri.parse(coverUrl) : null,
      );

      await _player.setAudioSource(LockCachingAudioSource(
        Uri.parse(url),
        tag: mediaItem,
      ));
      _player.play();
    } catch (e) {
      print('AudioPlayer Error in _playIndex: $e');
    }
  }

  Future<void> play() async => await _player.play();
  Future<void> pause() async => await _player.pause();
  Future<void> seek(Duration position) async => await _player.seek(position);
  
  Future<void> skipToNext() async {
    await _playIndex(state.currentIndex + 1);
  }

  Future<void> skipToPrevious() async {
    if (state.position.inSeconds > 3) {
      await _player.seek(Duration.zero);
    } else {
      await _playIndex(state.currentIndex - 1);
    }
  }

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await pause();
    } else {
      await play();
    }
  }
}

final audioProvider = NotifierProvider<AudioNotifier, AudioState>(() {
  return AudioNotifier();
});
