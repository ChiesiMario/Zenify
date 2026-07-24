import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:path_provider/path_provider.dart';
import 'package:zenify/models/downloaded_track.dart';
import 'package:zenify/providers/app_providers.dart';
import 'package:zenify/providers/download_provider.dart';
import 'package:zenify/providers/theme_provider.dart';
import 'package:zenify/utils/zenify_caching_audio_source.dart';
import 'package:zenify/api/subsonic_api.dart';

enum AudioRepeatMode { off, all, one }

class AudioState {
  final List<dynamic> queue;
  final List<dynamic> originalQueue;
  final int currentIndex;
  final bool isPlaying;
  final bool isBuffering;
  final Duration position;
  final Duration duration;
  final bool isShuffled;
  final AudioRepeatMode repeatMode;

  AudioState({
    this.queue = const [],
    this.originalQueue = const [],
    this.currentIndex = -1,
    this.isPlaying = false,
    this.isBuffering = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.isShuffled = false,
    this.repeatMode = AudioRepeatMode.off,
  });

  dynamic get currentSong => (currentIndex >= 0 && currentIndex < queue.length) ? queue[currentIndex] : null;

  AudioState copyWith({
    List<dynamic>? queue,
    List<dynamic>? originalQueue,
    int? currentIndex,
    bool? isPlaying,
    bool? isBuffering,
    Duration? position,
    Duration? duration,
    bool? isShuffled,
    AudioRepeatMode? repeatMode,
  }) {
    return AudioState(
      queue: queue ?? this.queue,
      originalQueue: originalQueue ?? this.originalQueue,
      currentIndex: currentIndex ?? this.currentIndex,
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      isShuffled: isShuffled ?? this.isShuffled,
      repeatMode: repeatMode ?? this.repeatMode,
    );
  }
}

class AudioNotifier extends Notifier<AudioState> {
  final AudioPlayer _player = AudioPlayer();
  bool _hasScrobbledCurrent = false;
  bool _isCachingCurrentSong = false;

  @override
  AudioState build() {
    ref.onDispose(() {
      _player.dispose();
    });

    final prefs = ref.watch(sharedPreferencesProvider);
    final savedShuffle = prefs.getBool('audio_is_shuffled') ?? false;
    final savedRepeat = prefs.getInt('audio_repeat_mode') ?? 0;
    
    AudioRepeatMode repeatMode = AudioRepeatMode.off;
    if (savedRepeat >= 0 && savedRepeat < AudioRepeatMode.values.length) {
      repeatMode = AudioRepeatMode.values[savedRepeat];
    }
    
    List<dynamic> queue = [];
    List<dynamic> originalQueue = [];
    int currentIndex = prefs.getInt('audio_current_index') ?? -1;

    try {
      final qStr = prefs.getString('audio_queue');
      if (qStr != null) {
        queue = jsonDecode(qStr) as List<dynamic>;
      }
      final oqStr = prefs.getString('audio_original_queue');
      if (oqStr != null) {
        originalQueue = jsonDecode(oqStr) as List<dynamic>;
      }
    } catch (e) {
      print('Failed to decode saved queue: $e');
    }
    
    // Ensure index is valid
    if (currentIndex >= queue.length) currentIndex = -1;

    final initialState = AudioState(
      queue: queue,
      originalQueue: originalQueue,
      currentIndex: currentIndex,
      isShuffled: savedShuffle,
      repeatMode: repeatMode,
    );

    Future.microtask(() {
      _init();
    });

    return initialState;
  }

  void _saveQueueState() {
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setString('audio_queue', jsonEncode(state.queue));
    prefs.setString('audio_original_queue', jsonEncode(state.originalQueue));
    prefs.setInt('audio_current_index', state.currentIndex);
  }

