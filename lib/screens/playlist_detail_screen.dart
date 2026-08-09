import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:zenify/components/zenify_song_list.dart';
import 'package:zenify/l10n/app_localizations.dart';
import 'package:zenify/providers/app_providers.dart';
import 'package:zenify/providers/audio_provider.dart';
import 'package:zenify/providers/download_provider.dart';
import 'package:zenify/providers/sort_providers.dart';
import 'package:zenify/utils/responsive.dart';

final playlistDetailProvider = FutureProvider.autoDispose.family<Map<String, dynamic>?, String>((ref, id) async {
  final networkState = ref.watch(networkProvider);
  if (networkState.isOffline) {
    final serverAsyncValue = ref.read(activeServerProvider);
    if (!serverAsyncValue.hasValue || serverAsyncValue.value == null) {
      return null;
    }
    final db = ref.read(databaseProvider);
    final cachedPlaylist = await db.getPlaylist(serverAsyncValue.value!.id, id);
    if (cachedPlaylist != null) {
      try {
        return jsonDecode(cachedPlaylist.rawData);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  final api = ref.watch(subsonicApiProvider);
  if (api == null) return null;
  return await api.getPlaylist(id);
});

class PlaylistDetailScreen extends ConsumerWidget {
  final String playlistId;
  final String playlistName;

  const PlaylistDetailScreen({
    super.key,
    required this.playlistId,
    required this.playlistName,
  });

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  List<dynamic> _sortSongs(List<dynamic> tracks, SongSortOption option, int randomSeed) {
    final list = List<dynamic>.from(tracks);
    switch (option) {
      case SongSortOption.nameAsc:
        list.sort((a, b) => (a['title'] ?? '').toString().toLowerCase().compareTo((b['title'] ?? '').toString().toLowerCase()));
        break;
      case SongSortOption.nameDesc:
        list.sort((a, b) => (b['title'] ?? '').toString().toLowerCase().compareTo((a['title'] ?? '').toString().toLowerCase()));
        break;
      case SongSortOption.random:
        list.shuffle(Random(randomSeed));
        break;
      case SongSortOption.defaultOrder:
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
    final playlistAsync = ref.watch(playlistDetailProvider(playlistId));
    final server = ref.watch(activeServerProvider).value;
    final api = ref.watch(subsonicApiProvider);
    final networkState = ref.watch(networkProvider);
    final downloadedTracksAsync = ref.watch(downloadedTracksProvider);
    final downloadedTracks = downloadedTracksAsync.valueOrNull ?? [];
    final downloadedIds = downloadedTracks
        .where((t) => t.isComplete && File(t.localPath).existsSync())
        .map((t) => t.songId)
        .toSet();
    final sortOption = ref.watch(songSortProvider);
    final randomSeed = ref.read(songSortProvider.notifier).randomSeed;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: playlistAsync.when(
        data: (playlist) {
          if (playlist == null) {
            return Center(child: Text(l10n.cannotLoadPlaylist));
          }

          var entryNode = playlist['entry'];
          List<dynamic> songs = [];
          if (entryNode != null) {
            if (entryNode is List) {
              songs = entryNode;
            } else {
              songs = [entryNode];
            }
          }

          final sortedSongs = _sortSongs(songs, sortOption, randomSeed);

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: getResponsiveMaxWidth(context)),
              child: RefreshIndicator(
                onRefresh: () async => ref.refresh(playlistDetailProvider(playlistId)),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              playlistName,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l10n.playlistSongCount((playlist['songCount'] ?? songs.length).toString()),
                              style: TextStyle(color: colorScheme.mutedForeground),
                            ),
                            const SizedBox(height: 20),
                            if (sortedSongs.isNotEmpty)
                              Row(
                                children: [
                                  Expanded(
                                    child: ShadButton(
                                      size: ShadButtonSize.lg,
                                      onPressed: () {
                                        final playableSongs = networkState.isOffline
                                            ? sortedSongs.where((s) => downloadedIds.contains(s['id']?.toString())).toList()
                                            : sortedSongs;
                                        if (playableSongs.isNotEmpty) {
                                          ref.read(audioProvider.notifier).playQueue(playableSongs, 0);
                                        }
                                      },
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(LucideIcons.play, size: 20),
                                          const SizedBox(width: 8),
                                          Text(l10n.playerPlay, style: const TextStyle(fontSize: 16)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: ShadButton.secondary(
                                      size: ShadButtonSize.lg,
                                      onPressed: () {
                                        final playableSongs = networkState.isOffline
                                            ? sortedSongs.where((s) => downloadedIds.contains(s['id']?.toString())).toList()
                                            : sortedSongs;
                                        if (playableSongs.isNotEmpty) {
                                          final shuffledList = List<dynamic>.from(playableSongs)..shuffle();
                                          ref.read(audioProvider.notifier).playQueue(shuffledList, 0);
                                        }
                                      },
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(LucideIcons.shuffle, size: 20),
                                          const SizedBox(width: 8),
                                          Text(l10n.playerShuffle, style: const TextStyle(fontSize: 16)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (sortedSongs.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Center(
                            child: Text(
                              l10n.playlistIsEmpty,
                              style: TextStyle(color: colorScheme.mutedForeground),
                            ),
                          ),
                        ),
                      )
                    else
                      ZenifySongList(
                        useSliver: true,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        showCover: true,
                        showFavoriteButton: true,
                        songs: sortedSongs.asMap().entries.map((entry) {
                          final songIndex = entry.key;
                          final song = entry.value;
                          final coverId = song['coverArt'] ?? song['albumId'];
                          final fallbackUrl = api != null && coverId != null ? api.getCoverArtUrl(coverId, size: 250) : null;
                          final duration = _formatDuration(song['duration'] as int? ?? 0);
                          final songId = song['id']?.toString() ?? '';

                          return SongTileData(
                            id: songId,
                            title: song['title'] ?? l10n.unknownSong,
                            subtitle: song['artist'] ?? l10n.unknownArtist,
                            coverId: song['albumId']?.toString() ?? coverId?.toString() ?? '',
                            fallbackCoverUrl: fallbackUrl,
                            duration: duration,
                            isOfflineUnplayable: networkState.isOffline && !(song['isDownloaded'] == true),
                            serverId: server?.id ?? 0,
                            rawSong: song,
                            isFavorite: song['starred'] != null,
                            onTap: () {
                              ref.read(audioProvider.notifier).playQueue(songs, songIndex);
                            },
                          );
                        }).toList(),
                      ),
                    const SliverPadding(padding: EdgeInsets.only(bottom: 128)),
                  ],
                ),
              ),
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
