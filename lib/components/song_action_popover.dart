import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:zenify/components/zenify_toast.dart';
import 'package:zenify/l10n/app_localizations.dart';
import 'package:zenify/providers/app_providers.dart';
import 'package:zenify/providers/audio_provider.dart';
import 'package:zenify/providers/download_provider.dart';
import 'package:zenify/screens/album_detail_screen.dart';
import 'package:zenify/screens/artist_detail_screen.dart';
import 'package:zenify/providers/ui_providers.dart';

import 'package:zenify/components/zenify_popover.dart';

class SongActionPopover extends ConsumerWidget {
  final dynamic song;
  final int serverId;
  final Widget child;

  const SongActionPopover({
    super.key,
    required this.song,
    required this.serverId,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ZenifyPopover(
      onOpenChanged: (isOpen) {
        if (isOpen) {
          ref.read(activePopoverSongIdProvider.notifier).state = song['id'].toString();
        } else {
          final currentId = ref.read(activePopoverSongIdProvider);
          if (currentId == song['id'].toString()) {
            ref.read(activePopoverSongIdProvider.notifier).state = null;
          }
        }
      },
      child: child,
      builder: (context, close) => _SongActionPopoverContent(
        song: song,
        serverId: serverId,
        onClose: close,
      ),
    );
  }
}

class _SongActionPopoverContent extends ConsumerWidget {
  final dynamic song;
  final int serverId;
  final VoidCallback onClose;

  const _SongActionPopoverContent({
    required this.song,
    required this.serverId,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;
    final networkState = ref.watch(networkProvider);

    return IntrinsicWidth(
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ZenifyPopoverItem(
              icon: LucideIcons.playCircle,
              label: l10n.playerPlayNext,
              colorScheme: colorScheme,
              onTap: () {
                ref.read(audioProvider.notifier).playNext(song);
                onClose();
                ZenifyToast.showSuccess(context, l10n.addedToQueue);
              },
            ),
            ZenifyPopoverItem(
              icon: LucideIcons.listPlus,
              label: l10n.addToQueue,
              colorScheme: colorScheme,
              onTap: () {
                ref.read(audioProvider.notifier).addToQueue(song);
                onClose();
                ZenifyToast.showSuccess(context, l10n.addedToQueue);
              },
            ),
            ZenifyPopoverItem(
              icon: LucideIcons.disc,
              label: l10n.goAlbum,
              colorScheme: colorScheme,
              onTap: () {
                onClose();
                final albumId = song['albumId']?.toString();
                if (albumId != null) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      settings: RouteSettings(name: song['album']),
                      builder: (context) => AlbumDetailScreen(
                        albumId: albumId,
                      ),
                    ),
                  );
                }
              },
            ),
            ZenifyPopoverItem(
              icon: LucideIcons.mic,
              label: l10n.goArtist,
              colorScheme: colorScheme,
              onTap: () {
                onClose();
                final artistId = song['artistId']?.toString();
                if (artistId != null) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      settings: RouteSettings(name: song['artist']),
                      builder: (context) => ArtistDetailScreen(
                        artistId: artistId,
                        artistName: song['artist']?.toString() ?? l10n.unknownArtist,
                      ),
                    ),
                  );
                }
              },
            ),
            if (!networkState.isOffline)
              ZenifyPopoverItem(
                icon: LucideIcons.download,
                label: l10n.download,
                colorScheme: colorScheme,
                onTap: () {
                  onClose();
                  ref.read(downloadServiceProvider).downloadSong(song, serverId, isManual: true);
                  ZenifyToast.showSuccess(context, l10n.downloadStarted);
                },
              ),
          ],
        ),
      ),
    );
  }
}
