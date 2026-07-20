import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenify/providers/app_providers.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:zenify/screens/album_detail_screen.dart';
import 'package:zenify/components/local_cover_image.dart';
import 'package:zenify/providers/sort_providers.dart';
class AlbumView extends ConsumerWidget {
  const AlbumView({super.key});

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

        final albumsAsync = ref.watch(albumsProvider);
        return albumsAsync.when(
          data: (albums) {
            if (albums.isEmpty) {
              return Center(child: Text('沒有找到任何專輯', style: TextStyle(color: colorScheme.mutedForeground)));
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 16, 32, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ShadSelect<AlbumSortOption>(
                        placeholder: const Text('排序方式'),
                        initialValue: ref.read(albumSortProvider),
                        onChanged: (value) {
                          if (value != null) {
                            ref.read(albumSortProvider.notifier).state = value;
                          }
                        },
                        options: [
                          const ShadOption(value: AlbumSortOption.defaultOrder, child: Text('預設排序')),
                          const ShadOption(value: AlbumSortOption.nameAsc, child: Text('名稱 (A-Z)')),
                          const ShadOption(value: AlbumSortOption.nameDesc, child: Text('名稱 (Z-A)')),
                          const ShadOption(value: AlbumSortOption.yearDesc, child: Text('年份 (新到舊)')),
                          const ShadOption(value: AlbumSortOption.yearAsc, child: Text('年份 (舊到新)')),
                          const ShadOption(value: AlbumSortOption.random, child: Text('隨機排列')),
                        ],
                        selectedOptionBuilder: (context, value) {
                          switch (value) {
                            case AlbumSortOption.nameAsc: return const Text('名稱 (A-Z)');
                            case AlbumSortOption.nameDesc: return const Text('名稱 (Z-A)');
                            case AlbumSortOption.yearDesc: return const Text('年份 (新到舊)');
                            case AlbumSortOption.yearAsc: return const Text('年份 (舊到新)');
                            case AlbumSortOption.random: return const Text('隨機排列');
                            default: return const Text('預設排序');
                          }
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                int crossAxisCount = (constraints.maxWidth / 150).floor();
                if (crossAxisCount < 2) crossAxisCount = 2;
                
                const double spacing = 32.0;
                final double totalSpacing = spacing * (crossAxisCount - 1) + spacing * 2;
                final double itemWidth = (constraints.maxWidth - totalSpacing) / crossAxisCount;
                
                // Image is square (itemWidth), text area takes ~48px
                final double itemHeight = itemWidth + 48.0; 
                final double childAspectRatio = itemWidth / itemHeight;

                return GridView.builder(
                  padding: const EdgeInsets.all(32.0),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: spacing,
                    mainAxisSpacing: spacing,
                    childAspectRatio: childAspectRatio,
                  ),
                  itemCount: albums.length,
                  itemBuilder: (context, index) {
                    final album = albums[index];
                    
                    final api = ref.watch(subsonicApiProvider);
                    final coverUrl = api != null && album['coverArt'] != null
                        ? api.getCoverArtUrl(album['coverArt'])
                        : null;

                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AlbumDetailScreen(albumId: album['id']),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AspectRatio(
                            aspectRatio: 1.0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: colorScheme.muted,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: coverUrl == null
                                  ? Center(child: Icon(LucideIcons.music, color: colorScheme.mutedForeground, size: 40))
                                  : LocalCoverImage(
                                      id: album['coverArt'],
                                      serverId: server.id,
                                      fallbackUrl: coverUrl,
                                    ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            album['name'] ?? '未知專輯',
                            style: TextStyle(color: colorScheme.foreground, fontWeight: FontWeight.bold, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.left,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            album['artist'] ?? '未知藝術家',
                            style: TextStyle(color: colorScheme.mutedForeground, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.left,
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      );
    },
          loading: () => Center(child: CircularProgressIndicator(color: colorScheme.foreground)),
          error: (err, stack) => Center(child: Text('加載專輯失敗: $err', style: TextStyle(color: colorScheme.destructive))),
        );
      },
      loading: () => Center(child: CircularProgressIndicator(color: colorScheme.foreground)),
      error: (err, stack) => Center(child: Text('加載伺服器狀態失敗', style: TextStyle(color: colorScheme.destructive))),
    );
  }
}
