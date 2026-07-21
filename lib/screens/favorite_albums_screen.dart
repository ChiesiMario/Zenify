import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:zenify/providers/app_providers.dart';
import 'package:zenify/screens/album_detail_screen.dart';
import 'package:zenify/components/local_cover_image.dart';

class FavoriteAlbumsScreen extends ConsumerWidget {
  const FavoriteAlbumsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeServer = ref.watch(activeServerProvider);
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.background,
        title: const Text('專輯'),
      ),
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
              final albums = favorites['albums'] ?? [];

              if (albums.isEmpty) {
                return Center(child: Text('目前沒有任何喜愛的專輯', style: TextStyle(color: colorScheme.mutedForeground)));
              }

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: albums.length,
                itemBuilder: (context, index) {
                  final album = albums[index];
                  final api = ref.watch(subsonicApiProvider);
                  final coverUrl = api != null && album['coverArt'] != null
                      ? api.getCoverArtUrl(album['coverArt'])
                      : null;

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AlbumDetailScreen(
                            albumId: album['id'].toString(),
                          ),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AspectRatio(
                          aspectRatio: 1,
                          child: Container(
                            decoration: BoxDecoration(
                              color: colorScheme.muted,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            foregroundDecoration: BoxDecoration(
                              border: Border.all(color: colorScheme.border, width: 0.8),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: coverUrl == null
                                  ? Icon(LucideIcons.disc, size: 48, color: colorScheme.mutedForeground)
                                  : LocalCoverImage(
                                      id: album['coverArt'],
                                      serverId: server.id,
                                      fallbackUrl: coverUrl,
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          album['title'] ?? album['name'] ?? 'Unknown Album',
                          style: TextStyle(
                            color: colorScheme.foreground,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          album['artist'] ?? 'Unknown Artist',
                          style: TextStyle(
                            color: colorScheme.mutedForeground,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
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
      ),
    );
  }
}
