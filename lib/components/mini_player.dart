import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:zenify/providers/audio_provider.dart';
import 'package:zenify/providers/app_providers.dart';
import 'package:zenify/screens/full_player_screen.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(audioProvider);
    final audioNotifier = ref.read(audioProvider.notifier);
    final api = ref.watch(subsonicApiProvider);
    final currentSong = audioState.currentSong;

    if (currentSong == null) {
      return const SizedBox.shrink(); // Don't show if nothing is playing
    }

    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;
    
    final coverUrl = api != null && currentSong['coverArt'] != null
        ? api.getCoverArtUrl(currentSong['coverArt'])
        : null;

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent, // Important for solid color filling correctly without artifacts
          builder: (context) => const FullPlayerScreen(),
        );
      },
      child: Container(
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
                image: coverUrl != null ? DecorationImage(image: NetworkImage(coverUrl), fit: BoxFit.cover) : null,
              ),
              child: coverUrl == null ? Icon(LucideIcons.music, color: colorScheme.mutedForeground) : null,
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
            if (audioState.isBuffering)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  width: 24, height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.foreground),
                ),
              )
            else
              IconButton(
                icon: Icon(audioState.isPlaying ? LucideIcons.pause : LucideIcons.play, color: colorScheme.foreground),
                onPressed: () => audioNotifier.togglePlayPause(),
              ),
            IconButton(
              icon: Icon(LucideIcons.skipForward, color: colorScheme.foreground),
              onPressed: () => audioNotifier.skipToNext(),
            ),
          ],
        ),
      ),
    );
  }
}
