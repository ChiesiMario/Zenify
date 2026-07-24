import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:zenify/providers/app_providers.dart';
import 'package:zenify/providers/audio_provider.dart';
import 'package:zenify/components/local_cover_image.dart';

class FavoriteSongsScreen extends ConsumerWidget {
  const FavoriteSongsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeServer = ref.watch(activeServerProvider);
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: activeServer.when(
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

              if (songs.isEmpty) {
                return Center(child: Text('目前沒有任何喜愛的歌曲', style: TextStyle(color: colorScheme.mutedForeground)));
              }

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: CustomScrollView(
                    slivers: [
                      // Padding for top spacing
                      const SliverPadding(padding: EdgeInsets.only(top: 24)),
                      
                      // Hero Sub-Banner
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverToBoxAdapter(
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: colorScheme.card,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: colorScheme.border, width: 1.0),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '最愛的歌曲',
                                      style: TextStyle(
                                        color: colorScheme.foreground,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '共 ${songs.length} 首歌曲',
                                      style: TextStyle(color: colorScheme.mutedForeground, fontSize: 13),
                                    ),
                                  ],
                                ),
                                ShadButton(
                                  onPressed: () {
                                    final shuffled = List<dynamic>.from(songs)..shuffle();
                                    ref.read(audioProvider.notifier).playQueue(shuffled, 0);
                                  },
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(LucideIcons.shuffle, size: 15),
                                      SizedBox(width: 6),
                                      Text('隨機播放', style: TextStyle(fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      // Spacing between banner and list
                      const SliverPadding(padding: EdgeInsets.only(top: 20)),

                      // Lazy loaded group card list with outer border
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: DecoratedSliver(
                          decoration: BoxDecoration(
                            color: colorScheme.card,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: colorScheme.border, width: 1.0),
                          ),
                          sliver: SliverList.builder(
                            itemCount: songs.length,
                            itemBuilder: (context, songIndex) {
                              final song = songs[songIndex];
                              final api = ref.watch(subsonicApiProvider);
                              final coverUrl = api != null && song['coverArt'] != null
                                  ? api.getCoverArtUrl(song['coverArt'])
                                  : null;
                                  
                              final isFirst = songIndex == 0;
                              final isLast = songIndex == songs.length - 1;

                              return Container(
                                decoration: BoxDecoration(
                                  border: isLast
                                      ? null
                                      : Border(
                                          bottom: BorderSide(
                                            color: colorScheme.border.withValues(alpha: 0.5),
                                            width: 0.5,
                                          ),
                                        ),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.vertical(
                                    top: isFirst ? const Radius.circular(12) : Radius.zero,
                                    bottom: isLast ? const Radius.circular(12) : Radius.zero,
                                  ),
                                  clipBehavior: Clip.antiAlias, // Ensures child ink/bg respects the corner radius
                                  child: ListTile(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                        top: isFirst ? const Radius.circular(12) : Radius.zero,
                                        bottom: isLast ? const Radius.circular(12) : Radius.zero,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                    leading: Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: colorScheme.muted,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: coverUrl == null
                                          ? Icon(LucideIcons.music, size: 20, color: colorScheme.mutedForeground)
                                          : LocalCoverImage(
                                              id: song['coverArt'],
                                              serverId: server.id,
                                              fallbackUrl: coverUrl,
                                            ),
                                    ),
                                    title: Text(
                                      song['title'] ?? '未知歌曲',
                                      style: TextStyle(
                                        color: colorScheme.foreground,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      song['artist'] ?? '未知藝術家',
                                      style: TextStyle(color: colorScheme.mutedForeground, fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: Icon(LucideIcons.heart, size: 16, color: colorScheme.primary),
                                    onTap: () {
                                      ref.read(audioProvider.notifier).playQueue(songs, songIndex);
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      
                      // Bottom padding
                      const SliverPadding(padding: EdgeInsets.only(bottom: 128)),
                    ],
                  ),
                ),
              );
            },
            loading: () => Center(child: CircularProgressIndicator(color: colorScheme.foreground)),
            error: (err, stack) => Center(child: Text('加載喜愛項目失敗: $err', style: TextStyle(color: colorScheme.destructive))),
          );
        },
        loading: () => Center(child: CircularProgressIndicator(color: colorScheme.foreground)),
        error: (err, stack) => Center(child: Text('加載伺服器狀態失敗', style: TextStyle(color: colorScheme.destructive))),
      ),
    );
  }
}
