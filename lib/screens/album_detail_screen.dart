import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenify/providers/app_providers.dart';
import 'package:zenify/providers/audio_provider.dart';
import 'package:zenify/providers/download_provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:zenify/components/local_cover_image.dart';
import 'package:zenify/screens/artist_detail_screen.dart';

class AlbumDetailScreen extends ConsumerWidget {
  final String albumId;

  const AlbumDetailScreen({super.key, required this.albumId});

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;
    final albumAsync = ref.watch(albumDetailProvider(albumId));
    final api = ref.watch(subsonicApiProvider);
    final server = ref.watch(activeServerProvider).value;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: albumAsync.when(
        data: (album) {
          if (album == null) {
            return Center(child: Text('找不到專輯資訊', style: TextStyle(color: colorScheme.mutedForeground)));
          }

          final coverUrl = api != null && album['coverArt'] != null
              ? api.getCoverArtUrl(album['coverArt'])
              : null;
              
          var songs = album['song'];
          if (songs != null && songs is! List) {
            songs = [songs];
          }
          final songList = songs as List<dynamic>? ?? [];

          final Map<int, List<Map<String, dynamic>>> groupedSongs = {};
          for (int i = 0; i < songList.length; i++) {
            final song = songList[i];
            final discNumber = song['discNumber'] as int? ?? 1;
            if (!groupedSongs.containsKey(discNumber)) {
              groupedSongs[discNumber] = [];
            }
            groupedSongs[discNumber]!.add({
              'index': i,
              'song': song,
            });
          }
          final discNumbers = groupedSongs.keys.toList()..sort();
          final hasMultipleDiscs = discNumbers.length > 1;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: CustomScrollView(
              slivers: [
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                  // Header
                  SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Album Cover
                          Container(
                            width: 250,
                            height: 250,
                            decoration: BoxDecoration(
                              color: colorScheme.muted,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 30,
                                  offset: const Offset(0, 15),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              clipBehavior: Clip.antiAliasWithSaveLayer,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  coverUrl == null
                                      ? Icon(LucideIcons.music, size: 80, color: colorScheme.mutedForeground)
                                      : LocalCoverImage(
                                          id: album['coverArt'],
                                          serverId: server?.id ?? 0,
                                          fallbackUrl: coverUrl,
                                          isThumb: false,
                                          fit: BoxFit.cover,
                                        ),
                                  IgnorePointer(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: colorScheme.foreground.withValues(alpha: 0.08),
                                          width: 1.0,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Typography
                          Text(
                            album['name'] ?? '未知專輯',
                            style: TextStyle(
                              color: colorScheme.foreground,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                              height: 1.1,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Builder(
                            builder: (context) {
                              bool isHovered = false;
                              return StatefulBuilder(
                                builder: (context, setState) {
                                  return MouseRegion(
                                cursor: SystemMouseCursors.click,
                                onEnter: (_) => setState(() => isHovered = true),
                                onExit: (_) => setState(() => isHovered = false),
                                child: GestureDetector(
                                  onTap: () {
                                    final artistId = album['artistId'];
                                    if (artistId != null) {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          settings: RouteSettings(name: album['artist']),
                                          builder: (context) => ArtistDetailScreen(
                                            artistId: artistId, 
                                            artistName: album['artist'] ?? '未知藝術家',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  child: Text(
                                    album['artist'] ?? '未知藝術家',
                                    style: TextStyle(
                                      color: colorScheme.mutedForeground,
                                      fontSize: 13,
                                      fontWeight: FontWeight.normal,
                                      height: 1.1,
                                      decoration: isHovered ? TextDecoration.underline : TextDecoration.none,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                );
                              },
                            );
                          },
                        ),
                          const SizedBox(height: 4),
                          Builder(
                            builder: (context) {
                              final parts = <String>[];
                              if (album['genre'] != null) parts.add(album['genre'].toString());
                              if (album['year'] != null) parts.add(album['year'].toString());
                              parts.add('${songList.length} 首歌');
                              
                              final List<InlineSpan> spans = [];
                              for (int i = 0; i < parts.length; i++) {
                                spans.add(TextSpan(text: parts[i]));
                                if (i != parts.length - 1) {
                                  spans.add(const TextSpan(
                                    text: ' • ',
                                    style: TextStyle(fontFamily: 'NotoSansTC'),
                                  ));
                                }
                              }
                              
                              return Text.rich(
                                TextSpan(children: spans),
                                style: TextStyle(
                                  color: colorScheme.mutedForeground, 
                                  fontSize: 13, 
                                  fontWeight: FontWeight.normal, 
                                  height: 1.1,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: ShadButton(
                                  size: ShadButtonSize.lg,
                                  onPressed: () {
                                    if (songList.isNotEmpty) {
                                      ref.read(audioProvider.notifier).playQueue(songList, 0);
                                    }
                                  },
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(LucideIcons.play, size: 20),
                                      SizedBox(width: 8),
                                      Text('播放', style: TextStyle(fontSize: 16)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ShadButton.secondary(
                                  size: ShadButtonSize.lg,
                                  onPressed: () {
                                    if (songList.isNotEmpty) {
                                      final shuffledList = List<dynamic>.from(songList)..shuffle();
                                      ref.read(audioProvider.notifier).playQueue(shuffledList, 0);
                                    }
                                  },
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(LucideIcons.shuffle, size: 20),
                                      SizedBox(width: 8),
                                      Text('隨機播放', style: TextStyle(fontSize: 16)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Tracklist
                  ...discNumbers.expand((discNumber) {
                    final group = groupedSongs[discNumber]!;
                    return [
                      if (hasMultipleDiscs)
                        SliverToBoxAdapter(
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 600),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                                child: Row(
                              children: [
                                Icon(LucideIcons.disc, size: 16, color: colorScheme.mutedForeground),
                                const SizedBox(width: 8),
                                Text(
                                  'Disc $discNumber',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.mutedForeground,
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
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Container(
                            decoration: BoxDecoration(
                              color: colorScheme.card,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: colorScheme.border, width: 1.0),
                            ),
                            child: Column(
                              children: List.generate(group.length, (localIndex) {
                                final item = group[localIndex];
                                final int absoluteIndex = item['index'];
                                final song = item['song'];
                                final duration = song['duration'] != null ? _formatDuration(song['duration']) : '--:--';
                                
                                final isFirst = localIndex == 0;
                                final isLast = localIndex == group.length - 1;

                                return Container(
                                  decoration: BoxDecoration(
                                    border: isLast ? null : Border(bottom: BorderSide(color: colorScheme.border.withValues(alpha: 0.5), width: 0.5)),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.vertical(
                                      top: isFirst ? const Radius.circular(12) : Radius.zero,
                                      bottom: isLast ? const Radius.circular(12) : Radius.zero,
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                      leading: SizedBox(
                                        width: 24,
                                        child: Center(
                                          child: Text(
                                            song['track']?.toString() ?? '${localIndex + 1}',
                                            style: TextStyle(color: colorScheme.mutedForeground, fontSize: 13, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        song['title'] ?? '未知歌曲',
                                        style: TextStyle(color: colorScheme.foreground, fontWeight: FontWeight.w600, fontSize: 14),
                                      ),
                                      subtitle: song['artist'] != album['artist']
                                          ? Text(song['artist'] ?? '', style: TextStyle(color: colorScheme.mutedForeground, fontSize: 12))
                                          : null,
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Consumer(
                                            builder: (context, ref, child) {
                                              final songId = song['id'].toString();
                                              final progressMap = ref.watch(downloadProgressProvider);
                                              final tracksAsync = ref.watch(downloadedTracksProvider);
                                              
                                              final isDownloaded = tracksAsync.when(
                                                data: (tracks) => tracks.any((t) => t.songId == songId && t.isManualDownload && t.isComplete),
                                                loading: () => false,
                                                error: (_, __) => false,
                                              );

                                              if (isDownloaded) {
                                                return Icon(LucideIcons.checkCircle2, color: colorScheme.primary, size: 20);
                                              }

                                              final progress = progressMap[songId];
                                              if (progress != null && progress < 1.0) {
                                                return SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child: CircularProgressIndicator(value: progress, strokeWidth: 2, color: colorScheme.primary),
                                                );
                                              }

                                              return IconButton(
                                                icon: Icon(LucideIcons.downloadCloud, color: colorScheme.mutedForeground, size: 20),
                                                onPressed: () {
                                                  if (server != null) {
                                                    ref.read(downloadServiceProvider).downloadSong(song, server.id);
                                                  }
                                                },
                                                tooltip: '下載歌曲',
                                              );
                                            },
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            duration,
                                            style: TextStyle(color: colorScheme.mutedForeground, fontSize: 13, fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                                      onTap: () {
                                        ref.read(audioProvider.notifier).playQueue(songList, absoluteIndex);
                                      },
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (hasMultipleDiscs && discNumber != discNumbers.last)
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    ];
                  }),
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                  SliverToBoxAdapter(
                    child: Container(
                      color: const Color(0xFFF4F4F5),
                      padding: const EdgeInsets.only(top: 24, bottom: 148),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _AlbumOfflineBentoCard(
                                    songList: songList,
                                    serverId: server?.id ?? 0,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: SizedBox(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
        },
        loading: () => Center(child: CircularProgressIndicator(color: colorScheme.foreground)),
        error: (err, stack) => Center(child: Text('加載失敗: $err', style: TextStyle(color: colorScheme.destructive))),
      ),
    );
  }
}

class _AlbumOfflineBentoCard extends ConsumerStatefulWidget {
  final List<dynamic> songList;
  final int serverId;

  const _AlbumOfflineBentoCard({
    required this.songList,
    required this.serverId,
  });

  @override
  ConsumerState<_AlbumOfflineBentoCard> createState() => _AlbumOfflineBentoCardState();
}

class _AlbumOfflineBentoCardState extends ConsumerState<_AlbumOfflineBentoCard> {
  bool _isHovered = false;
  bool? _optimisticState;

  Future<void> _handleToggle(bool turnOn) async {
    setState(() => _optimisticState = turnOn);
    final downloadService = ref.read(downloadServiceProvider);
    if (turnOn) {
      for (final song in widget.songList) {
        await downloadService.downloadSong(song, widget.serverId);
      }
    } else {
      for (final song in widget.songList) {
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

    final isAllOfflined = widget.songList.isNotEmpty &&
        widget.songList.every((s) => manualDownloadedIds.contains(s['id'].toString()));

    final isDownloading = _optimisticState != null || widget.songList.any((s) {
      final p = downloadProgress[s['id'].toString()];
      return p != null && p > 0.0 && p < 1.0;
    });

    final effectiveOfflined = _optimisticState ?? isAllOfflined;

    final String titleStr = _optimisticState == true
        ? '離線中...'
        : (effectiveOfflined ? '已離線' : '離線');

    final String subtitleStr = _optimisticState == true
        ? '正在離線全專輯歌曲...'
        : (effectiveOfflined ? '已儲存至離線音樂' : '離線本專輯所有歌曲');

    int totalBytes = 0;
    for (final song in widget.songList) {
      if (song['size'] != null && song['size'] is int) {
        totalBytes += song['size'] as int;
      } else if (song['duration'] != null && song['duration'] is int) {
        final dur = song['duration'] as int;
        final br = (song['bitRate'] as int?) ?? 320;
        totalBytes += (dur * br * 1000 ~/ 8);
      }
    }

    String sizeFormatted = '';
    if (totalBytes > 0) {
      if (totalBytes >= 1024 * 1024 * 1024) {
        sizeFormatted = '${(totalBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
      } else {
        sizeFormatted = '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
    }

    return MouseRegion(
      cursor: isDownloading ? SystemMouseCursors.basic : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: isDownloading ? null : () => _handleToggle(!effectiveOfflined),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (_isHovered && !isDownloading)
                  ? colorScheme.foreground.withValues(alpha: 0.4)
                  : colorScheme.border,
              width: 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    height: 38,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Opacity(
                        opacity: isDownloading ? 0.4 : 1.0,
                        child: ShadSwitch(
                          value: effectiveOfflined,
                          onChanged: isDownloading ? null : (value) => _handleToggle(value),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    titleStr,
                    style: TextStyle(
                      color: colorScheme.foreground,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorScheme.muted.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: colorScheme.border.withValues(alpha: 0.5),
                        width: 0.5,
                      ),
                    ),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: '${widget.songList.length} 首'),
                          if (sizeFormatted.isNotEmpty) ...[
                            const TextSpan(
                              text: ' • ',
                              style: TextStyle(fontFamily: 'NotoSansTC'),
                            ),
                            TextSpan(text: sizeFormatted),
                          ],
                        ],
                      ),
                      style: TextStyle(
                        color: colorScheme.mutedForeground,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                subtitleStr,
                style: TextStyle(
                  color: colorScheme.mutedForeground,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
