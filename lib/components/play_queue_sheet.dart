import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:zenify/providers/audio_provider.dart';

class PlayQueueSheet extends ConsumerWidget {
  const PlayQueueSheet({super.key});

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;
    final audioState = ref.watch(audioProvider);
    final audioNotifier = ref.read(audioProvider.notifier);

    final queue = audioState.queue;
    final currentIndex = audioState.currentIndex;

    return Container(
      padding: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: colorScheme.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: colorScheme.mutedForeground.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 16),
          // Title
          Text(
            '播放隊列',
            style: TextStyle(
              color: colorScheme.foreground,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Divider(color: colorScheme.border),
          // Queue list
          Flexible(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shrinkWrap: true,
              itemCount: queue.length,
              itemBuilder: (context, index) {
                final song = queue[index];
                final isCurrent = index == currentIndex;
                final duration = song['duration'] != null ? _formatDuration(song['duration']) : '--:--';

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  tileColor: isCurrent ? colorScheme.primary.withOpacity(0.1) : null,
                  leading: isCurrent
                      ? Icon(LucideIcons.playCircle, color: colorScheme.primary)
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: colorScheme.mutedForeground,
                            fontSize: 16,
                          ),
                        ),
                  title: Text(
                    song['title'] ?? '未知歌曲',
                    style: TextStyle(
                      color: isCurrent ? colorScheme.primary : colorScheme.foreground,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    song['artist'] ?? '未知藝術家',
                    style: TextStyle(
                      color: isCurrent ? colorScheme.primary.withOpacity(0.8) : colorScheme.mutedForeground,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    duration,
                    style: TextStyle(
                      color: isCurrent ? colorScheme.primary : colorScheme.mutedForeground,
                      fontSize: 12,
                    ),
                  ),
                  onTap: () {
                    audioNotifier.playQueue(queue, index);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
