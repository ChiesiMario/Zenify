import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenify/providers/app_providers.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:zenify/components/local_cover_image.dart';
import 'package:zenify/screens/artist_detail_screen.dart';


class ArtistsView extends ConsumerWidget {
  const ArtistsView({super.key});

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

        final artistsAsync = ref.watch(artistsProvider);
        return artistsAsync.when(
          data: (artists) {
            if (artists.isEmpty) {
              return Center(child: Text('沒有找到藝術家', style: TextStyle(color: colorScheme.mutedForeground)));
            }

            return Column(
              children: [

                Expanded(
                  child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4, // Change depending on screen width
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: artists.length,
              itemBuilder: (context, index) {
                final artist = artists[index];
                
                // Get cover art URL if available
                final api = ref.watch(subsonicApiProvider);
                final coverUrl = api != null && artist['coverArt'] != null
                    ? api.getCoverArtUrl(artist['coverArt'])
                    : null;

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ArtistDetailScreen(
                          artistId: artist['id'],
                          artistName: artist['name'] ?? '未知藝術家',
                          coverUrl: coverUrl,
                        ),
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: colorScheme.muted,
                            shape: BoxShape.circle,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: coverUrl == null
                              ? Center(child: Icon(LucideIcons.user, color: colorScheme.mutedForeground, size: 40))
                              : LocalCoverImage(
                                  id: artist['coverArt'],
                                  serverId: server.id,
                                  fallbackUrl: coverUrl,
                                  isThumb: true,
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        artist['name'] ?? '未知藝術家',
                        style: TextStyle(color: colorScheme.foreground, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
                ),
              ],
            );
          },
          loading: () => Center(child: CircularProgressIndicator(color: colorScheme.foreground)),
          error: (err, stack) => Center(child: Text('加載藝術家失敗: $err', style: TextStyle(color: colorScheme.destructive))),
        );
      },
      loading: () => Center(child: CircularProgressIndicator(color: colorScheme.foreground)),
      error: (err, stack) => Center(child: Text('加載伺服器狀態失敗', style: TextStyle(color: colorScheme.destructive))),
    );
  }
}
