import 'package:zenify/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:zenify/providers/app_providers.dart';
import 'package:zenify/providers/audio_provider.dart';
import 'package:zenify/components/local_cover_image.dart';
import 'package:zenify/components/zenify_toast.dart';

import 'package:zenify/providers/sort_providers.dart';
import 'package:zenify/providers/download_provider.dart';
import 'package:zenify/providers/offline_preference_provider.dart';

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
    final l10n = AppLocalizations.of(context)!;
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
              child: Text(l10n.serverNotConnectedHint, style: TextStyle(color: colorScheme.mutedForeground)),
            );
          }

          final favoritesAsync = ref.watch(favoritesProvider);
          return favoritesAsync.when(
            data: (favorites) {
              final rawSongs = favorites['songs'] ?? [];
              final songs = _sortSongs(rawSongs, sortOption);

              if (songs.isEmpty) {
                return Center(child: Text(l10n.noFavoriteSongs, style: TextStyle(color: colorScheme.mutedForeground)));
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
                                              id: song['albumId']?.toString() ?? song['parent']?.toString() ?? song['coverArt']?.toString() ?? '',
                                              serverId: server.id,
                                              fallbackUrl: coverUrl,
                                            ),
                                    ),
                                    title: Text(
                                      song['title'] ?? l10n.unknownSong,
                                      style: TextStyle(
                                        color: colorScheme.foreground,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      song['artist'] ?? l10n.unknownArtist,
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
            error: (err, stack) => Center(child: Text(l10n.loadFavoritesFailed(err.toString()), style: TextStyle(color: colorScheme.destructive))),
          );
        },
        loading: () => Center(child: CircularProgressIndicator(color: colorScheme.foreground)),
        error: (err, stack) => Center(child: Text(l10n.loadServerStatusFailed, style: TextStyle(color: colorScheme.destructive))),
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
    final l10n = AppLocalizations.of(context)!;
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;
    final api = ref.watch(subsonicApiProvider);
    final networkState = ref.watch(networkProvider);

    final mutedIconColor = colorScheme.mutedForeground.withValues(alpha: 0.3);

    return Opacity(
      opacity: networkState.isOffline ? 0.3 : 1.0,
      child: SizedBox(
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
          onPressed: networkState.isOffline ? () {
            ZenifyToast.showError(context, l10n.serverOffline);
          } : () async {
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
          tooltip: _isFavorite ? l10n.removeFromFavorites : l10n.addToFavorites,
        ),
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
  Future<void> _handleToggle(bool turnOn) async {
    await ref.read(offlinePreferenceProvider.notifier).setFavoritesOffline(turnOn);
    final downloadService = ref.read(downloadServiceProvider);
    
    try {
      if (turnOn) {
        for (final song in widget.songs) {
          await downloadService.downloadSong(song, widget.serverId);
        }
      } else {
        for (final song in widget.songs) {
          await downloadService.deleteDownload(song['id'].toString());
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.offlineOperationFailed),
            backgroundColor: ShadTheme.of(context).colorScheme.destructive,
          ),
        );
      }
    } finally {
      ref.invalidate(downloadedTracksProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;
    final downloadedTracksAsync = ref.watch(downloadedTracksProvider);
    final downloadedTracks = downloadedTracksAsync.valueOrNull ?? [];
    final downloadProgress = ref.watch(downloadProgressProvider);

    final networkState = ref.watch(networkProvider);
    final isOffline = networkState.isOffline;
    
    final prefsState = ref.watch(offlinePreferenceProvider).valueOrNull;
    final effectiveOfflined = prefsState?.favoritesPreference ?? false;

    final String statusStr = effectiveOfflined ? l10n.offlineSyncEnabled : l10n.totalSongsCountWidget(widget.songs.length.toString());

    return Row(
      children: [
        // Play Bento Card
        Expanded(
          child: _PlayBentoCard(
            onPlay: () {
              ref.read(audioProvider.notifier).playQueue(widget.songs, 0);
            },
            onShuffle: () {
              final shuffled = List<dynamic>.from(widget.songs)..shuffle();
              ref.read(audioProvider.notifier).playQueue(shuffled, 0);
            },
          ),
        ),
        const SizedBox(width: 12),
        // Offline Bento Card
        Expanded(
          child: _OfflineBentoCard(
            effectiveOfflined: effectiveOfflined,
            isOffline: isOffline,
            statusStr: statusStr,
            songCount: widget.songs.length,
            onToggle: _handleToggle,
          ),
        ),
      ],
    );
  }
}

class _OfflineBentoCard extends StatefulWidget {
  final bool effectiveOfflined;
  final bool isOffline;
  final String statusStr;
  final int songCount;
  final Function(bool) onToggle;

  const _OfflineBentoCard({
    required this.effectiveOfflined,
    required this.isOffline,
    required this.statusStr,
    required this.songCount,
    required this.onToggle,
  });

  @override
  State<_OfflineBentoCard> createState() => _OfflineBentoCardState();
}

class _OfflineBentoCardState extends State<_OfflineBentoCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;

    final isDisabled = widget.isOffline;

    return MouseRegion(
      cursor: isDisabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: isDisabled ? null : () => widget.onToggle(!widget.effectiveOfflined),
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
                SizedBox(
                  height: 38,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: ShadSwitch(
                      value: widget.effectiveOfflined,
                      onChanged: isDisabled ? null : widget.onToggle,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    l10n.offlineFavoriteSongs,
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
                      l10n.songCountWidgetShort(widget.songCount.toString()),
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
                widget.statusStr,
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

class _PlayBentoCard extends StatefulWidget {
  final VoidCallback onPlay;
  final VoidCallback onShuffle;

  const _PlayBentoCard({
    required this.onPlay,
    required this.onShuffle,
  });

  @override
  State<_PlayBentoCard> createState() => _PlayBentoCardState();
}

class _PlayBentoCardState extends State<_PlayBentoCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
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
            SizedBox(
              height: 38,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _HoverablePlayIconButton(
                    icon: LucideIcons.play,
                    isPrimary: true,
                    onPressed: widget.onPlay,
                  ),
                  _HoverablePlayIconButton(
                    icon: LucideIcons.shuffle,
                    onPressed: widget.onShuffle,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.playAll,
              style: TextStyle(
                color: colorScheme.foreground,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.startPlayingFavoriteSongs,
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
    );
  }
}

class _HoverablePlayIconButton extends StatefulWidget {
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onPressed;

  const _HoverablePlayIconButton({
    required this.icon,
    this.isPrimary = false,
    required this.onPressed,
  });

  @override
  State<_HoverablePlayIconButton> createState() => _HoverablePlayIconButtonState();
}

class _HoverablePlayIconButtonState extends State<_HoverablePlayIconButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;
    
    final Color bgColor = widget.isPrimary 
        ? colorScheme.foreground 
        : colorScheme.secondary;
    
    final Color iconColor = widget.isPrimary 
        ? colorScheme.background 
        : colorScheme.foreground;

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
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  widget.icon,
                  size: 18,
                  color: iconColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
