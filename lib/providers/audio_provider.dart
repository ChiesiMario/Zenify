import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:path_provider/path_provider.dart';
import 'package:zenify/models/downloaded_track.dart';
import 'package:zenify/providers/app_providers.dart';
import 'package:zenify/providers/download_provider.dart';
import 'package:zenify/utils/zenify_caching_audio_source.dart';

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
  bool _hasScrobbledCurrent = false;
  bool _isCachingCurrentSong = false;

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
      
      final dur = state.duration;
      if (dur.inMilliseconds > 0 && pos.inMilliseconds > dur.inMilliseconds / 2) {
        if (!_hasScrobbledCurrent && state.currentSong != null) {
          _hasScrobbledCurrent = true;
          final api = ref.read(subsonicApiProvider);
          if (api != null) {
            api.scrobble(id: state.currentSong['id'].toString(), submission: true);
          }
        }
      }
    });

    _player.durationStream.listen((dur) {
      if (dur != null) {
        this.state = this.state.copyWith(duration: dur);
      }
    });

    _player.bufferedPositionStream.listen((bufferedPosition) async {
      if (_isCachingCurrentSong) {
        final dur = state.duration;
        // If buffered position is very close to or exceeds duration
        if (dur.inMilliseconds > 0 && bufferedPosition.inMilliseconds >= dur.inMilliseconds - 200) {
          _isCachingCurrentSong = false;
          final current = state.currentSong;
          if (current != null) {
            final songId = current['id'].toString();
            final db = ref.read(databaseProvider);
            final track = await db.getDownloadedTrack(songId);
            if (track != null && !track.isComplete) {
              track.isComplete = true;
              try {
                track.sizeBytes = File(track.localPath).lengthSync();
              } catch (_) {}
              await db.saveDownloadedTrack(track);
            }
          }
        }
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

      // Check if downloaded
      final db = ref.read(databaseProvider);
      final downloadedTrack = await db.getDownloadedTrack(song['id'].toString());
      
      AudioSource audioSource;
      _isCachingCurrentSong = false;
      
      if (downloadedTrack != null && downloadedTrack.isComplete && File(downloadedTrack.localPath).existsSync()) {
        audioSource = AudioSource.file(
          downloadedTrack.localPath,
          tag: mediaItem,
        );
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final downloadDir = Directory('${dir.path}/zenify_downloads');
        if (!downloadDir.existsSync()) {
          downloadDir.createSync(recursive: true);
        }
        final localPath = '${downloadDir.path}/${song['id']}.mp3';

        final zenifySource = ZenifyCachingAudioSource(
          Uri.parse(url),
          cacheFile: File(localPath),
          tag: mediaItem,
        );
        audioSource = zenifySource;
        _isCachingCurrentSong = true;

        zenifySource.downloadProgressStream.listen((progress) async {
          if (progress >= 1.0) {
             final db = ref.read(databaseProvider);
             final dt = await db.getDownloadedTrack(song['id'].toString());
             if (dt != null && !dt.isComplete) {
                dt.isComplete = true;
                final file = File(dt.localPath);
                if (file.existsSync()) {
                  dt.sizeBytes = file.lengthSync();
                }
                await db.saveDownloadedTrack(dt);
                ref.invalidate(downloadedTracksProvider);
             }
          }
        });

        if (downloadedTrack == null) {
          final server = await db.getActiveServer();
          final serverId = server?.id ?? 0;
          
          final track = DownloadedTrack()
            ..songId = song['id'].toString()
            ..serverId = serverId
            ..title = song['title'] ?? 'Unknown'
            ..artist = song['artist'] ?? 'Unknown'
            ..album = song['album']
            ..albumId = song['albumId']?.toString()
            ..coverArt = song['coverArt']
            ..duration = song['duration'] ?? 0
            ..localPath = localPath
            ..sizeBytes = 0
            ..downloadedAt = DateTime.now()
            ..rawData = jsonEncode(song)
            ..isComplete = false;

          await db.saveDownloadedTrack(track);
        } else if (!downloadedTrack.isComplete) {
          downloadedTrack.downloadedAt = DateTime.now();
          await db.saveDownloadedTrack(downloadedTrack);
        }
      }

      await _player.setAudioSource(audioSource);
      
      // Send Now Playing scrobble
      _hasScrobbledCurrent = false;
      api.scrobble(id: song['id'].toString(), submission: false);
      
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
