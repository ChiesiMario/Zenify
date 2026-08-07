import 'package:zenify/l10n/app_localizations.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenify/models/downloaded_track.dart';
import 'package:zenify/providers/download_provider.dart';
import 'package:zenify/providers/audio_provider.dart';
import 'package:zenify/providers/app_providers.dart';
import 'package:zenify/components/local_cover_image.dart';
import 'package:zenify/components/albums_grid.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:zenify/providers/sort_providers.dart';

class DownloadsView extends ConsumerStatefulWidget {
  const DownloadsView({super.key});

  @override
  ConsumerState<DownloadsView> createState() => _DownloadsViewState();
}

class _DownloadsViewState extends ConsumerState<DownloadsView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);
    // Set initial state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(downloadsTabProvider.notifier).state = _tabController.index;
    });
  }

  void _handleTabSelection() {
    if (!_tabController.indexIsChanging) {
      ref.read(downloadsTabProvider.notifier).state = _tabController.index;
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  List<dynamic> _sortAlbums(List<dynamic> albums, AlbumSortOption option) {
    final list = List<dynamic>.from(albums);
    switch (option) {
      case AlbumSortOption.nameAsc:
        list.sort((a, b) => (a['title'] ?? '').toString().toLowerCase().compareTo((b['title'] ?? '').toString().toLowerCase()));
        break;
      case AlbumSortOption.nameDesc:
        list.sort((a, b) => (b['title'] ?? '').toString().toLowerCase().compareTo((a['title'] ?? '').toString().toLowerCase()));
        break;
      case AlbumSortOption.random:
        list.shuffle();
        break;
      case AlbumSortOption.defaultOrder:
      default:
        break;
    }
    return list;
  }

  List<DownloadedTrack> _sortSongs(List<DownloadedTrack> tracks, SongSortOption option) {
    final list = List<DownloadedTrack>.from(tracks);
    switch (option) {
      case SongSortOption.nameAsc:
        list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case SongSortOption.nameDesc:
        list.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
        break;
      case SongSortOption.random:
        list.shuffle();
        break;
      case SongSortOption.defaultOrder:
        list.sort((a, b) {
          final da = a.downloadedAt;
          final db = b.downloadedAt;
          return db.compareTo(da);
        });
        break;
    }
    return list;
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _formatSize(int bytes) {
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;
    final downloadsAsync = ref.watch(downloadedTracksProvider);
    final api = ref.watch(subsonicApiProvider);
    final audioNotifier = ref.read(audioProvider.notifier);

    final showCached = ref.watch(showCachedDownloadsProvider);
    List<DownloadedTrack> currentViewTracks = [];
    downloadsAsync.whenData((tracks) {
      final validTracks = tracks.where((t) => File(t.localPath).existsSync()).toList();
      currentViewTracks = showCached ? validTracks : validTracks.where((t) => t.isManualDownload).toList();
    });

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: colorScheme.background,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        automaticallyImplyLeading: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 240),
                      child: Container(
                        height: 52,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: colorScheme.card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: colorScheme.border,
                            width: 1.0,
                          ),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          overlayColor: WidgetStateProperty.all(Colors.transparent),
                          dividerColor: Colors.transparent,
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicator: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          labelColor: colorScheme.primaryForeground,
                          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 0.2),
                          unselectedLabelColor: colorScheme.foreground.withValues(alpha: 0.5),
                          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                          tabs: [
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(LucideIcons.disc, size: 16),
                                  const SizedBox(width: 6),
                                  Text(l10n.navAlbums),
                                ],
                              ),
                            ),
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(LucideIcons.music, size: 16),
                                  SizedBox(width: 6),
                                  Text(l10n.songs),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (currentViewTracks.isNotEmpty)
                      _HoverablePlayIconButton(
                        onPressed: () {
                          final songs = currentViewTracks.map((t) {
                            try {
                              return jsonDecode(t.rawData) as Map<String, dynamic>;
                            } catch (_) {
                              return null;
                            }
                          }).whereType<Map<String, dynamic>>().toList();
                          
                          if (songs.isNotEmpty) {
                            audioNotifier.playQueue(songs, 0);
                          }
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: downloadsAsync.when(
        data: (tracks) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildAlbumsTab(
                context: context,
                manualTracks: currentViewTracks,
                colorScheme: colorScheme,
                api: api,
              ),
              _buildSongsTab(
                context: context,
                manualTracks: currentViewTracks,
                colorScheme: colorScheme,
                api: api,
              ),
            ],
          );
        },
        loading: () => Center(child: CircularProgressIndicator(color: colorScheme.foreground)),
        error: (err, stack) => Center(
          child: Text(l10n.loadFailed(err.toString()), style: TextStyle(color: colorScheme.destructive)),
        ),
      ),
    );
  }

  Widget _buildAlbumsTab({
    required BuildContext context,
    required List<DownloadedTrack> manualTracks,
    required ShadColorScheme colorScheme,
    required dynamic api,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final sortOption = ref.watch(albumSortProvider);

    // Group tracks by albumId
    final albumGroups = <String, List<DownloadedTrack>>{};
    for (final track in manualTracks) {
      final aId = track.albumId ?? 'unknown';
      albumGroups.putIfAbsent(aId, () => []).add(track);
    }

    final albums = albumGroups.entries.map((e) {
      final tracks = e.value;
      final firstTrack = tracks.first;
      dynamic year;
      try {
        final rawMap = jsonDecode(firstTrack.rawData);
        year = rawMap['year'];
      } catch (_) {}

      return {
        'id': e.key == 'unknown' ? null : e.key,
        'title': firstTrack.album ?? l10n.unknownAlbum,
        'artist': firstTrack.artist,
        'artistId': null, // We don't save artistId in DownloadedTrack
        'coverArt': firstTrack.coverArt,
        'songCount': tracks.length,
        'year': year,
      };
    }).toList();

    final sortedAlbums = _sortAlbums(albums, sortOption);

    if (sortedAlbums.isEmpty) {
      return Center(
        child: Text(
          l10n.noOfflineAlbumsYet,
          style: TextStyle(color: colorScheme.mutedForeground),
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600), // Match typical grid max width
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.totalSortedAlbumsCount(sortedAlbums.length.toString()),
                      style: TextStyle(
                        color: colorScheme.foreground,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: AlbumsGrid(
                albums: sortedAlbums,
                physics: const BouncingScrollPhysics(),
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                hideOfflineIcon: true,
              ),
            ),
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 128)),
      ],
    );
  }

  Widget _buildSongsTab({
    required BuildContext context,
    required List<DownloadedTrack> manualTracks,
    required ShadColorScheme colorScheme,
    required dynamic api,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final sortOption = ref.watch(songSortProvider);
    final sortedTracks = _sortSongs(manualTracks, sortOption);

    if (sortedTracks.isEmpty) {
      return Center(
        child: Text(
          l10n.noOfflineSongsYet,
          style: TextStyle(color: colorScheme.mutedForeground),
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.totalSortedSongsCount(sortedTracks.length.toString()),
                      style: TextStyle(
                        color: colorScheme.foreground,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverLayoutBuilder(
          builder: (context, constraints) {
            final double horizontalPadding = (constraints.crossAxisExtent - 568) / 2;
            final double padding = horizontalPadding > 0 ? horizontalPadding : 0;
            return SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 16 + padding),
              sliver: DecoratedSliver(
                decoration: BoxDecoration(
                  color: colorScheme.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.border, width: 1.0),
                ),
                sliver: SliverList.builder(
                  itemCount: sortedTracks.length,
                  itemBuilder: (context, index) {
                      final track = sortedTracks[index];
                      int sizeBytes = track.sizeBytes;
                      if (sizeBytes <= 0) {
                        try {
                          final f = File(track.localPath);
                          if (f.existsSync()) {
                            sizeBytes = f.lengthSync();
                            if (sizeBytes > 0) {
                              track.sizeBytes = sizeBytes;
                              ref.read(databaseProvider).saveDownloadedTrack(track);
                            }
                          }
                        } catch (_) {}
                      }
                      final duration = _formatDuration(track.duration);
                      final size = _formatSize(sizeBytes);
                      
                      final isFirst = index == 0;
                      final isLast = index == sortedTracks.length - 1;

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
                          clipBehavior: Clip.antiAlias,
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
                              child: track.coverArt != null
                                  ? LocalCoverImage(
                                      id: track.albumId ?? track.coverArt!,
                                      serverId: track.serverId,
                                      fallbackUrl: api?.getCoverArtUrl(track.coverArt!),
                                    )
                                  : Icon(LucideIcons.music, size: 20, color: colorScheme.mutedForeground),
                            ),
                            title: Text(
                              track.title,
                              style: TextStyle(color: colorScheme.foreground, fontWeight: FontWeight.w600, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${track.artist} • $size',
                              style: TextStyle(color: colorScheme.mutedForeground, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(LucideIcons.trash2, color: colorScheme.destructive, size: 18),
                                  onPressed: () async {
                                    await ref.read(downloadServiceProvider).deleteDownload(track.songId);
                                    ref.invalidate(downloadedTracksProvider);
                                  },
                                  tooltip: l10n.delete,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  duration,
                                  style: TextStyle(color: colorScheme.mutedForeground, fontSize: 12),
                                ),
                              ],
                            ),
                            onTap: () {
                              final allSongs = sortedTracks.map((t) => jsonDecode(t.rawData)).toList();
                              ref.read(audioProvider.notifier).playQueue(allSongs, index);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
            );
          },
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 128)),
      ],
    );
  }
}

class _HoverablePlayIconButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _HoverablePlayIconButton({required this.onPressed});

  @override
  State<_HoverablePlayIconButton> createState() => _HoverablePlayIconButtonState();
}

class _HoverablePlayIconButtonState extends State<_HoverablePlayIconButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;
    
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onPressed();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.90 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            opacity: _isPressed ? 0.6 : (_isHovered ? 0.8 : 1.0),
            duration: const Duration(milliseconds: 150),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colorScheme.foreground,
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.border,
                  width: 1.0,
                ),
              ),
              child: Center(
                child: Icon(
                  LucideIcons.play,
                  size: 20,
                  color: colorScheme.background,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

