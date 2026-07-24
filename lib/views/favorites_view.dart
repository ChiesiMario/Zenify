import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:zenify/providers/app_providers.dart';
import 'package:zenify/providers/audio_provider.dart';
import 'package:zenify/providers/download_provider.dart';
import 'package:zenify/components/local_cover_image.dart';
import 'package:zenify/screens/favorite_songs_screen.dart';
import 'package:zenify/screens/favorite_albums_screen.dart';
import 'package:zenify/views/playlists_view.dart';
import 'package:zenify/views/downloads_view.dart';

class FavoritesView extends ConsumerWidget {
  const FavoritesView({super.key});

  String _formatSize(int bytes) {
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;

    final favoritesAsync = ref.watch(favoritesProvider);
    final playlistsAsync = ref.watch(playlistsProvider);
    final downloadsAsync = ref.watch(downloadedTracksProvider);
    final server = ref.watch(activeServerProvider).value;

    final List songs = favoritesAsync.value?['songs'] ?? [];
    final List albums = favoritesAsync.value?['albums'] ?? [];
    final playlists = playlistsAsync.value ?? [];
    final downloads = downloadsAsync.value ?? [];
    final validDownloads = downloads.where((t) => File(t.localPath).existsSync()).toList();

    final totalCacheSizeBytes = validDownloads.fold<int>(0, (sum, t) {
      int sz = t.sizeBytes;
      if (sz <= 0) {
        try {
          final f = File(t.localPath);
          if (f.existsSync()) sz = f.lengthSync();
        } catch (_) {}
      }
      return sum + sz;
    });

    final recentSongs = songs.take(4).toList();

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Padding(
        padding: const EdgeInsets.only(right: 2.0),
        child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Hero Sanctuary Overview Banner
                    _buildHeroBanner(context, ref, colorScheme, songs, albums.length, _formatSize(totalCacheSizeBytes)),
                    const SizedBox(height: 24),

                    // 2. Section Header for Categories
                    _buildSectionHeader('珍藏分類', colorScheme),
                    const SizedBox(height: 12),

                    // 2x2 Bento Box Grid
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _VercelBentoCard(
                                title: '歌曲',
                                subtitle: '喜愛單曲與個人最愛',
                                icon: LucideIcons.music,
                                countBadge: '${songs.length} 首',
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    settings: const RouteSettings(name: '歌曲'),
                                    builder: (context) => const FavoriteSongsScreen(),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _VercelBentoCard(
                                title: '專輯',
                                subtitle: '已收藏的音樂專輯',
                                icon: LucideIcons.disc,
                                countBadge: '${albums.length} 張',
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    settings: const RouteSettings(name: '專輯'),
                                    builder: (context) => const FavoriteAlbumsScreen(),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _VercelBentoCard(
                                title: '播放清單',
                                subtitle: '自訂音樂歌單',
                                icon: LucideIcons.listMusic,
                                countBadge: '${playlists.length} 個',
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    settings: const RouteSettings(name: '播放清單'),
                                    builder: (context) => const PlaylistsView(),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _VercelBentoCard(
                                title: '已下載',
                                subtitle: '離線音樂與快取',
                                icon: LucideIcons.downloadCloud,
                                countBadge: '${validDownloads.length} 首',
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    settings: const RouteSettings(name: '已下載'),
                                    builder: (context) => const DownloadsView(),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // 3. Recently Liked Snippet Section
                    if (recentSongs.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSectionHeader('最近收藏', colorScheme),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                settings: const RouteSettings(name: '歌曲'),
                                builder: (context) => const FavoriteSongsScreen(),
                              ),
                            ),
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: Row(
                                children: [
                                  Text(
                                    '查看全部 ${songs.length}',
                                    style: TextStyle(
                                      color: colorScheme.mutedForeground,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    LucideIcons.arrowRight,
                                    size: 14,
                                    color: colorScheme.mutedForeground,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: colorScheme.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.border,
                            width: 1.0,
                          ),
                        ),
                        child: Column(
                          children: recentSongs.asMap().entries.map((entry) {
                            final index = entry.key;
                            final song = entry.value;
                            final api = ref.watch(subsonicApiProvider);
                            final coverUrl = api != null && song['coverArt'] != null
                                ? api.getCoverArtUrl(song['coverArt'])
                                : null;
                            final isLast = index == recentSongs.length - 1;

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
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: coverUrl == null
                                        ? Icon(LucideIcons.music, size: 20, color: colorScheme.mutedForeground)
                                        : LocalCoverImage(
                                            id: song['coverArt'],
                                            serverId: server?.id ?? 0,
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
                                    style: TextStyle(
                                      color: colorScheme.mutedForeground,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: Icon(
                                    LucideIcons.heart,
                                    size: 16,
                                    color: colorScheme.primary,
                                  ),
                                  onTap: () {
                                    ref.read(audioProvider.notifier).playQueue(songs, index);
                                  },
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                  const SizedBox(height: 128),
                ],
                ),
              ),
            ),
          ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildHeroBanner(
    BuildContext context,
    WidgetRef ref,
    ShadColorScheme colorScheme,
    List<dynamic> songs,
    int albumsCount,
    String cacheSize,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.border,
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '個人音樂珍藏',
            style: TextStyle(
              color: colorScheme.foreground,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${songs.length} 首歌曲',
                style: TextStyle(color: colorScheme.mutedForeground, fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 8),
              Text('•', style: TextStyle(color: colorScheme.mutedForeground, fontSize: 12)),
              const SizedBox(width: 8),
              Text(
                '$albumsCount 張專輯',
                style: TextStyle(color: colorScheme.mutedForeground, fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 8),
              Text('•', style: TextStyle(color: colorScheme.mutedForeground, fontSize: 12)),
              const SizedBox(width: 8),
              Text(
                cacheSize,
                style: TextStyle(color: colorScheme.mutedForeground, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ShadButton(
            enabled: songs.isNotEmpty,
            onPressed: () {
              if (songs.isNotEmpty) {
                final shuffled = List<dynamic>.from(songs)..shuffle();
                ref.read(audioProvider.notifier).playQueue(shuffled, 0);
              }
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.shuffle, size: 16),
                SizedBox(width: 8),
                Text('隨機播放最愛歌曲', style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, ShadColorScheme colorScheme) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: colorScheme.mutedForeground,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _VercelBentoCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String countBadge;
  final VoidCallback onTap;

  const _VercelBentoCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.countBadge,
    required this.onTap,
  });

  @override
  State<_VercelBentoCard> createState() => _VercelBentoCardState();
}

class _VercelBentoCardState extends State<_VercelBentoCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered
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
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: _isHovered
                          ? colorScheme.foreground
                          : colorScheme.muted.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _isHovered
                            ? colorScheme.foreground
                            : colorScheme.border.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      widget.icon,
                      size: 18,
                      color: _isHovered
                          ? colorScheme.background
                          : colorScheme.foreground,
                    ),
                  ),
                  AnimatedSlide(
                    duration: const Duration(milliseconds: 150),
                    offset: _isHovered ? const Offset(0.1, -0.1) : Offset.zero,
                    child: Icon(
                      LucideIcons.arrowUpRight,
                      size: 16,
                      color: _isHovered
                          ? colorScheme.foreground
                          : colorScheme.mutedForeground.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    widget.title,
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
                    child: Text(
                      widget.countBadge,
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
                widget.subtitle,
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
