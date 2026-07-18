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

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        border: Border(
          top: BorderSide(color: Color(0xFF2C2C2C), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Album Art Placeholder or Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2C),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(LucideIcons.music, color: Colors.white54),
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
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  currentSong['artist'] ?? '未知藝術家',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
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
                return const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: 24, height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
                );
              } else if (playing != true) {
                return IconButton(
                  icon: const Icon(LucideIcons.play, color: Colors.white),
                  onPressed: player.play,
                );
              } else {
                return IconButton(
                  icon: const Icon(LucideIcons.pause, color: Colors.white),
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
