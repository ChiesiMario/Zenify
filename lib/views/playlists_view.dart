import 'package:zenify/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:zenify/utils/responsive.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:zenify/providers/app_providers.dart';
import 'package:zenify/router/app_router.dart';

import 'package:zenify/providers/sort_providers.dart';
import 'dart:math';

final playlistsProvider = FutureProvider<List<dynamic>>((ref) async {
  final networkState = ref.watch(networkProvider);
  if (networkState.isOffline) {
    final serverAsyncValue = ref.read(activeServerProvider);
    if (!serverAsyncValue.hasValue || serverAsyncValue.value == null) {
      return [];
    }
    final db = ref.read(databaseProvider);
    final cachedPlaylists = await db.getPlaylists(serverAsyncValue.value!.id);
    
    List<dynamic> result = [];
    for (var p in cachedPlaylists) {
      try {
        result.add(jsonDecode(p.rawData));
      } catch (_) {}
    }
    return result;
  }

  final api = ref.watch(subsonicApiProvider);
  if (api == null) return [];
  return await api.getPlaylists();
});

class PlaylistsView extends ConsumerWidget {
  const PlaylistsView({super.key});

  List<dynamic> _sortPlaylists(List<dynamic> playlists, AlbumSortOption option, int randomSeed) {
    final list = List<dynamic>.from(playlists);
    switch (option) {
      case AlbumSortOption.nameAsc:
        list.sort((a, b) => (a['name'] ?? '').toString().toLowerCase().compareTo((b['name'] ?? '').toString().toLowerCase()));
        break;
      case AlbumSortOption.nameDesc:
        list.sort((a, b) => (b['name'] ?? '').toString().toLowerCase().compareTo((a['name'] ?? '').toString().toLowerCase()));
        break;
      case AlbumSortOption.random:
        list.shuffle(Random(randomSeed));
        break;
      case AlbumSortOption.defaultOrder:
      default:
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;
    final playlistsAsync = ref.watch(playlistsProvider);
    final sortOption = ref.watch(albumSortProvider);

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: playlistsAsync.when(
        data: (rawPlaylists) {
          final randomSeed = ref.read(albumSortProvider.notifier).randomSeed;
          final playlists = _sortPlaylists(rawPlaylists, sortOption, randomSeed);
          if (playlists.isEmpty) {
            return Center(
              child: Text(l10n.noPlaylistsCurrently, style: TextStyle(color: colorScheme.mutedForeground)),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(playlistsProvider),
            child: ListView(
              padding: const EdgeInsets.only(top: 24, bottom: 128),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: getResponsiveMaxWidth(context)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Hero Banner
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: colorScheme.card,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: colorScheme.border, width: 1.0),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.navPlaylists,
                                  style: TextStyle(
                                    color: colorScheme.foreground,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  l10n.totalPlaylistsCount(playlists.length.toString()),
                                  style: TextStyle(color: colorScheme.mutedForeground, fontSize: 13),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Playlist Group Container
                          Container(
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: colorScheme.card,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: colorScheme.border, width: 1.0),
                            ),
                            child: Column(
                              children: playlists.asMap().entries.map((entry) {
                                final index = entry.key;
                                final playlist = entry.value;
                                final title = playlist['name'] ?? 'Unknown Playlist';
                                final songCount = playlist['songCount'] ?? 0;
                                final duration = playlist['duration'] ?? 0;
                                final durationMinutes = duration ~/ 60;
                                final isLast = index == playlists.length - 1;

                                return Container(
                                  decoration: BoxDecoration(
                                    border: isLast
                                        ? null
                                        : Border(
                                            bottom: BorderSide(
                                              color: colorScheme.border.withValues(alpha: 0.5),
                                              width: 0.5,
                                            ),
                                          ),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.vertical(
                                      top: index == 0 ? const Radius.circular(12) : Radius.zero,
                                      bottom: isLast ? const Radius.circular(12) : Radius.zero,
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: ListTile(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(
                                          top: index == 0 ? const Radius.circular(12) : Radius.zero,
                                          bottom: isLast ? const Radius.circular(12) : Radius.zero,
                                        ),
                                      ),
                                      leading: Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: colorScheme.muted,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(LucideIcons.listMusic, size: 20, color: colorScheme.foreground),
                                      ),
                                      title: Text(
                                        title,
                                        style: TextStyle(
                                          color: colorScheme.foreground,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      subtitle: Text(
                                        l10n.songsCountAndDuration(songCount.toString(), durationMinutes.toString()),
                                        style: TextStyle(color: colorScheme.mutedForeground, fontSize: 12),
                                      ),
                                      trailing: Icon(
                                        LucideIcons.arrowUpRight,
                                        size: 16,
                                        color: colorScheme.mutedForeground,
                                      ),
                                      onTap: () {
                                        context.pushBranch('playlist/${playlist['id']}', extra: title);
                                      },
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text(l10n.loadFailedErr(err.toString()), style: TextStyle(color: colorScheme.destructive)),
        ),
      ),
    );
  }
}
