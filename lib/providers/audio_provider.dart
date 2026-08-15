import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:zenify/models/downloaded_track.dart';
import 'package:zenify/providers/app_providers.dart';
import 'package:zenify/providers/download_provider.dart';
import 'package:zenify/providers/theme_provider.dart';
import 'package:zenify/services/path_service.dart';
import 'package:zenify/services/audio_cache_proxy.dart';
import 'package:zenify/api/subsonic_api.dart';
import 'package:path/path.dart' as p;
import 'dart:math' as math;

class ReplayGainEnabledNotifier extends Notifier<bool> {
  static const _key = 'replay_gain_enabled';

  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool(_key) ?? true;
  }

  void toggle() {
    final newValue = !state;
    state = newValue;
    ref.read(sharedPreferencesProvider).setBool(_key, newValue);
  }
}

final replayGainEnabledProvider = NotifierProvider<ReplayGainEnabledNotifier, bool>(() {
  return ReplayGainEnabledNotifier();
});

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
      debugPrint('Failed to decode saved queue: $e');
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
        final networkState = ref.read(networkProvider);
        bool isPlayable = true;
        Set<String> downloadedIds = {};

        if (networkState.isOffline) {
          final downloadedTracks = ref.read(downloadedTracksProvider).value ?? [];
          downloadedIds = downloadedTracks.map((t) => t.songId).toSet();
          isPlayable = downloadedIds.contains(state.queue[state.currentIndex]['id']?.toString());
        }

        if (isPlayable) {
          await _playIndex(state.currentIndex, autoPlay: false, startPosition: Duration(milliseconds: position));
        } else {
          int nextIndex = state.currentIndex + 1;
          bool foundPlayable = false;

          while (nextIndex < state.queue.length) {
            if (downloadedIds.contains(state.queue[nextIndex]['id']?.toString())) {
              foundPlayable = true;
              break;
            }
            nextIndex++;
          }
          
          if (!foundPlayable && state.repeatMode == AudioRepeatMode.all) {
            nextIndex = 0;
            while (nextIndex <= state.currentIndex) {
              if (downloadedIds.contains(state.queue[nextIndex]['id']?.toString())) {
                foundPlayable = true;
                break;
              }
              nextIndex++;
            }
          }

          if (foundPlayable) {
            await _playIndex(nextIndex, autoPlay: false);
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to restore playback state: $e');
    }
  }

  void _init() {
    _player.playerStateStream.listen((playerState) {
      state = state.copyWith(
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
          state = AudioState(); // 什麼都不做，清空播放狀態
        }
      }
    });

    _player.durationStream.listen((dur) {
      if (dur != null) {
        state = state.copyWith(duration: dur);
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

    int lastPositionSave = 0;
    _player.positionStream.listen((pos) {
      state = state.copyWith(position: pos);
      
      final dur = state.duration;
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - lastPositionSave > 2000) {
        lastPositionSave = now;
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
    final networkState = ref.read(networkProvider);
    List<dynamic> playableSongs = songs;
    int playableIndex = initialIndex;

    if (networkState.isOffline) {
      final downloadedTracks = ref.read(downloadedTracksProvider).value ?? [];
      final downloadedIds = downloadedTracks.map((t) => t.songId).toSet();
      
      final targetSongId = (initialIndex >= 0 && initialIndex < songs.length) ? songs[initialIndex]['id'] : null;
      
      playableSongs = songs.where((s) => downloadedIds.contains(s['id']?.toString())).toList();
      if (playableSongs.isEmpty) return; // Nothing to play
      
      if (targetSongId != null) {
        playableIndex = playableSongs.indexWhere((s) => s['id'] == targetSongId);
        if (playableIndex == -1) playableIndex = 0;
      }
    }

    final prefs = ref.read(sharedPreferencesProvider);
    final isShuffled = prefs.getBool('audio_is_shuffled') ?? false;

    if (isShuffled && playableSongs.isNotEmpty) {
      final initialSong = playableSongs[playableIndex];
      final remaining = List<dynamic>.from(playableSongs);
      remaining.removeAt(playableIndex);
      remaining.shuffle();
      
      final newQueue = [initialSong, ...remaining];
      
      state = state.copyWith(
        queue: newQueue,
        originalQueue: playableSongs,
        isShuffled: true,
      );
      await _playIndex(0);
    } else {
      state = state.copyWith(
        queue: playableSongs,
        originalQueue: playableSongs,
        isShuffled: false,
      );
      _saveQueueState();
      await _playIndex(playableIndex);
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
      state = state.copyWith(currentIndex: index);
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
        final cacheDir = await PathService.getOfflineDir();
        final localPath = p.join(cacheDir.path, '${song['id']}.mp3');

        final proxyUrl = AudioCacheProxy().getProxyUrl(url, song['id'].toString());
        audioSource = AudioSource.uri(
          Uri.parse(proxyUrl),
          tag: mediaItem,
        );
        _isCachingCurrentSong = true;

        AudioCacheProxy().getDownloadProgress(song['id'].toString()).listen((progress) async {
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
                
                // Enforce cache limit
                final cacheLimit = ref.read(cacheLimitProvider);
                await db.enforceCacheLimit(cacheLimit);
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
      
      // Apply ReplayGain
      final isReplayGainEnabled = ref.read(replayGainEnabledProvider);
      double targetVolume = 1.0;
      if (isReplayGainEnabled && song['replayGain'] != null) {
        final replayGain = song['replayGain'];
        final trackGain = replayGain['trackGain'] as num?;
        final albumGain = replayGain['albumGain'] as num?;
        final fallbackGain = replayGain['fallbackGain'] as num?;
        
        final gain = trackGain ?? albumGain ?? fallbackGain;
        if (gain != null) {
          targetVolume = math.pow(10, gain / 20).toDouble();
        }
      }
      await _player.setVolume(targetVolume);
      
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
      
      _preloadNextSongs();
    } catch (e) {
      debugPrint('AudioPlayer Error in _playIndex: $e');
    }
  }

  Future<void> _preloadNextSongs() async {
    final networkState = ref.read(networkProvider);
    if (networkState.isOffline) return;

    final db = ref.read(databaseProvider);
    final activeServer = await db.getActiveServer();
    if (activeServer == null) return;
    
    int checkedCount = 0;
    int nextIndex = state.currentIndex + 1;
    
    while (checkedCount < 2 && state.queue.isNotEmpty) {
      if (nextIndex >= state.queue.length) {
        if (state.repeatMode == AudioRepeatMode.all) {
          nextIndex = 0;
        } else {
          break; // End of queue
        }
      }
      
      // Prevent infinite loop in very small queues
      if (nextIndex == state.currentIndex) break;
      
      final song = state.queue[nextIndex];
      final songId = song['id']?.toString();
      
      if (songId != null) {
        final track = await db.getDownloadedTrack(songId);
        if (track == null || !track.isComplete || !File(track.localPath).existsSync()) {
          // Trigger download in background (cache mode)
          ref.read(downloadServiceProvider).downloadSong(song, activeServer.id, isManual: false).catchError((e) {
            debugPrint('Preload error for song $songId: $e');
          });
        }
      }
      
      checkedCount++;
      nextIndex++;
    }
  }

  Future<void> play() async => await _player.play();
  Future<void> pause() async => await _player.pause();
  Future<void> stop() async => await _player.stop();
  Future<void> seek(Duration position) async => await _player.seek(position);
  
  Future<void> reloadCurrentTrack() async {
    if (state.currentIndex >= 0 && state.currentIndex < state.queue.length) {
      final currentPos = state.position;
      await _playIndex(state.currentIndex, autoPlay: false, startPosition: currentPos);
    }
  }
  
  Future<void> disposePlayer() async {
    await _player.dispose();
  }
  
  Future<void> skipToNext() async {
    final networkState = ref.read(networkProvider);
    Set<String> downloadedIds = {};
    if (networkState.isOffline) {
      final downloadedTracks = ref.read(downloadedTracksProvider).value ?? [];
      downloadedIds = downloadedTracks.map((t) => t.songId).toSet();
    }

    int nextIndex = state.currentIndex + 1;
    bool foundPlayable = false;

    while (nextIndex < state.queue.length) {
      if (!networkState.isOffline || downloadedIds.contains(state.queue[nextIndex]['id']?.toString())) {
        foundPlayable = true;
        break;
      }
      nextIndex++;
    }

    if (!foundPlayable) {
      if (state.repeatMode == AudioRepeatMode.all) {
        nextIndex = 0;
        while (nextIndex <= state.currentIndex) {
          if (!networkState.isOffline || downloadedIds.contains(state.queue[nextIndex]['id']?.toString())) {
            foundPlayable = true;
            break;
          }
          nextIndex++;
        }
      }
    }

    if (foundPlayable) {
      await _playIndex(nextIndex);
    } else {
      await _player.stop();
    }
  }

  Future<void> skipToPrevious() async {
    if (state.position.inSeconds > 3) {
      await _player.seek(Duration.zero);
      return;
    }

    final networkState = ref.read(networkProvider);
    Set<String> downloadedIds = {};
    if (networkState.isOffline) {
      final downloadedTracks = ref.read(downloadedTracksProvider).value ?? [];
      downloadedIds = downloadedTracks.map((t) => t.songId).toSet();
    }

    int prevIndex = state.currentIndex - 1;
    bool foundPlayable = false;

    while (prevIndex >= 0) {
      if (!networkState.isOffline || downloadedIds.contains(state.queue[prevIndex]['id']?.toString())) {
        foundPlayable = true;
        break;
      }
      prevIndex--;
    }

    if (!foundPlayable) {
      if (state.repeatMode == AudioRepeatMode.all) {
        prevIndex = state.queue.length - 1;
        while (prevIndex > state.currentIndex) {
          if (!networkState.isOffline || downloadedIds.contains(state.queue[prevIndex]['id']?.toString())) {
            foundPlayable = true;
            break;
          }
          prevIndex--;
        }
      }
    }

    if (foundPlayable) {
      await _playIndex(prevIndex);
    } else {
      await _player.seek(Duration.zero);
    }
  }

  void toggleRepeat() {
    AudioRepeatMode nextMode;
    switch (state.repeatMode) {
      case AudioRepeatMode.off: nextMode = AudioRepeatMode.all; break;
      case AudioRepeatMode.all: nextMode = AudioRepeatMode.one; break;
      case AudioRepeatMode.one: nextMode = AudioRepeatMode.off; break;
    }
    state = state.copyWith(repeatMode: nextMode);
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
      state = state.copyWith(
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

      state = state.copyWith(
        isShuffled: true,
        originalQueue: original,
        queue: newQueue,
        currentIndex: currentSong != null ? 0 : (newQueue.isNotEmpty ? 0 : -1),
      );
      prefs.setBool('audio_is_shuffled', true);
      _saveQueueState();
    }
  }

  void reorderQueue(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final currentList = List<dynamic>.from(state.queue);
    final item = currentList.removeAt(oldIndex);
    currentList.insert(newIndex, item);

    int newCurrentIndex = state.currentIndex;
    if (state.currentIndex == oldIndex) {
      newCurrentIndex = newIndex;
    } else if (oldIndex < state.currentIndex && newIndex >= state.currentIndex) {
      newCurrentIndex -= 1;
    } else if (oldIndex > state.currentIndex && newIndex <= state.currentIndex) {
      newCurrentIndex += 1;
    }

    state = state.copyWith(
      queue: currentList,
      currentIndex: newCurrentIndex,
    );
    _saveQueueState();
  }

  void removeFromQueue(int index) {
    if (index < 0 || index >= state.queue.length) return;
    final currentList = List<dynamic>.from(state.queue);
    currentList.removeAt(index);
    
    int newCurrentIndex = state.currentIndex;
    if (index < state.currentIndex) {
      newCurrentIndex -= 1;
    } else if (index == state.currentIndex) {
      if (currentList.isEmpty) {
        newCurrentIndex = -1;
        _player.stop();
      } else {
        if (newCurrentIndex >= currentList.length) {
          newCurrentIndex = 0;
        }
        _playIndex(newCurrentIndex);
      }
    }

    state = state.copyWith(
      queue: currentList,
      currentIndex: newCurrentIndex,
    );
    _saveQueueState();
  }

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await pause();
    } else {
      await play();
    }
  }

  void addToQueue(dynamic song) {
    final currentList = List<dynamic>.from(state.queue);
    currentList.add(song);
    
    final currentOriginal = List<dynamic>.from(state.originalQueue);
    currentOriginal.add(song);

    state = state.copyWith(
      queue: currentList,
      originalQueue: currentOriginal,
      currentIndex: state.currentIndex == -1 ? 0 : state.currentIndex,
    );
    _saveQueueState();
  }

  void playNext(dynamic song) {
    final currentList = List<dynamic>.from(state.queue);
    final currentOriginal = List<dynamic>.from(state.originalQueue);
    
    int newIndex = state.currentIndex + 1;
    if (state.currentIndex >= 0 && state.currentIndex < currentList.length) {
      currentList.insert(newIndex, song);
      
      // Attempt to insert right after the current song in originalQueue too
      final currentSong = state.currentSong;
      if (currentSong != null) {
        int origIndex = currentOriginal.indexWhere((s) => s['id'] == currentSong['id']);
        if (origIndex != -1) {
          currentOriginal.insert(origIndex + 1, song);
        } else {
          currentOriginal.add(song);
        }
      } else {
        currentOriginal.add(song);
      }
    } else {
      currentList.add(song);
      currentOriginal.add(song);
    }
    
    state = state.copyWith(
      queue: currentList,
      originalQueue: currentOriginal,
      currentIndex: state.currentIndex == -1 ? 0 : state.currentIndex,
    );
    _saveQueueState();
  }
}

final audioProvider = NotifierProvider<AudioNotifier, AudioState>(() {
  return AudioNotifier();
});
