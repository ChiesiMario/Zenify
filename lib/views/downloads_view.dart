import 'package:zenify/l10n/app_localizations.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenify/models/downloaded_track.dart';
import 'package:zenify/providers/download_provider.dart';
import 'package:zenify/providers/audio_provider.dart';
import 'package:zenify/providers/app_providers.dart';
import 'package:zenify/components/albums_grid.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:zenify/providers/sort_providers.dart';
import 'package:zenify/components/group_tab_bar.dart';
import 'package:zenify/components/zenify_song_list.dart';
import 'dart:math';

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

  List<dynamic> _sortAlbums(List<dynamic> albums, AlbumSortOption option, int randomSeed) {
    final list = List<dynamic>.from(albums);
    switch (option) {
      case AlbumSortOption.nameAsc:
        list.sort((a, b) => (a['title'] ?? '').toString().toLowerCase().compareTo((b['title'] ?? '').toString().toLowerCase()));
        break;
      case AlbumSortOption.nameDesc:
        list.sort((a, b) => (b['title'] ?? '').toString().toLowerCase().compareTo((a['title'] ?? '').toString().toLowerCase()));
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

  List<DownloadedTrack> _sortSongs(List<DownloadedTrack> tracks, SongSortOption option, int randomSeed) {
    final list = List<DownloadedTrack>.from(tracks);
    switch (option) {
      case SongSortOption.nameAsc:
        list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case SongSortOption.nameDesc:
        list.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
        break;
      case SongSortOption.random:
        list.shuffle(Random(randomSeed));
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
                    GroupTabBar(
                      controller: _tabController,
                      maxWidth: 240,
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

    final albumSeed = ref.read(albumSortProvider.notifier).randomSeed;
    final sortedAlbums = _sortAlbums(albums, sortOption, albumSeed);

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
    final songSeed = ref.read(songSortProvider.notifier).randomSeed;
    final sortedTracks = _sortSongs(manualTracks, sortOption, songSeed);

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
            final double horizontalPadding = (constraints.crossAxisExtent - 600) / 2;
            final double padding = horizontalPadding > 0 ? horizontalPadding : 0;
            return SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 16 + padding),
              sliver: ZenifySongList(
                useSliver: true,
                songs: sortedTracks.asMap().entries.map((entry) {
                  final index = entry.key;
                  final track = entry.value;
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
                  
                  final rawSong = jsonDecode(track.rawData);
                  
                  return SongTileData(
                    id: track.songId,
                    title: track.title,
                    subtitle: '${track.artist} • $size',
                    coverId: track.albumId ?? track.coverArt,
                    fallbackCoverUrl: track.coverArt != null ? api?.getCoverArtUrl(track.coverArt!) : null,
                    duration: duration,
                    isOfflineUnplayable: false,
                    serverId: track.serverId,
                    rawSong: rawSong,
                    isFavorite: rawSong is Map && rawSong['starred'] != null,
                    onTap: () {
                      final allSongs = sortedTracks.map((t) => jsonDecode(t.rawData)).toList();
                      ref.read(audioProvider.notifier).playQueue(allSongs, index);
                    },
                  );
                }).toList(),
                showCover: true,
                showFavoriteButton: true,
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

