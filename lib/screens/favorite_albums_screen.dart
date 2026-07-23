import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:zenify/providers/app_providers.dart';
import 'package:zenify/screens/album_detail_screen.dart';
import 'package:zenify/components/album_card.dart';
import 'package:zenify/providers/audio_provider.dart';

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

              return ListView(
                padding: const EdgeInsets.symmetric(vertical: 24),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Hero Sub Banner
                            Container(
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
                                        '收藏的專輯',
                                        style: TextStyle(
                                          color: colorScheme.foreground,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '共 ${albums.length} 張專輯',
                                        style: TextStyle(color: colorScheme.mutedForeground, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                  ShadButton(
                                    onPressed: () async {
                                      final api = ref.read(subsonicApiProvider);
                                      if (api != null && albums.isNotEmpty) {
                                        final randomAlbum = (albums.toList()..shuffle()).first;
                                        try {
                                          final albumData = await api.getAlbum(randomAlbum['id'].toString());
                                          final songs = albumData?['song'] ?? [];
                                          if (songs.isNotEmpty) {
                                            ref.read(audioProvider.notifier).playQueue(songs, 0);
                                          }
                                        } catch (e) {
                                          // Ignore play errors
                                        }
                                      }
                                    },
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(LucideIcons.shuffle, size: 15),
                                        SizedBox(width: 6),
                                        Text('隨機播放一張專輯', style: TextStyle(fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Album Cards Grid
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 160,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 16,
                                mainAxisExtent: 185,
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
                                  padding: 0,
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
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
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
