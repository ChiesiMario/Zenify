import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenify/models/downloaded_track.dart';
import 'package:zenify/providers/download_provider.dart';
import 'package:zenify/providers/audio_provider.dart';
import 'package:zenify/providers/app_providers.dart';
import 'package:zenify/components/local_cover_image.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class DownloadsView extends ConsumerWidget {
  const DownloadsView({super.key});

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
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;
    final downloadsAsync = ref.watch(downloadedTracksProvider);
    final api = ref.watch(subsonicApiProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: colorScheme.background,
        appBar: AppBar(
          toolbarHeight: 0,
          backgroundColor: colorScheme.background,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          elevation: 0,
          automaticallyImplyLeading: false,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: colorScheme.muted.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colorScheme.border.withValues(alpha: 0.8),
                        width: 1.0,
                      ),
                    ),
                    child: TabBar(
                      overlayColor: WidgetStateProperty.all(Colors.transparent),
                      dividerColor: Colors.transparent,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        color: colorScheme.card,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: colorScheme.border, width: 1.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      labelColor: colorScheme.foreground,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, letterSpacing: -0.2),
                      unselectedLabelColor: colorScheme.mutedForeground,
                      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                      tabs: const [
                        Tab(text: '手動下載'),
                        Tab(text: '播放快取'),
                      ],
                    ),
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
            final cacheTracks = validTracks.where((t) => !t.isManualDownload).toList();

            return TabBarView(
              children: [
                _buildTrackList(
                  context: context,
                  ref: ref,
                  tracks: manualTracks,
                  emptyText: '尚無手動下載的音樂',
                  colorScheme: colorScheme,
                  api: api,
                ),
                _buildCacheTab(
                  context: context,
                  ref: ref,
                  cacheTracks: cacheTracks,
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
      ),
    );
  }

  Widget _buildCacheTab({
    required BuildContext context,
    required WidgetRef ref,
    required List<DownloadedTrack> cacheTracks,
    required ShadColorScheme colorScheme,
    required dynamic api,
  }) {
    if (cacheTracks.isEmpty) {
      return Center(
        child: Text(
          '尚無播放快取紀錄',
          style: TextStyle(color: colorScheme.mutedForeground),
        ),
      );
    }

    final totalSizeBytes = cacheTracks.fold<int>(0, (sum, t) {
      int sz = t.sizeBytes;
      if (sz <= 0) {
        try {
          final f = File(t.localPath);
          if (f.existsSync()) {
            sz = f.lengthSync();
            if (sz > 0) {
              t.sizeBytes = sz;
              ref.read(databaseProvider).saveDownloadedTrack(t);
            }
          }
        } catch (_) {}
      }
      return sum + sz;
    });
    final formattedTotal = _formatSize(totalSizeBytes);

    return Column(
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        '共 ${cacheTracks.length} 首快取歌曲',
                        style: TextStyle(
                          color: colorScheme.foreground,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorScheme.muted.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.border.withValues(alpha: 0.6),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          formattedTotal,
                          style: TextStyle(
                            color: colorScheme.mutedForeground,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  ShadButton.outline(
                    size: ShadButtonSize.sm,
                    onPressed: () async {
                      await ref.read(downloadServiceProvider).clearAllCaches();
                      ref.invalidate(downloadedTracksProvider);
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.trash2, size: 13, color: colorScheme.mutedForeground),
                        const SizedBox(width: 6),
                        Text(
                          '清除所有快取',
                          style: TextStyle(
                            color: colorScheme.foreground,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: _buildTrackList(
            context: context,
            ref: ref,
            tracks: cacheTracks,
            emptyText: '尚無播放快取紀錄',
            colorScheme: colorScheme,
            api: api,
          ),
        ),
      ],
    );
  }

  Widget _buildTrackList({
    required BuildContext context,
    required WidgetRef ref,
    required List<DownloadedTrack> tracks,
    required String emptyText,
    required ShadColorScheme colorScheme,
    required dynamic api,
  }) {
    if (tracks.isEmpty) {
      return Center(
        child: Text(
          emptyText,
          style: TextStyle(color: colorScheme.mutedForeground),
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: CustomScrollView(
          slivers: [
            const SliverPadding(padding: EdgeInsets.only(top: 8)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: DecoratedSliver(
                decoration: BoxDecoration(
                  color: colorScheme.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.border, width: 1.0),
                ),
                sliver: SliverList.builder(
                  itemCount: tracks.length,
                  itemBuilder: (context, index) {
                    final track = tracks[index];
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
                    final isLast = index == tracks.length - 1;

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
                                    id: track.coverArt!,
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
                            final allSongs = tracks.map((t) => jsonDecode(t.rawData)).toList();
                            ref.read(audioProvider.notifier).playQueue(allSongs, index);
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 128)),
          ],
        ),
      ),
    );
  }
}
