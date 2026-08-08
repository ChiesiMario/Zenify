import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:zenify/components/local_cover_image.dart';
import 'package:zenify/components/zenify_toast.dart';
import 'package:zenify/providers/app_providers.dart';
import 'package:zenify/l10n/app_localizations.dart';

class SongTileData {
  final String id;
  final String title;
  final String? subtitle;
  final String? coverId;
  final String? fallbackCoverUrl;
  final String? trackNumber;
  final String duration;
  final bool isOfflineUnplayable;
  final int serverId;
  final VoidCallback onTap;
  final Widget? customTrailing;
  final bool isFavorite;

  const SongTileData({
    required this.id,
    required this.title,
    this.subtitle,
    this.coverId,
    this.fallbackCoverUrl,
    this.trackNumber,
    required this.duration,
    required this.isOfflineUnplayable,
    required this.serverId,
    required this.onTap,
    this.customTrailing,
    this.isFavorite = false,
  });
}

class ZenifyFavoriteSongButton extends ConsumerWidget {
  final String songId;
  final bool defaultState;

  const ZenifyFavoriteSongButton({
    super.key,
    required this.songId,
    this.defaultState = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;
    final api = ref.watch(subsonicApiProvider);
    final networkState = ref.watch(networkProvider);

    final isFavorite = ref.watch(favoriteStatusProvider.select((map) => map[songId])) ?? defaultState;
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
            isFavorite ? Icons.favorite : LucideIcons.heart,
            color: isFavorite ? const Color(0xFFEF4444) : mutedIconColor,
            size: 16,
          ),
          onPressed: networkState.isOffline
              ? () {
                  ZenifyToast.showError(context, l10n.serverOffline);
                }
              : () async {
                  if (api == null) return;
                  await ref.read(favoriteStatusProvider.notifier).toggleStar(
                        id: songId,
                        isCurrentlyStarred: isFavorite,
                        api: api,
                        isAlbum: false,
                      );
                },
          tooltip: isFavorite ? l10n.removeFromFavorites : l10n.addToFavorites,
        ),
      ),
    );
  }
}

class ZenifySongList extends ConsumerWidget {
  final List<SongTileData> songs;
  final bool showCover;
  final bool showTrackNumber;
  final bool showFavoriteButton;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry padding;
  final bool useSliver; // If true, returns a SliverList inside SliverPadding

  const ZenifySongList({
    super.key,
    required this.songs,
    this.showCover = false,
    this.showTrackNumber = false,
    this.showFavoriteButton = true,
    this.shrinkWrap = false,
    this.physics,
    this.padding = EdgeInsets.zero,
    this.useSliver = false,
  });

  Widget _buildTile(BuildContext context, ShadColorScheme colorScheme, AppLocalizations l10n, SongTileData song, int index, bool isFirst, bool isLast) {
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
        child: Opacity(
          opacity: song.isOfflineUnplayable ? 0.3 : 1.0,
          child: ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                top: isFirst ? const Radius.circular(12) : Radius.zero,
                bottom: isLast ? const Radius.circular(12) : Radius.zero,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: _buildLeading(colorScheme, song),
            title: Text(
              song.title.isNotEmpty ? song.title : l10n.unknownSong,
              style: TextStyle(
                color: colorScheme.foreground,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: song.subtitle != null && song.subtitle!.isNotEmpty
                ? Text(
                    song.subtitle!,
                    style: TextStyle(color: colorScheme.mutedForeground, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
            trailing: _buildTrailing(colorScheme, song),
            onTap: song.isOfflineUnplayable ? null : song.onTap,
          ),
        ),
      ),
    );
  }

  Widget? _buildLeading(ShadColorScheme colorScheme, SongTileData song) {
    if (showCover) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: colorScheme.muted,
          borderRadius: BorderRadius.circular(6),
        ),
        clipBehavior: Clip.antiAlias,
        child: song.coverId != null || song.fallbackCoverUrl != null
            ? LocalCoverImage(
                id: song.coverId ?? '',
                serverId: song.serverId,
                fallbackUrl: song.fallbackCoverUrl,
              )
            : Icon(LucideIcons.music, size: 20, color: colorScheme.mutedForeground),
      );
    }
    if (showTrackNumber) {
      return SizedBox(
        width: 24,
        child: Center(
          child: Text(
            song.trackNumber ?? '',
            style: TextStyle(color: colorScheme.mutedForeground, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }
    return null;
  }

  Widget _buildTrailing(ShadColorScheme colorScheme, SongTileData song) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (song.customTrailing != null) song.customTrailing!,
        if (song.customTrailing != null) const SizedBox(width: 4),
        Text(
          song.duration,
          style: TextStyle(color: colorScheme.mutedForeground, fontSize: 13, fontWeight: FontWeight.w500),
        ),
        if (showFavoriteButton) ...[
          const SizedBox(width: 4),
          ZenifyFavoriteSongButton(songId: song.id, defaultState: song.isFavorite),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (songs.isEmpty) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context)!;
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;

    if (useSliver) {
      return SliverPadding(
        padding: padding,
        sliver: DecoratedSliver(
          decoration: BoxDecoration(
            color: colorScheme.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.border, width: 1.0),
          ),
          sliver: SliverList.builder(
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];
              final isFirst = index == 0;
              final isLast = index == songs.length - 1;
              return _buildTile(context, colorScheme, l10n, song, index, isFirst, isLast);
            },
          ),
        ),
      );
    }

    return Padding(
      padding: padding,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.border, width: 1.0),
        ),
        child: ListView.builder(
          shrinkWrap: shrinkWrap,
          physics: physics ?? (shrinkWrap ? const NeverScrollableScrollPhysics() : null),
          padding: EdgeInsets.zero,
          itemCount: songs.length,
          itemBuilder: (context, index) {
            final song = songs[index];
            final isFirst = index == 0;
            final isLast = index == songs.length - 1;
            return _buildTile(context, colorScheme, l10n, song, index, isFirst, isLast);
          },
        ),
      ),
    );
  }
}
