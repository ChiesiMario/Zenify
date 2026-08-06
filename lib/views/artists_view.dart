import 'package:zenify/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenify/providers/app_providers.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:zenify/components/artists_grid.dart';

class ArtistsView extends ConsumerWidget {
  const ArtistsView({super.key});

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

        final artistsAsync = ref.watch(artistsProvider);
        return artistsAsync.when(
          data: (state) {
            if (state.artists.isEmpty) {
              return Center(child: Text(l10n.noArtistsFound, style: TextStyle(color: colorScheme.mutedForeground)));
            }

            return ArtistsGrid(
              artists: state.artists,
              shrinkWrap: false,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 128),
              totalCount: state.totalCount,
              isLoadingMore: state.isLoadingMore,
              onLoadMore: () {
                ref.read(artistsProvider.notifier).loadMore();
              },
            );
          },
          loading: () => Center(child: CircularProgressIndicator(color: colorScheme.foreground)),
          error: (err, stack) => Center(child: Text(l10n.loadArtistsFailed(err.toString()), style: TextStyle(color: colorScheme.destructive))),
        );
      },
      loading: () => Center(child: CircularProgressIndicator(color: colorScheme.foreground)),
      error: (err, stack) => Center(child: Text(l10n.loadServerStatusFailed, style: TextStyle(color: colorScheme.destructive))),
    );
  }
}
