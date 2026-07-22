import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenify/providers/app_providers.dart';
import 'package:zenify/providers/audio_provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:zenify/screens/album_detail_screen.dart';
import 'package:zenify/screens/artist_detail_screen.dart';
import 'package:zenify/components/album_card.dart';

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
                      const double cardPadding = 10.0;
                      const double cardTotalWidth = fixedItemWidth + (cardPadding * 2);
                      const double spacing = 16.0;
                      
                      // Calculate how many columns can fit
                      int crossAxisCount = (constraints.maxWidth - 32) ~/ (cardTotalWidth + spacing);
                      if (crossAxisCount < 2) crossAxisCount = 2; // At least 2 columns
                      
                      final double totalSpacing = spacing * (crossAxisCount - 1) + 64; // 64 is for padding (32*2)
                      final double cellWidth = (constraints.maxWidth - totalSpacing) / crossAxisCount;
                      
                      // Total card height = cover height (150) + text & spacing & padding (80) = 230.0
                      const double cellHeight = fixedItemWidth + 80.0; 
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

                          return Center(
                            child: AlbumCard(
                              title: album['name'] ?? '未知專輯',
                              artist: album['artist'] ?? '未知藝術家',
                              coverArtId: album['coverArt'],
                              fallbackCoverUrl: coverUrl,
                              serverId: server.id,
                              width: fixedItemWidth,
                              padding: cardPadding,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AlbumDetailScreen(albumId: album['id']),
                                  ),
                                );
                              },
                              onPlayTap: () async {
                                final subsonicApi = ref.read(subsonicApiProvider);
                                if (subsonicApi != null) {
                                  final detail = await subsonicApi.getAlbum(album['id']);
                                  if (detail != null && detail['song'] != null) {
                                    var songs = detail['song'];
                                    if (songs is! List) songs = [songs];
                                    ref.read(audioProvider.notifier).playQueue(List<dynamic>.from(songs), 0);
                                  }
                                }
                              },
                              onArtistTap: () async {
                                String? artistId = album['artistId'];
                                if (artistId == null) {
                                  final api = ref.read(subsonicApiProvider);
                                  if (api != null) {
                                    final detail = await api.getAlbum(album['id']);
                                    if (detail != null && detail['artistId'] != null) {
                                      artistId = detail['artistId'];
                                    }
                                  }
                                }
                                if (artistId != null && context.mounted) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ArtistDetailScreen(
                                        artistId: artistId!,
                                        artistName: album['artist'] ?? '未知藝術家',
                                      ),
                                    ),
                                  );
                                }
                              },
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
