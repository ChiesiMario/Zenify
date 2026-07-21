import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:zenify/providers/audio_provider.dart';
import 'package:zenify/providers/app_providers.dart';
import 'package:zenify/components/local_cover_image.dart';
import 'package:zenify/components/play_queue_sheet.dart';

class FullPlayerScreen extends ConsumerWidget {
  const FullPlayerScreen({super.key});

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(audioProvider);
    final audioNotifier = ref.read(audioProvider.notifier);
    final api = ref.watch(subsonicApiProvider);
    final server = ref.watch(activeServerProvider).value;
    final currentSong = audioState.currentSong;
    
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;

    if (currentSong == null) {
      return Container(
        color: colorScheme.background,
        child: const Center(child: Text('無播放中的歌曲')),
      );
    }

    final coverUrl = api != null && currentSong['coverArt'] != null
        ? api.getCoverArtUrl(currentSong['coverArt'], size: 800)
        : null;

    final position = audioState.position;
    final duration = audioState.duration;
    double sliderValue = duration.inMilliseconds > 0 
        ? position.inMilliseconds / duration.inMilliseconds 
        : 0.0;
    sliderValue = sliderValue.clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Top Drag Handle & Close Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: colorScheme.mutedForeground.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: Icon(LucideIcons.chevronDown, color: colorScheme.foreground),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Album Cover
                    Flexible(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            color: colorScheme.muted,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 30,
                                offset: const Offset(0, 15),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: coverUrl == null 
                              ? Center(child: Icon(LucideIcons.music, size: 80, color: colorScheme.mutedForeground))
                              : LocalCoverImage(
                                  id: currentSong['coverArt'],
                                  serverId: server?.id ?? 0,
                                  fallbackUrl: coverUrl,
                                  isThumb: false,
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                    
                    // Song Info
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentSong['title'] ?? '未知歌曲',
                            style: TextStyle(
                              color: colorScheme.foreground,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentSong['artist'] ?? '未知藝術家',
                            style: TextStyle(
                              color: colorScheme.mutedForeground,
                              fontSize: 18,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Progress Bar
                    Slider(
                      value: sliderValue,
                      min: 0.0,
                      max: 1.0,
                      activeColor: colorScheme.foreground,
                      inactiveColor: colorScheme.muted,
                      onChanged: (val) {
                        final newPos = Duration(milliseconds: (val * duration.inMilliseconds).round());
                        audioNotifier.seek(newPos);
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatDuration(position), style: TextStyle(color: colorScheme.mutedForeground, fontSize: 12)),
                        Text(_formatDuration(duration), style: TextStyle(color: colorScheme.mutedForeground, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 32),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: Icon(
                            LucideIcons.shuffle, 
                            color: audioState.isShuffled ? colorScheme.primary : colorScheme.mutedForeground
                          ),
                          onPressed: () => audioNotifier.toggleShuffle(),
                        ),
                        IconButton(
                          icon: Icon(LucideIcons.skipBack, color: colorScheme.foreground),
                          iconSize: 36,
                          onPressed: () => audioNotifier.skipToPrevious(),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorScheme.primary,
                          ),
                          child: IconButton(
                            icon: Icon(
                              audioState.isPlaying ? LucideIcons.pause : LucideIcons.play, 
                              color: colorScheme.primaryForeground
                            ),
                            iconSize: 48,
                            onPressed: () => audioNotifier.togglePlayPause(),
                          ),
                        ),
                        IconButton(
                          icon: Icon(LucideIcons.skipForward, color: colorScheme.foreground),
                          iconSize: 36,
                          onPressed: () => audioNotifier.skipToNext(),
                        ),
                        IconButton(
                          icon: Icon(
                            audioState.repeatMode == AudioRepeatMode.one 
                                ? LucideIcons.repeat1 
                                : LucideIcons.repeat,
                            color: audioState.repeatMode != AudioRepeatMode.off 
                                ? colorScheme.primary 
                                : colorScheme.mutedForeground,
                          ),
                          onPressed: () => audioNotifier.toggleRepeat(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: Icon(LucideIcons.listMusic, color: colorScheme.mutedForeground),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => FractionallySizedBox(
                                heightFactor: 0.8,
                                child: const PlayQueueSheet(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
