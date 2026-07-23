import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:zenify/providers/app_providers.dart';
import 'package:zenify/screens/album_detail_screen.dart';
import 'package:zenify/components/album_card.dart';

class FavoriteAlbumsScreen extends ConsumerWidget {
  const FavoriteAlbumsScreen({super.key});

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
              final albums = favorites['albums'] ?? [];

              if (albums.isEmpty) {
                return Center(child: Text('目前沒有任何喜愛的專輯', style: TextStyle(color: colorScheme.mutedForeground)));
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  const double cardWidth = 140.0;
                  const double cardPadding = 8.0;
                  const double cardTotalWidth = cardWidth + (cardPadding * 2);
                  const double spacing = 16.0;
                  
                  int crossAxisCount = (constraints.maxWidth - 32) ~/ (cardTotalWidth + spacing);
                  if (crossAxisCount < 2) crossAxisCount = 2;
                  
                  final double totalHorizontalSpacing = spacing * (crossAxisCount - 1) + 32;
                  final double cellWidth = (constraints.maxWidth - totalHorizontalSpacing) / crossAxisCount;
                  
                  const double fixedCellHeight = 194.0;
                  final double childAspectRatio = cellWidth / fixedCellHeight;

                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: spacing,
                      mainAxisSpacing: 12.0,
                      childAspectRatio: childAspectRatio,
                    ),
                    itemCount: albums.length,
                    itemBuilder: (context, index) {
                      final album = albums[index];
                      final api = ref.watch(subsonicApiProvider);
                      final coverUrl = api != null && album['coverArt'] != null
                          ? api.getCoverArtUrl(album['coverArt'])
                          : null;

                      return AlbumCard(
                        title: album['title'] ?? album['name'] ?? 'Unknown Album',
                        artist: album['artist'] ?? 'Unknown Artist',
                        coverArtId: album['coverArt'],
                        fallbackCoverUrl: coverUrl,
                        serverId: server.id,
                        width: 140,
                        padding: 8,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              settings: RouteSettings(name: album['title'] ?? album['name'] ?? '專輯詳情'),
                              builder: (context) => AlbumDetailScreen(
                                albumId: album['id'].toString(),
                              ),
                            ),
                          );
                        },
                      );
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
      ),
    );
  }
}
