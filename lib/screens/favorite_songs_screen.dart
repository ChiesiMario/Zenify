import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:zenify/providers/app_providers.dart';
import 'package:zenify/providers/audio_provider.dart';
import 'package:zenify/components/local_cover_image.dart';

import 'package:zenify/providers/sort_providers.dart';
import 'dart:io';
import 'package:zenify/providers/download_provider.dart';
import 'package:zenify/services/download_service.dart';

class FavoriteSongsScreen extends ConsumerWidget {
  const FavoriteSongsScreen({super.key});

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  List<dynamic> _sortSongs(List<dynamic> songs, AlbumSortOption option) {
    final list = List<dynamic>.from(songs);
    switch (option) {
      case AlbumSortOption.nameAsc:
        list.sort((a, b) => (a['title'] ?? '').toString().toLowerCase().compareTo((b['title'] ?? '').toString().toLowerCase()));
        break;
      case AlbumSortOption.nameDesc:
        list.sort((a, b) => (b['title'] ?? '').toString().toLowerCase().compareTo((a['title'] ?? '').toString().toLowerCase()));
        break;
      case AlbumSortOption.yearDesc:
        list.sort((a, b) => (b['year'] ?? 0).compareTo(a['year'] ?? 0));
        break;
      case AlbumSortOption.yearAsc:
        list.sort((a, b) => (a['year'] ?? 0).compareTo(b['year'] ?? 0));
        break;
      case AlbumSortOption.random:
        list.shuffle();
        break;
      case AlbumSortOption.defaultOrder:
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              child: Text('未連接伺服器，請先在右上角新增', style: TextStyle(color: colorScheme.mutedForeground)),
            );
          }

          final favoritesAsync = ref.watch(favoritesProvider);
          return favoritesAsync.when(
            data: (favorites) {
              final rawSongs = favorites['songs'] ?? [];
              final songs = _sortSongs(rawSongs, sortOption);

              if (songs.isEmpty) {
                return Center(child: Text('目前沒有任何喜愛的歌曲', style: TextStyle(color: colorScheme.mutedForeground)));
              }

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: CustomScrollView(
                    slivers: [
                      // Padding for top spacing
                      const SliverPadding(padding: EdgeInsets.only(top: 24)),
                      
                      // Hero Sub-Banner
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverToBoxAdapter(
                          child: _FavoriteHeroBanner(
                            songs: songs,
                            serverId: server.id,
                          ),
                        ),
                      ),
                      
                      // Spacing between banner and list
                      const SliverPadding(padding: EdgeInsets.only(top: 20)),

                      // Lazy loaded group card list with outer border
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: DecoratedSliver(
                          decoration: BoxDecoration(
                            color: colorScheme.card,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: colorScheme.border, width: 1.0),
                          ),
                          sliver: SliverList.builder(
                            itemCount: songs.length,
                            itemBuilder: (context, songIndex) {
                              final song = songs[songIndex];
                              final api = ref.watch(subsonicApiProvider);
                              final coverUrl = api != null && song['coverArt'] != null
                                  ? api.getCoverArtUrl(song['coverArt'])
                                  : null;
                                  
                              final isFirst = songIndex == 0;
                              final isLast = songIndex == songs.length - 1;

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
                                    top: isFirst ? const Radius.circular(12) : Radius.zero,
                                    bottom: isLast ? const Radius.circular(12) : Radius.zero,
                                  ),
                                  clipBehavior: Clip.antiAlias, // Ensures child ink/bg respects the corner radius
                                  child: ListTile(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                        top: isFirst ? const Radius.circular(12) : Radius.zero,
                                        bottom: isLast ? const Radius.circular(12) : Radius.zero,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                    leading: Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: colorScheme.muted,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: coverUrl == null
                                          ? Icon(LucideIcons.music, size: 20, color: colorScheme.mutedForeground)
                                          : LocalCoverImage(
                                              id: song['coverArt'],
                                              serverId: server.id,
                                              fallbackUrl: coverUrl,
                                            ),
                                    ),
                                    title: Text(
                                      song['title'] ?? '未知歌曲',
                                      style: TextStyle(
                                        color: colorScheme.foreground,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      song['artist'] ?? '未知藝術家',
                                      style: TextStyle(color: colorScheme.mutedForeground, fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          song['duration'] != null ? _formatDuration(song['duration'] as int) : '--:--',
                                          style: TextStyle(color: colorScheme.mutedForeground, fontSize: 13, fontWeight: FontWeight.w500),
                                        ),
                                        const SizedBox(width: 4),
                                        _FavoriteSongButton(songId: song['id'].toString()),
                                      ],
                                    ),
                                    onTap: () {
                                      ref.read(audioProvider.notifier).playQueue(songs, songIndex);
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      
                      // Bottom padding
                      const SliverPadding(padding: EdgeInsets.only(bottom: 128)),
                    ],
                  ),
                ),
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

class _FavoriteSongButton extends ConsumerStatefulWidget {
  final String songId;
  const _FavoriteSongButton({required this.songId});

  @override
  ConsumerState<_FavoriteSongButton> createState() => _FavoriteSongButtonState();
}

class _FavoriteSongButtonState extends ConsumerState<_FavoriteSongButton> {
  bool _isFavorite = true;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;
    final api = ref.watch(subsonicApiProvider);

    final mutedIconColor = colorScheme.mutedForeground.withValues(alpha: 0.3);

    return SizedBox(
      width: 28,
      height: 28,
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
        icon: Icon(
          _isFavorite ? Icons.favorite : LucideIcons.heart,
          color: _isFavorite ? const Color(0xFFEF4444) : mutedIconColor,
          size: 16,
        ),
        onPressed: () async {
          if (api == null) return;
          setState(() {
            _isFavorite = !_isFavorite;
          });
          if (_isFavorite) {
            await api.star(id: widget.songId);
          } else {
            await api.unstar(id: widget.songId);
          }
          // 特意不 invalidate favoritesProvider，讓歌曲保留在畫面上
        },
        tooltip: _isFavorite ? '取消最愛' : '加入最愛',
      ),
    );
  }
}

class _FavoriteHeroBanner extends ConsumerStatefulWidget {
  final List<dynamic> songs;
  final int serverId;

