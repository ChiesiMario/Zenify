import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenify/providers/app_providers.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:zenify/screens/album_detail_screen.dart';
import 'package:zenify/components/local_cover_image.dart';

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

                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                const double fixedItemWidth = 150.0;
                const double spacing = 32.0;
                
                // Calculate how many columns can fit with fixed width and spacing
                int crossAxisCount = (constraints.maxWidth - 32) ~/ (fixedItemWidth + spacing);
                if (crossAxisCount < 2) crossAxisCount = 2; // At least 2 columns
                
                final double totalSpacing = spacing * (crossAxisCount - 1) + 64; // 64 is for padding (32*2)
                final double cellWidth = (constraints.maxWidth - totalSpacing) / crossAxisCount;
                
                // The cell height will exactly fit the 150px image + 48px text
                const double cellHeight = fixedItemWidth + 48.0; 
                final double childAspectRatio = cellWidth / cellHeight;

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
                      child: Center(
                        child: SizedBox(
                          width: fixedItemWidth,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: fixedItemWidth,
                                height: fixedItemWidth,
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
                        ),
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
