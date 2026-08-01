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
    final networkState = ref.watch(networkProvider);
    final downloadedTracksAsync = ref.watch(downloadedTracksProvider);
    final downloadedTracks = downloadedTracksAsync.valueOrNull ?? [];
    final downloadedIds = downloadedTracks
        .where((t) => t.isComplete && File(t.localPath).existsSync())
        .map((t) => t.songId)
        .toSet();

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
                                      ? Container(color: colorScheme.muted)
                                      : LocalCoverImage(
                                          id: album['albumId']?.toString() ?? album['parent']?.toString() ?? album['coverArt']?.toString() ?? album['id'],
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
                                    final playableSongs = networkState.isOffline 
                                      ? songList.where((s) => downloadedIds.contains(s['id']?.toString())).toList() 
                                      : songList;
                                    if (playableSongs.isNotEmpty) {
                                      ref.read(audioProvider.notifier).playQueue(playableSongs, 0);
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
                                    final playableSongs = networkState.isOffline 
                                      ? songList.where((s) => downloadedIds.contains(s['id']?.toString())).toList() 
                                      : songList;
                                    if (playableSongs.isNotEmpty) {
                                      final shuffledList = List<dynamic>.from(playableSongs)..shuffle();
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
                                
                                final isOfflineUnplayable = networkState.isOffline && !downloadedIds.contains(song['id']?.toString());
                                final opacity = isOfflineUnplayable ? 0.3 : 1.0;

                                return Container(
                                  decoration: BoxDecoration(
                                    border: isLast ? null : Border(bottom: BorderSide(color: colorScheme.border.withValues(alpha: 0.5), width: 0.5)),
                                  ),
                                  child: Opacity(
                                    opacity: opacity,
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
                                            Text(
                                              duration,
                                              style: TextStyle(color: colorScheme.mutedForeground, fontSize: 13, fontWeight: FontWeight.w500),
                                            ),
                                            const SizedBox(width: 4),
                                            Consumer(
                                              builder: (context, ref, child) {
                                                final favoritesAsync = ref.watch(favoritesProvider);
                                                final songId = song['id']?.toString();
                                                final isFavorite = favoritesAsync.value?['songs']?.any(
                                                  (s) => s['id']?.toString() == songId,
                                                ) ?? (song['starred'] != null);

                                                final mutedIconColor = colorScheme.mutedForeground.withValues(alpha: 0.3);

                                                return SizedBox(
                                                  width: 28,
                                                  height: 28,
                                                  child: IconButton(
                                                    padding: EdgeInsets.zero,
                                                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                                    icon: Icon(
                                                      isFavorite ? Icons.favorite : LucideIcons.heart,
                                                      color: isFavorite ? const Color(0xFFEF4444) : mutedIconColor,
                                                      size: 16,
                                                    ),
                                                    onPressed: isOfflineUnplayable ? null : () async {
                                                      if (songId == null || api == null) return;
                                                      if (isFavorite) {
                                                        await api.unstar(id: songId);
                                                      } else {
                                                        await api.star(id: songId);
                                                      }
                                                      ref.invalidate(favoritesProvider);
                                                    },
                                                    tooltip: isFavorite ? '取消最愛' : '加入最愛',
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                        onTap: isOfflineUnplayable ? null : () {
                                          ref.read(audioProvider.notifier).playQueue(songList, absoluteIndex);
                                        },
                                      ),
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
                      color: colorScheme.secondary,
                      padding: const EdgeInsets.only(top: 24, bottom: 148),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
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
                                const SizedBox(height: 20),
                                _StreamingPlatformsRow(
                                  albumName: album['name'] ?? '',
                                  artistName: album['artist'] ?? '',
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
    
    try {
      if (turnOn) {
        for (final song in widget.songList) {
          await downloadService.downloadSong(song, widget.serverId);
        }
      } else {
        for (final song in widget.songList) {
          await downloadService.deleteDownload(song['id'].toString());
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('離線操作失敗，可能歌曲無法下載或伺服器錯誤'),
            backgroundColor: ShadTheme.of(context).colorScheme.destructive,
          ),
        );
      }
    } finally {
      ref.invalidate(downloadedTracksProvider);
      await ref.read(downloadedTracksProvider.future);
      if (mounted) {
        setState(() => _optimisticState = null);
      }
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

    final networkState = ref.watch(networkProvider);
    final isOffline = networkState.isOffline;

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

    final isDisabled = isDownloading || isOffline;

    return MouseRegion(
      cursor: isDisabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: isDisabled ? null : () => _handleToggle(!effectiveOfflined),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (_isHovered && !isDisabled)
                  ? colorScheme.foreground.withValues(alpha: 0.4)
                  : colorScheme.border,
              width: 1.0,
            ),
          ),
          child: Opacity(
            opacity: isDisabled ? 0.4 : 1.0,
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
                        child: ShadSwitch(
                          value: effectiveOfflined,
                          onChanged: isDisabled ? null : (value) => _handleToggle(value),
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
      ),
    );
  }
}

class _StreamingPlatformsRow extends StatelessWidget {
  final String albumName;
  final String artistName;

  const _StreamingPlatformsRow({
    required this.albumName,
    required this.artistName,
  });

  Future<void> _openPlatformUrl(String platform) async {
    final query = '$albumName $artistName'.trim();
    final encodedQuery = Uri.encodeComponent(query);

    String url;
    switch (platform) {
      case 'spotify':
        url = 'https://open.spotify.com/search/$encodedQuery';
        break;
      case 'apple':
        url = 'https://music.apple.com/us/search?term=$encodedQuery';
        break;
      case 'ytmusic':
        url = 'https://music.youtube.com/search?q=$encodedQuery';
        break;
      case 'youtube':
        url = 'https://www.youtube.com/results?search_query=$encodedQuery';
        break;
      case 'tidal':
        url = 'https://listen.tidal.com/search?q=$encodedQuery';
        break;
      case 'amazon':
        url = 'https://music.amazon.com/search/$encodedQuery';
        break;
      case 'deezer':
        url = 'https://www.deezer.com/search/$encodedQuery';
        break;
      case 'qq':
        url = 'https://y.qq.com/n/ryqq/search?w=$encodedQuery';
        break;
      case 'netease':
        url = 'https://music.163.com/#/search/m/?s=$encodedQuery';
        break;
      case 'kkbox':
        url = 'https://www.kkbox.com/tw/tc/search/$encodedQuery';
        break;
      case 'bandcamp':
        url = 'https://bandcamp.com/search?q=$encodedQuery';
        break;
      case 'soundcloud':
        url = 'https://soundcloud.com/search?q=$encodedQuery';
        break;
      case 'qobuz':
        url = 'https://www.qobuz.com/us-en/search?q=$encodedQuery';
        break;
      case 'lastfm':
        url = 'https://www.last.fm/search?q=$encodedQuery';
        break;
      default:
        url = 'https://www.google.com/search?q=$encodedQuery';
    }

    try {
      if (Platform.isWindows) {
        await Process.run('cmd', ['/c', 'start', '', url]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [url]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [url]);
      }
    } catch (e) {
      print('Failed to open URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;

    final platforms = [
      {'id': 'spotify', 'name': 'Spotify', 'icon': LucideIcons.music},
      {'id': 'apple', 'name': 'Apple Music', 'icon': LucideIcons.headphones},
      {'id': 'ytmusic', 'name': 'YouTube Music', 'icon': LucideIcons.playCircle},
      {'id': 'youtube', 'name': 'YouTube', 'icon': LucideIcons.tv},
      {'id': 'tidal', 'name': 'Tidal', 'icon': LucideIcons.radio},
      {'id': 'amazon', 'name': 'Amazon Music', 'icon': LucideIcons.shoppingBag},
      {'id': 'deezer', 'name': 'Deezer', 'icon': LucideIcons.sliders},
      {'id': 'qq', 'name': 'QQ 音樂', 'icon': LucideIcons.disc},
      {'id': 'netease', 'name': '網易雲音樂', 'icon': LucideIcons.flame},
      {'id': 'kkbox', 'name': 'KKBOX', 'icon': LucideIcons.box},
      {'id': 'bandcamp', 'name': 'Bandcamp', 'icon': LucideIcons.tag},
      {'id': 'soundcloud', 'name': 'SoundCloud', 'icon': LucideIcons.cloud},
      {'id': 'qobuz', 'name': 'Qobuz', 'icon': LucideIcons.award},
      {'id': 'lastfm', 'name': 'Last.fm', 'icon': LucideIcons.activity},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '在其他串流平台搜尋',
          style: TextStyle(
            color: colorScheme.mutedForeground,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: platforms.map((p) {
            return _PlatformPillButton(
              label: p['name'] as String,
              icon: p['icon'] as IconData,
              onTap: () => _openPlatformUrl(p['id'] as String),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _PlatformPillButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _PlatformPillButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_PlatformPillButton> createState() => _PlatformPillButtonState();
}

class _PlatformPillButtonState extends State<_PlatformPillButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;

    final bgColor = _isHovered ? colorScheme.foreground : colorScheme.card;
    final fgColor = _isHovered ? colorScheme.background : colorScheme.foreground;
    final borderColor = _isHovered ? colorScheme.foreground : colorScheme.border;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: borderColor,
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 14,
                color: fgColor,
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  color: fgColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