  Future<void> _restorePlaybackState() async {
    // Delay loading to avoid resource contention on slow cold boot
    await Future.delayed(const Duration(milliseconds: 1500));
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final position = prefs.getInt('audio_position') ?? 0;
      if (state.currentIndex >= 0 && state.currentIndex < state.queue.length) {
        // Load the track but do not auto-play
        await _playIndex(state.currentIndex, autoPlay: false, startPosition: Duration(milliseconds: position));
      }
    } catch (e) {
      print('Failed to restore playback state: $e');
    }
  }

  void _init() {
    _player.playerStateStream.listen((playerState) {
      this.state = this.state.copyWith(
        isPlaying: playerState.playing,
        isBuffering: playerState.processingState == ProcessingState.buffering || playerState.processingState == ProcessingState.loading,
      );

      if (playerState.processingState == ProcessingState.completed) {
        if (state.repeatMode == AudioRepeatMode.one) {
          _player.seek(Duration.zero);
          _player.play();
        } else if (state.currentIndex >= 0 && state.currentIndex < state.queue.length - 1) {
          skipToNext();
        } else if (state.repeatMode == AudioRepeatMode.all && state.queue.isNotEmpty) {
          _playIndex(0);
        } else {
          _player.stop();
          this.state = AudioState(); // 什麼都不做，清空播放狀態
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
        final current = state.currentSong;
        if (current != null) {
          final songId = current['id'].toString();
          final db = ref.read(databaseProvider);
          final track = await db.getDownloadedTrack(songId);
          if (track != null) {
            try {
              final file = File(track.localPath);
              if (file.existsSync()) {
                final currentLength = file.lengthSync();
                final dur = state.duration;
                final isNearEnd = dur.inMilliseconds > 0 && bufferedPosition.inMilliseconds >= dur.inMilliseconds - 200;
                
                if (currentLength != track.sizeBytes || (isNearEnd && !track.isComplete)) {
                  track.sizeBytes = currentLength;
                  if (isNearEnd) {
                    track.isComplete = true;
                    _isCachingCurrentSong = false;
                  }
                  await db.saveDownloadedTrack(track);
                  ref.invalidate(downloadedTracksProvider);
                }
              }
            } catch (_) {}
          }
        }
      }
    });

    int _lastPositionSave = 0;
    _player.positionStream.listen((pos) {
      this.state = this.state.copyWith(position: pos);
      
      final dur = state.duration;
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - _lastPositionSave > 2000) {
        _lastPositionSave = now;
        ref.read(sharedPreferencesProvider).setInt('audio_position', pos.inMilliseconds);
      }

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

    _restorePlaybackState();
  }

  Future<void> playQueue(List<dynamic> songs, int initialIndex) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final isShuffled = prefs.getBool('audio_is_shuffled') ?? false;

    if (isShuffled && songs.isNotEmpty) {
      final initialSong = songs[initialIndex];
      final remaining = List<dynamic>.from(songs);
      remaining.removeAt(initialIndex);
      remaining.shuffle();
      
      final newQueue = [initialSong, ...remaining];
      
      this.state = this.state.copyWith(
        queue: newQueue,
        originalQueue: songs,
        isShuffled: true,
      );
      await _playIndex(0);
    } else {
      this.state = this.state.copyWith(
        queue: songs,
        originalQueue: songs,
        isShuffled: false,
      );
      _saveQueueState();
      await _playIndex(initialIndex);
    }
  }

  Future<void> _playIndex(int index, {bool autoPlay = true, Duration? startPosition}) async {
    if (index < 0 || index >= state.queue.length) return;
    
    try {
      SubsonicApi? api = ref.read(subsonicApiProvider);
      if (api == null) {
        final server = await ref.read(activeServerProvider.future);
        if (server == null) return;
        api = SubsonicApi(server);
      }
      this.state = this.state.copyWith(currentIndex: index);
      _saveQueueState();
      
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
            ..isComplete = false
            ..isManualDownload = false;

          await db.saveDownloadedTrack(track);
        } else if (!downloadedTrack.isComplete) {
          downloadedTrack.downloadedAt = DateTime.now();
          await db.saveDownloadedTrack(downloadedTrack);
        }
      }

      await _player.setAudioSource(audioSource);
      
      // Send Now Playing scrobble
      if (autoPlay) {
        _hasScrobbledCurrent = false;
        api.scrobble(id: song['id'].toString(), submission: false);
      }
      
      if (startPosition != null) {
        await _player.seek(startPosition);
      }
      
      if (autoPlay) {
        _player.play();
      }
    } catch (e) {
      print('AudioPlayer Error in _playIndex: $e');
    }
  }

  Future<void> play() async => await _player.play();
  Future<void> pause() async => await _player.pause();
  Future<void> seek(Duration position) async => await _player.seek(position);
  
  Future<void> disposePlayer() async {
    await _player.dispose();
  }
  
  Future<void> skipToNext() async {
    if (state.currentIndex >= state.queue.length - 1) {
      if (state.repeatMode == AudioRepeatMode.all) {
        await _playIndex(0);
      }
    } else {
      await _playIndex(state.currentIndex + 1);
    }
  }

  Future<void> skipToPrevious() async {
    if (state.position.inSeconds > 3) {
      await _player.seek(Duration.zero);
    } else {
      if (state.currentIndex == 0 && state.repeatMode == AudioRepeatMode.all) {
        await _playIndex(state.queue.length - 1);
      } else if (state.currentIndex > 0) {
        await _playIndex(state.currentIndex - 1);
      }
    }
  }

  void toggleRepeat() {
    AudioRepeatMode nextMode;
    switch (state.repeatMode) {
      case AudioRepeatMode.off: nextMode = AudioRepeatMode.all; break;
      case AudioRepeatMode.all: nextMode = AudioRepeatMode.one; break;
      case AudioRepeatMode.one: nextMode = AudioRepeatMode.off; break;
    }
    this.state = this.state.copyWith(repeatMode: nextMode);
    ref.read(sharedPreferencesProvider).setInt('audio_repeat_mode', nextMode.index);
  }

  void toggleShuffle() {
    final prefs = ref.read(sharedPreferencesProvider);
    if (state.isShuffled) {
      // Turn off shuffle
      final currentSong = state.currentSong;
      final original = List<dynamic>.from(state.originalQueue);
      int newIndex = -1;
      if (currentSong != null) {
        newIndex = original.indexWhere((s) => s['id'] == currentSong['id']);
      }
      this.state = this.state.copyWith(
        isShuffled: false,
        queue: original,
        currentIndex: newIndex != -1 ? newIndex : 0,
      );
      prefs.setBool('audio_is_shuffled', false);
      _saveQueueState();
    } else {
      // Turn on shuffle
      final currentSong = state.currentSong;
      final original = state.queue.isEmpty ? <dynamic>[] : List<dynamic>.from(state.queue);
      final remaining = List<dynamic>.from(original);
      
      if (currentSong != null) {
        remaining.removeWhere((s) => s['id'] == currentSong['id']);
      }
      remaining.shuffle();
      
      final newQueue = <dynamic>[];
      if (currentSong != null) {
        newQueue.add(currentSong);
      }
      newQueue.addAll(remaining);

      this.state = this.state.copyWith(
        isShuffled: true,
        originalQueue: original,
        queue: newQueue,
        currentIndex: currentSong != null ? 0 : (newQueue.isNotEmpty ? 0 : -1),
      );
      prefs.setBool('audio_is_shuffled', true);
      _saveQueueState();
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
