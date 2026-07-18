import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:zenify/services/player_service.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerService = ref.watch(playerServiceProvider);
    final player = playerService.player;
    final currentSong = playerService.currentSong;

    if (currentSong == null) {
      return const SizedBox.shrink(); // Don't show if nothing is playing
    }

    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.card, // Or background, using card gives slight distinction if they differ
        border: Border(
          top: BorderSide(color: colorScheme.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Album Art Placeholder or Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colorScheme.muted,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(LucideIcons.music, color: colorScheme.mutedForeground),
          ),
          const SizedBox(width: 12),
          // Song Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  currentSong['title'] ?? '未知歌曲',
                  style: TextStyle(color: colorScheme.foreground, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  currentSong['artist'] ?? '未知藝術家',
                  style: TextStyle(color: colorScheme.mutedForeground, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Controls
          StreamBuilder<PlayerState>(
            stream: player.playerStateStream,
            builder: (context, snapshot) {
              final playerState = snapshot.data;
              final processingState = playerState?.processingState;
              final playing = playerState?.playing;
              
              if (processingState == ProcessingState.loading || processingState == ProcessingState.buffering) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: 24, height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.foreground),
                  ),
                );
              } else if (playing != true) {
                return IconButton(
                  icon: Icon(LucideIcons.play, color: colorScheme.foreground),
                  onPressed: player.play,
                );
              } else {
                return IconButton(
                  icon: Icon(LucideIcons.pause, color: colorScheme.foreground),
                  onPressed: player.pause,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
