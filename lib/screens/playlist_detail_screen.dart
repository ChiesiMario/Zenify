import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:zenify/providers/app_providers.dart';
import 'package:zenify/providers/audio_provider.dart';
import 'package:zenify/components/local_cover_image.dart';

final playlistDetailProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, id) async {
  final api = ref.watch(subsonicApiProvider);
  if (api == null) return null;
  return await api.getPlaylist(id);
});

class PlaylistDetailScreen extends ConsumerWidget {
  final String playlistId;
  final String playlistName;

  const PlaylistDetailScreen({
    super.key,
    required this.playlistId,
    required this.playlistName,
  });

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;
    final playlistAsync = ref.watch(playlistDetailProvider(playlistId));
    final server = ref.watch(activeServerProvider).value;
    final api = ref.watch(subsonicApiProvider);

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: playlistAsync.when(
        data: (playlist) {
          if (playlist == null) {
            return const Center(child: Text('無法載入播放清單'));
          }

          var entryNode = playlist['entry'];
          List<dynamic> songs = [];
          if (entryNode != null) {
            if (entryNode is List) {
              songs = entryNode;
            } else {
              songs = [entryNode];
            }
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        playlistName,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${playlist['songCount'] ?? 0} 首歌曲',
                        style: TextStyle(color: colorScheme.mutedForeground),
                      ),
                      const SizedBox(height: 24),
                      if (songs.isNotEmpty)
                        ShadButton(
                          width: double.infinity,
                          child: const Text('播放全部'),
                          onPressed: () {
                            ref.read(audioProvider.notifier).playQueue(songs, 0);
                          },
                        ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
              if (songs.isEmpty)
                SliverToBoxAdapter(
                  child: Center(
                    child: Text('播放清單是空的', style: TextStyle(color: colorScheme.mutedForeground)),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final song = songs[index];
                      final coverId = song['coverArt'] ?? song['albumId'];
                      final fallbackUrl = api != null && coverId != null ? api.getCoverArtUrl(coverId, size: 250) : null;
                      final duration = _formatDuration(song['duration'] as int? ?? 0);

                      return ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: SizedBox(
                            width: 48,
                            height: 48,
                            child: LocalCoverImage(
                              id: coverId ?? '',
                              serverId: server?.id ?? 0,
                              fallbackUrl: fallbackUrl,
                              isThumb: true,
                            ),
                          ),
                        ),
                        title: Text(song['title'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w500)),
                        subtitle: Text(song['artist'] ?? '', style: TextStyle(color: colorScheme.mutedForeground)),
                        trailing: Text(duration, style: TextStyle(color: colorScheme.mutedForeground)),
                        onTap: () {
                          ref.read(audioProvider.notifier).playQueue(songs, index);
                        },
                      );
                    },
                    childCount: songs.length,
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('載入失敗: $err', style: TextStyle(color: colorScheme.destructive)),
        ),
      ),
    );
  }
}
