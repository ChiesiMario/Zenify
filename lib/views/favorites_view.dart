import 'package:zenify/l10n/app_localizations.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:zenify/providers/app_providers.dart';
import 'package:zenify/providers/audio_provider.dart';
import 'package:zenify/providers/download_provider.dart';
import 'package:zenify/views/playlists_view.dart';
import 'package:zenify/utils/responsive.dart';
import 'package:zenify/router/app_router.dart';

class FavoritesView extends ConsumerWidget {
  const FavoritesView({super.key});

  String _formatSize(int bytes) {
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;

    final favoritesAsync = ref.watch(favoritesProvider);
    final playlistsAsync = ref.watch(playlistsProvider);
    final downloadsAsync = ref.watch(downloadedTracksProvider);

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


    return Scaffold(
      backgroundColor: colorScheme.background,
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: getResponsiveMaxWidth(context)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Hero Sanctuary Overview Banner
                    _buildHeroBanner(context, ref, colorScheme, songs, albums.length, _formatSize(totalCacheSizeBytes)),
                    const SizedBox(height: 24),

                    // 2. Section Header for Categories
                    _buildSectionHeader(l10n.favoriteCategories, colorScheme),
                    const SizedBox(height: 12),

                    // 2x2 Bento Box Grid
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _VercelBentoCard(
                                title: l10n.songs,
                                subtitle: l10n.favoriteSinglesAndPersonalFavorites,
                                icon: LucideIcons.music,
                                countBadge: l10n.songsCountOnly(songs.length.toString()),
                                onTap: () => context.pushBranch('songs', extra: l10n.songs),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _VercelBentoCard(
                                title: l10n.navAlbums,
                                subtitle: l10n.favoritedMusicAlbums,
                                icon: LucideIcons.disc,
                                countBadge: l10n.albumsCountOnly(albums.length.toString()),
                                onTap: () => context.pushBranch('favorite_albums', extra: l10n.navAlbums),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _VercelBentoCard(
                                title: l10n.navPlaylists,
                                subtitle: l10n.customMusicPlaylists,
                                icon: LucideIcons.listMusic,
                                countBadge: l10n.playlistsCountOnly(playlists.length.toString()),
                                onTap: () => context.pushBranch('playlists', extra: l10n.navPlaylists),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _VercelBentoCard(
                                title: l10n.offlineStatus,
                                subtitle: l10n.offlineMusicAndCache,
                                icon: LucideIcons.downloadCloud,
                                countBadge: l10n.validDownloadsCount(validDownloads.length.toString()),
                                onTap: () => context.pushBranch('downloads', extra: l10n.offlineStatus),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                  const SizedBox(height: 32),
                  Opacity(
                    opacity: 0.4,
                    child: Column(
                      children: [
                        Divider(color: colorScheme.border),
                        const SizedBox(height: 16),
                        ListTile(
                          leading: Icon(LucideIcons.settings, color: colorScheme.foreground, size: 20),
                          title: Text(l10n.appSettings, style: TextStyle(color: colorScheme.foreground, fontSize: 14, fontWeight: FontWeight.w500)),
                          trailing: Icon(LucideIcons.chevronRight, color: colorScheme.mutedForeground, size: 16),
                          onTap: () {
                            context.push('/settings');
                          },
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 128),
                ],
                ),
              ),
            ),
          ),
        ],
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
    final l10n = AppLocalizations.of(context)!;
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
            l10n.personalMusicCollection,
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
                l10n.songsCountFull(songs.length.toString()),
                style: TextStyle(color: colorScheme.mutedForeground, fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 6),
              Text('•', style: TextStyle(color: colorScheme.mutedForeground, fontSize: 12)),
              const SizedBox(width: 6),
              Text(
                l10n.albumsCountVarFull(albumsCount.toString()),
                style: TextStyle(color: colorScheme.mutedForeground, fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 6),
              Text('•', style: TextStyle(color: colorScheme.mutedForeground, fontSize: 12)),
              const SizedBox(width: 6),
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.shuffle, size: 16),
                const SizedBox(width: 8),
                Text(l10n.shuffleFavoriteSongs, style: TextStyle(fontWeight: FontWeight.w600)),
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
    final l10n = AppLocalizations.of(context)!;
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
