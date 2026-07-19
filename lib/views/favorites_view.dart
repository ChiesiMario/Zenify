import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenify/providers/app_providers.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:zenify/providers/audio_provider.dart';
import 'package:zenify/components/local_cover_image.dart';

class FavoritesView extends ConsumerWidget {
  const FavoritesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeServer = ref.watch(activeServerProvider);
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;

    return activeServer.when(
      data: (server) {
        if (server == null) {
          return Center(
            child: Text('未連接伺服器，請先在右上角新增', style: TextStyle(color: colorScheme.mutedForeground)),
          );
        }

        final favoritesAsync = ref.watch(favoritesProvider);
        return favoritesAsync.when(
          data: (favorites) {
            final songs = favorites['songs'] ?? [];
            final albums = favorites['albums'] ?? [];
            final artists = favorites['artists'] ?? [];

            if (songs.isEmpty && albums.isEmpty && artists.isEmpty) {
              return Center(child: Text('目前沒有任何喜愛的項目', style: TextStyle(color: colorScheme.mutedForeground)));
            }

            // Simple implementation: display a list of all favorite songs
            if (songs.isEmpty) {
               return Center(child: Text('沒有喜愛的歌曲（目前僅顯示歌曲）', style: TextStyle(color: colorScheme.mutedForeground)));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: songs.length,
              itemBuilder: (context, index) {
                final song = songs[index];
                
                final api = ref.watch(subsonicApiProvider);
                final coverUrl = api != null && song['coverArt'] != null
                    ? api.getCoverArtUrl(song['coverArt'])
                    : null;

                return ListTile(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colorScheme.muted,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: coverUrl == null
                        ? Icon(LucideIcons.music, color: colorScheme.mutedForeground)
                        : LocalCoverImage(
                            id: song['coverArt'],
                            serverId: server.id,
                            fallbackUrl: coverUrl,
                          ),
                  ),
                  title: Text(
                    song['title'] ?? '未知歌曲',
                    style: TextStyle(color: colorScheme.foreground, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    song['artist'] ?? '未知藝術家',
                    style: TextStyle(color: colorScheme.mutedForeground),
                  ),
                  trailing: Icon(LucideIcons.heart, color: colorScheme.primary),
                  onTap: () {
                    ref.read(audioProvider.notifier).playQueue(songs, index);
                  },
                );
              },
            );
          },
          loading: () => Center(child: CircularProgressIndicator(color: colorScheme.foreground)),
          error: (err, stack) => Center(child: Text('加載喜愛項目失敗: $err', style: TextStyle(color: colorScheme.destructive))),
        );
      },
      loading: () => Center(child: CircularProgressIndicator(color: colorScheme.foreground)),
      error: (err, stack) => Center(child: Text('加載伺服器狀態失敗', style: TextStyle(color: colorScheme.destructive))),
    );
  }
}
