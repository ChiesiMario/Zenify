import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:zenify/components/local_cover_image.dart';
import 'package:zenify/components/albums_grid.dart';
import 'package:zenify/providers/app_providers.dart';
import 'package:zenify/providers/audio_provider.dart';

class ArtistDetailScreen extends ConsumerStatefulWidget {
  final String artistId;
  final String artistName;
  final String? coverUrl;

  const ArtistDetailScreen({
    super.key,
    required this.artistId,
    required this.artistName,
    this.coverUrl,
  });

  @override
  ConsumerState<ArtistDetailScreen> createState() => _ArtistDetailScreenState();
}

class _ArtistDetailScreenState extends ConsumerState<ArtistDetailScreen> {
  bool _isBioExpanded = false;
  bool _showAllTopSongs = false;

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;
    final artistDetailAsync = ref.watch(artistDetailProvider(widget.artistId));
    final server = ref.watch(activeServerProvider).value;
    final api = ref.watch(subsonicApiProvider);

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: artistDetailAsync.when(
        data: (artistData) {
          if (artistData == null) {
            return Center(
              child: Text('無法載入藝術家資料', style: TextStyle(color: colorScheme.destructive)),
            );
          }

          final String name = artistData['name'] ?? widget.artistName;
          final String? bio = artistData['biography'];
          final List<dynamic> topSongs = artistData['topSongs'] ?? [];
          final List<dynamic> albums = artistData['album'] ?? [];

          return CustomScrollView(
            slivers: [
              // 1. Hero Header
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 32),
                          // Circular Artist Cover
                          Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              color: colorScheme.muted,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 30,
                                  offset: const Offset(0, 15),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  LocalCoverImage(
                                    id: widget.artistId,
                                    serverId: server?.id ?? 0,
                                    fallbackUrl: widget.coverUrl,
                                    fit: BoxFit.cover,
                                    isThumb: false,
                                  ),
                                  IgnorePointer(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
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
                          const SizedBox(height: 24),
                          // Typography
                          Text(
                            name,
                            style: TextStyle(
                              color: colorScheme.foreground,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                              height: 1.1,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Builder(
                            builder: (context) {
                              int albumCount = artistData['albumCount'] as int? ?? albums.length;
                              int songCount = 0;
                              if (artistData['songCount'] != null) {
                                songCount = artistData['songCount'] as int;
                              } else {
                                for (var a in albums) {
                                  songCount += (a['songCount'] as int? ?? 0);
                                }
                              }
                              
                              final parts = <String>[];
                              parts.add('$albumCount 張專輯');
                              if (songCount > 0) parts.add('$songCount 首歌');
                              
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
                                  fontSize: 14,
                                  fontWeight: FontWeight.normal,
                                  height: 1.1,
                                ),
                                textAlign: TextAlign.center,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Content below header
              SliverToBoxAdapter(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (bio != null && bio.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            Text('關於', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.foreground, letterSpacing: -0.5)),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isBioExpanded = !_isBioExpanded;
                                });
                              },
                              child: AnimatedCrossFade(
                                duration: const Duration(milliseconds: 300),
                                crossFadeState: _isBioExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                                firstChild: _buildBioText(bio, colorScheme, 4),
                                secondChild: _buildBioText(bio, colorScheme, null),
                              ),
                            ),
                            const SizedBox(height: 32),
                          ] else ...[
                            const SizedBox(height: 24),
                          ],

                          // 3. Top Songs
                          if (topSongs.isNotEmpty) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  '熱門歌曲',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.foreground,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ShadButton.secondary(
                                      size: ShadButtonSize.sm,
                                      onPressed: () {
                                        final shuffled = List<dynamic>.from(topSongs)..shuffle();
                                        ref.read(audioProvider.notifier).playQueue(shuffled, 0);
                                      },
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(LucideIcons.shuffle, size: 14),
                                          SizedBox(width: 6),
                                          Text('隨機播放'),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ShadButton(
                                      size: ShadButtonSize.sm,
                                      onPressed: () {
                                        ref.read(audioProvider.notifier).playQueue(List<dynamic>.from(topSongs), 0);
                                      },
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(LucideIcons.play, size: 14),
                                          SizedBox(width: 6),
                                          Text('播放', style: TextStyle(fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              decoration: BoxDecoration(
                                color: colorScheme.card,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: colorScheme.border, width: 1.0),
                              ),
                              child: Column(
                                children: [
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    padding: EdgeInsets.zero,
                                    itemCount: _showAllTopSongs ? topSongs.length : (topSongs.length > 5 ? 5 : topSongs.length),
                                    itemBuilder: (context, index) {
                                      final song = topSongs[index];
                                      final title = song['title'] ?? '未知歌曲';
                                      final duration = _formatDuration(song['duration'] as int? ?? 0);
                                      final coverArtId = song['coverArt'] ?? song['albumId'];
                                      final fallbackUrl = api != null && coverArtId != null ? api.getCoverArtUrl(coverArtId, size: 250) : null;
                                      
                                      final isFirst = index == 0;
                                      final isLastIndex = _showAllTopSongs ? topSongs.length - 1 : (topSongs.length > 5 ? 4 : topSongs.length - 1);
                                      final isLast = index == isLastIndex;
                                      final showShowMoreButton = !_showAllTopSongs && topSongs.length > 5;

                                      return Container(
                                        decoration: BoxDecoration(
                                          border: (isLast && !showShowMoreButton) ? null : Border(bottom: BorderSide(color: colorScheme.border.withValues(alpha: 0.5), width: 0.5)),
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          borderRadius: BorderRadius.vertical(
                                            top: isFirst ? const Radius.circular(12) : Radius.zero,
                                            bottom: (isLast && !showShowMoreButton) ? const Radius.circular(12) : Radius.zero,
                                          ),
                                          clipBehavior: Clip.antiAlias,
                                          child: ListTile(
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                            leading: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                SizedBox(
                                                  width: 24,
                                                  child: Text(
                                                    '${index + 1}',
                                                    style: TextStyle(color: colorScheme.mutedForeground, fontSize: 13, fontWeight: FontWeight.w600),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                ClipRRect(
                                                  borderRadius: BorderRadius.circular(6),
                                                  child: SizedBox(
                                                    width: 44,
                                                    height: 44,
                                                    child: LocalCoverImage(
                                                      id: coverArtId ?? '',
                                                      serverId: server?.id ?? 0,
                                                      fallbackUrl: fallbackUrl,
                                                      isThumb: true,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            title: Text(title, style: TextStyle(color: colorScheme.foreground, fontWeight: FontWeight.w600, fontSize: 14)),
                                            subtitle: Text(song['album'] ?? '', style: TextStyle(color: colorScheme.mutedForeground, fontSize: 12)),
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
                                                        onPressed: () async {
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
                                            onTap: () {
                                              ref.read(audioProvider.notifier).playQueue(List<dynamic>.from(topSongs), index);
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  if (!_showAllTopSongs && topSongs.length > 5)
                                    Material(
                                      color: Colors.transparent,
                                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                                      clipBehavior: Clip.antiAlias,
                                      child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            _showAllTopSongs = true;
                                          });
                                        },
                                        child: Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          alignment: Alignment.center,
                                          child: Text(
                                            '顯示更多',
                                            style: TextStyle(
                                              color: colorScheme.foreground,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 48),
                          ],

                          // 4. Albums
                          if (albums.isNotEmpty) ...[
                            Text('專輯', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colorScheme.foreground, letterSpacing: -0.5)),
                            const SizedBox(height: 16),
                            AlbumsGrid(
                              albums: albums.toList(),
                              showYearInsteadOfArtist: true,
                            ),
                          ],
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // 5. Streaming Platforms Bottom Section
              SliverToBoxAdapter(
                child: Container(
                  color: const Color(0xFFF4F4F5),
                  padding: const EdgeInsets.only(top: 24, bottom: 148),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _StreamingPlatformsRow(
                          artistName: name,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => Center(child: CircularProgressIndicator(color: colorScheme.foreground)),
        error: (err, stack) => Center(
          child: Text('載入失敗: $err', style: TextStyle(color: colorScheme.destructive)),
        ),
      ),
    );
  }

  Widget _buildBioText(String bio, ShadColorScheme colorScheme, int? maxLines) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          bio,
          maxLines: maxLines,
          overflow: maxLines != null ? TextOverflow.ellipsis : null,
          style: TextStyle(
            color: colorScheme.mutedForeground,
            height: 1.6,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          maxLines != null ? '閱讀更多' : '收起',
          style: TextStyle(
            color: colorScheme.foreground,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _StreamingPlatformsRow extends StatelessWidget {
  final String? albumName;
  final String artistName;

  const _StreamingPlatformsRow({
    this.albumName,
    required this.artistName,
  });

  Future<void> _openPlatformUrl(String platform) async {
    final query = (albumName != null && albumName!.isNotEmpty)
        ? '$albumName $artistName'.trim()
        : artistName.trim();
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
