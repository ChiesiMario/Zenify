import 'package:zenify/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:zenify/providers/app_providers.dart';
import 'package:zenify/components/albums_grid.dart';
import 'package:zenify/providers/audio_provider.dart';

import 'package:zenify/providers/sort_providers.dart';
import 'dart:math';
import 'package:zenify/utils/responsive.dart';

class FavoriteAlbumsScreen extends ConsumerWidget {
  const FavoriteAlbumsScreen({super.key});

  List<dynamic> _sortAlbums(List<dynamic> albums, AlbumSortOption option, int randomSeed) {
    final list = List<dynamic>.from(albums);
    switch (option) {
      case AlbumSortOption.nameAsc:
        list.sort((a, b) => (a['title'] ?? a['name'] ?? '').toString().toLowerCase().compareTo((b['title'] ?? b['name'] ?? '').toString().toLowerCase()));
        break;
      case AlbumSortOption.nameDesc:
        list.sort((a, b) => (b['title'] ?? b['name'] ?? '').toString().toLowerCase().compareTo((a['title'] ?? a['name'] ?? '').toString().toLowerCase()));
        break;
      case AlbumSortOption.yearDesc:
        list.sort((a, b) => (b['year'] ?? 0).compareTo(a['year'] ?? 0));
        break;
      case AlbumSortOption.yearAsc:
        list.sort((a, b) => (a['year'] ?? 0).compareTo(b['year'] ?? 0));
        break;
      case AlbumSortOption.random:
        list.shuffle(Random(randomSeed));
        break;
      case AlbumSortOption.defaultOrder:
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final activeServer = ref.watch(activeServerProvider);
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;
    final sortOption = ref.watch(albumSortProvider);

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: activeServer.when(
        data: (server) {
          if (server == null) {
            return Center(
              child: Text(l10n.serverNotConnectedHint, style: TextStyle(color: colorScheme.mutedForeground)),
            );
          }

          final favoritesAsync = ref.watch(favoritesProvider);
          return favoritesAsync.when(
            data: (favorites) {
              final rawAlbums = favorites['albums'] ?? [];
              final randomSeed = ref.read(albumSortProvider.notifier).randomSeed;
              final albums = _sortAlbums(rawAlbums, sortOption, randomSeed);

              if (albums.isEmpty) {
                return Center(child: Text(l10n.noFavoriteAlbums, style: TextStyle(color: colorScheme.mutedForeground)));
              }

              return ListView(
                padding: const EdgeInsets.symmetric(vertical: 24),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: getResponsiveMaxWidth(context)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Hero Sub Banner
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: colorScheme.card,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: colorScheme.border, width: 1.0),
                              ),
                              child: Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 16,
                                runSpacing: 16,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.favoriteAlbumsTitle,
                                        style: TextStyle(
                                          color: colorScheme.foreground,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        l10n.totalAlbumsCount(albums.length.toString()),
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
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(LucideIcons.shuffle, size: 15),
                                        const SizedBox(width: 6),
                                        Text(l10n.shufflePlayAnAlbum, style: const TextStyle(fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            AlbumsGrid(albums: albums.toList()),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 128),
                ],
              );
            },
            loading: () => Center(child: CircularProgressIndicator(color: colorScheme.foreground)),
            error: (err, stack) => Center(child: Text(l10n.loadFavoritesFailed(err.toString()), style: TextStyle(color: colorScheme.destructive))),
          );
        },
        loading: () => Center(child: CircularProgressIndicator(color: colorScheme.foreground)),
        error: (err, stack) => Center(child: Text(l10n.loadServerStatusFailed, style: TextStyle(color: colorScheme.destructive))),
      ),
    );
  }
}
