import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenify/providers/app_providers.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

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
              return Center(child: Text('沒有找到專輯', style: TextStyle(color: colorScheme.mutedForeground)));
            }

            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // Change depending on screen width
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: albums.length,
              itemBuilder: (context, index) {
                final album = albums[index];
                
                // Get cover art URL
                final api = ref.watch(subsonicApiProvider);
                final coverUrl = api != null && album['coverArt'] != null
                    ? '${api.server.url}/rest/getCoverArt?id=${album['coverArt']}&u=${api.server.username}&t=${api.getAuthParams()['t']}&s=${api.getAuthParams()['s']}&v=1.16.1&c=Zenify'
                    : null; // Normally we'd use a cleaner method in api client, but this works for demo.

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: colorScheme.muted,
                          borderRadius: BorderRadius.circular(8),
                          image: coverUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(coverUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: coverUrl == null
                            ? Center(child: Icon(LucideIcons.music, color: colorScheme.mutedForeground, size: 40))
                            : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      album['name'] ?? '未知專輯',
                      style: TextStyle(color: colorScheme.foreground, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      album['artist'] ?? '未知藝術家',
                      style: TextStyle(color: colorScheme.mutedForeground, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                );
              },
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
