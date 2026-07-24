import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenify/providers/app_providers.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:zenify/components/artists_grid.dart';

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

            return ArtistsGrid(
              artists: artists.toList(),
              shrinkWrap: false,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 128),
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
