import 'package:zenify/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:zenify/components/albums_grid.dart';
import 'package:zenify/providers/app_providers.dart';

class AlbumView extends ConsumerWidget {
  const AlbumView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final activeServer = ref.watch(activeServerProvider);
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;

    return activeServer.when(
      data: (server) {
        if (server == null) {
          return Center(
            child: Text(l10n.serverNotConnectedHint, style: TextStyle(color: colorScheme.mutedForeground)),
          );
        }

        final albumsAsync = ref.watch(albumsProvider);
        return albumsAsync.when(
          data: (state) {
            if (state.albums.isEmpty) {
              return Center(child: Text(l10n.noAlbumsFound, style: TextStyle(color: colorScheme.mutedForeground)));
            }

            return AlbumsGrid(
              albums: state.albums,
              shrinkWrap: false,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 128),
              isHome: true,
              totalCount: state.totalCount,
              isLoadingMore: state.isLoadingMore,
              onLoadMore: () {
                ref.read(albumsProvider.notifier).loadMore();
              },
            );
          },
          loading: () => Center(child: CircularProgressIndicator(color: colorScheme.foreground)),
          error: (err, stack) => Center(child: Text(l10n.loadAlbumsFailed(err.toString()), style: TextStyle(color: colorScheme.destructive))),
        );
      },
      loading: () => Center(child: CircularProgressIndicator(color: colorScheme.foreground)),
      error: (err, stack) => Center(child: Text(l10n.loadServerStatusFailed, style: TextStyle(color: colorScheme.destructive))),
    );
  }
}
