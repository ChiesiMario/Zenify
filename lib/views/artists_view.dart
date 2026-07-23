import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenify/providers/app_providers.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:zenify/screens/artist_detail_screen.dart';
import 'package:zenify/components/artist_card.dart';


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
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                const double fixedItemWidth = 100.0;
                const double spacing = 32.0;
                
                // Calculate how many columns can fit with fixed width and spacing
                int crossAxisCount = (constraints.maxWidth - 32) ~/ (fixedItemWidth + spacing);
                if (crossAxisCount < 2) crossAxisCount = 2; // At least 2 columns
                
                final double totalSpacing = spacing * (crossAxisCount - 1) + 64; // 64 is for padding (32*2)
                final double cellWidth = (constraints.maxWidth - totalSpacing) / crossAxisCount;
                
                // The cell height will exactly fit the 100px image + 32px text
                const double cellHeight = fixedItemWidth + 32.0; 
                final double childAspectRatio = cellWidth / cellHeight;

                return GridView.builder(
                  padding: const EdgeInsets.all(32.0),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: spacing,
                    mainAxisSpacing: spacing,
                    childAspectRatio: childAspectRatio,
                  ),
                  itemCount: artists.length,
                  itemBuilder: (context, index) {
                    final artist = artists[index];
                    
                    // Get cover art URL if available
                    final api = ref.watch(subsonicApiProvider);
                    final coverUrl = api != null && artist['coverArt'] != null
                        ? api.getCoverArtUrl(artist['coverArt'])
                        : null;

                    return Center(
                      child: ArtistCard(
                        name: artist['name'] ?? '未知藝術家',
                        artistId: artist['id'],
                        coverArtId: artist['coverArt'],
                        fallbackCoverUrl: coverUrl,
                        serverId: server.id,
                        width: fixedItemWidth,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              settings: RouteSettings(name: artist['name'] ?? '未知藝術家'),
                              builder: (context) => ArtistDetailScreen(
                                artistId: artist['id'],
                                artistName: artist['name'] ?? '未知藝術家',
                                coverUrl: coverUrl,
                              ),
                            ),
                          );
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
          error: (err, stack) => Center(child: Text('加載藝術家失敗: $err', style: TextStyle(color: colorScheme.destructive))),
        );
      },
      loading: () => Center(child: CircularProgressIndicator(color: colorScheme.foreground)),
      error: (err, stack) => Center(child: Text('加載伺服器狀態失敗', style: TextStyle(color: colorScheme.destructive))),
    );
  }
}
