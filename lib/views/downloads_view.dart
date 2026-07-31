import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:ui';
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
      default:
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
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;
    final downloadsAsync = ref.watch(downloadedTracksProvider);
    final api = ref.watch(subsonicApiProvider);

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
                          tabs: const [
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(LucideIcons.disc, size: 16),
                                  SizedBox(width: 6),
                                  Text('專輯'),
                                ],
                              ),
                            ),
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(LucideIcons.music, size: 16),
                                  SizedBox(width: 6),
                                  Text('歌曲'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (ref.watch(activeServerProvider).value?.id != null)
                      _DeleteAllButton(serverId: ref.watch(activeServerProvider).value!.id),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: downloadsAsync.when(
        data: (tracks) {
          final validTracks = tracks.where((t) => File(t.localPath).existsSync()).toList();
          final manualTracks = validTracks.where((t) => t.isManualDownload).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildAlbumsTab(
                context: context,
                manualTracks: manualTracks,
                colorScheme: colorScheme,
                api: api,
              ),
              _buildSongsTab(
                context: context,
                manualTracks: manualTracks,
                colorScheme: colorScheme,
                api: api,
              ),
            ],
          );
        },
        loading: () => Center(child: CircularProgressIndicator(color: colorScheme.foreground)),
        error: (err, stack) => Center(
          child: Text('加載失敗: $err', style: TextStyle(color: colorScheme.destructive)),
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
      return {
        'id': e.key == 'unknown' ? null : e.key,
        'title': firstTrack.album ?? '未知專輯',
        'artist': firstTrack.artist,
        'artistId': null, // We don't save artistId in DownloadedTrack
        'coverArt': firstTrack.coverArt,
        'songCount': tracks.length,
      };
    }).toList();

    final sortedAlbums = _sortAlbums(albums, sortOption);

    if (sortedAlbums.isEmpty) {
      return Center(
        child: Text(
          '尚無已離線的專輯',
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
                      '共 ${sortedAlbums.length} 張專輯',
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
    final sortOption = ref.watch(songSortProvider);
    final sortedTracks = _sortSongs(manualTracks, sortOption);

    if (sortedTracks.isEmpty) {
      return Center(
        child: Text(
          '尚無已離線的歌曲',
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
                      '共 ${sortedTracks.length} 首歌曲',
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
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverCrossAxisGroup(
            slivers: [
              SliverCrossAxisExpanded(
                flex: 1,
                sliver: const SliverToBoxAdapter(child: SizedBox.shrink()),
              ),
              SliverConstrainedCrossAxis(
                maxExtent: 568,
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
                                  tooltip: '刪除',
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
              ),
              SliverCrossAxisExpanded(
                flex: 1,
                sliver: const SliverToBoxAdapter(child: SizedBox.shrink()),
              ),
            ],
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 128)),
      ],
    );
  }
}

class _DeleteAllButton extends ConsumerStatefulWidget {
  final int serverId;

  const _DeleteAllButton({required this.serverId});

  @override
  ConsumerState<_DeleteAllButton> createState() => _DeleteAllButtonState();
}

class _DeleteAllButtonState extends ConsumerState<_DeleteAllButton> {
  int _clickCount = 0;
  Timer? _resetTimer;

  void _handleClick() async {
    setState(() {
      _clickCount++;
    });

    _resetTimer?.cancel();

    if (_clickCount >= 3) {
      // Execute delete
      final downloadService = ref.read(downloadServiceProvider);
      await downloadService.deleteAllManualDownloads(widget.serverId);
      ref.invalidate(downloadedTracksProvider);
      
      setState(() {
        _clickCount = 0;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('已刪除所有手動離線的音樂', style: TextStyle(color: Colors.white)),
            backgroundColor: ShadTheme.of(context).colorScheme.primary,
          ),
        );
      }
    } else {
      // Start reset timer (3 seconds to confirm)
      _resetTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _clickCount = 0;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;
    
    String buttonText;
    Color buttonColor;
    Color borderColor;
    Color textColor;
    
    switch (_clickCount) {
      case 1:
        buttonText = '確認';
        buttonColor = colorScheme.destructive;
        textColor = colorScheme.destructiveForeground;
        borderColor = Colors.transparent;
        break;
      case 2:
        buttonText = '最終確認';
        buttonColor = colorScheme.destructive;
        textColor = colorScheme.destructiveForeground;
        borderColor = Colors.transparent;
        break;
      case 0:
      default:
        buttonText = '刪除全部';
        buttonColor = Colors.transparent;
        textColor = colorScheme.mutedForeground;
        borderColor = colorScheme.border;
        break;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 36,
      width: 90,
      child: ShadButton.outline(
        onPressed: _handleClick,
        backgroundColor: buttonColor,
        hoverBackgroundColor: _clickCount == 0 
            ? colorScheme.destructive.withValues(alpha: 0.1)
            : buttonColor,
        foregroundColor: textColor,
        hoverForegroundColor: textColor,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: ShadDecoration(
          border: ShadBorder.all(
            color: borderColor,
            width: 1,
            radius: const BorderRadius.all(Radius.circular(8)),
          ),
        ),
        child: Text(
          buttonText,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
    );
  }
}