  const _FavoriteHeroBanner({
    required this.songs,
    required this.serverId,
  });

  @override
  ConsumerState<_FavoriteHeroBanner> createState() => _FavoriteHeroBannerState();
}

class _FavoriteHeroBannerState extends ConsumerState<_FavoriteHeroBanner> {
  bool? _optimisticState;

  Future<void> _handleToggle(bool turnOn) async {
    setState(() => _optimisticState = turnOn);
    final downloadService = ref.read(downloadServiceProvider);
    if (turnOn) {
      for (final song in widget.songs) {
        await downloadService.downloadSong(song, widget.serverId);
      }
    } else {
      for (final song in widget.songs) {
        await downloadService.deleteDownload(song['id'].toString());
      }
    }
    ref.invalidate(downloadedTracksProvider);
    await ref.read(downloadedTracksProvider.future);
    if (mounted) {
      setState(() => _optimisticState = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;
    final downloadedTracksAsync = ref.watch(downloadedTracksProvider);
    final downloadedTracks = downloadedTracksAsync.valueOrNull ?? [];
    final downloadProgress = ref.watch(downloadProgressProvider);

    final manualDownloadedIds = downloadedTracks
        .where((t) => t.isManualDownload && t.isComplete && File(t.localPath).existsSync())
        .map((t) => t.songId)
        .toSet();

    final isAllOfflined = widget.songs.isNotEmpty &&
        widget.songs.every((s) => manualDownloadedIds.contains(s['id'].toString()));

    final isDownloading = _optimisticState != null || widget.songs.any((s) {
      final p = downloadProgress[s['id'].toString()];
      return p != null && p > 0.0 && p < 1.0;
    });

    final effectiveOfflined = _optimisticState ?? isAllOfflined;

    final String statusStr = _optimisticState == true
        ? '正在離線歌曲...'
        : (effectiveOfflined ? '已全數離線' : '共 ${widget.songs.length} 首歌曲');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.border, width: 1.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '離線最愛歌曲',
                        style: TextStyle(
                          color: colorScheme.foreground,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Opacity(
                      opacity: isDownloading ? 0.4 : 1.0,
                      child: SizedBox(
                        height: 24, // Control height so it doesn't push row too high
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: ShadSwitch(
                            value: effectiveOfflined,
                            onChanged: isDownloading ? null : (value) => _handleToggle(value),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  statusStr,
                  style: TextStyle(color: colorScheme.mutedForeground, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShadButton.secondary(
                onPressed: () {
                  final shuffled = List<dynamic>.from(widget.songs)..shuffle();
                  ref.read(audioProvider.notifier).playQueue(shuffled, 0);
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.shuffle, size: 15, color: colorScheme.foreground),
                    const SizedBox(width: 6),
                    Text('隨機播放', style: TextStyle(fontWeight: FontWeight.w600, color: colorScheme.foreground)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ShadButton(
                onPressed: () {
                  ref.read(audioProvider.notifier).playQueue(widget.songs, 0);
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.play, size: 15),
                    SizedBox(width: 6),
                    Text('播放', style: TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
