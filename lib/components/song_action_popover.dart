import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:zenify/components/zenify_button.dart';
import 'package:zenify/components/zenify_dialog.dart';
import 'package:zenify/components/zenify_toast.dart';
import 'package:zenify/l10n/app_localizations.dart';
import 'package:zenify/providers/app_providers.dart';
import 'package:zenify/providers/audio_provider.dart';
import 'package:zenify/providers/download_provider.dart';
import 'package:zenify/screens/album_detail_screen.dart';
import 'package:zenify/screens/artist_detail_screen.dart';
import 'package:zenify/views/playlists_view.dart';
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

    final downloadedTracksAsync = ref.watch(downloadedTracksProvider);
    final songId = song['id']?.toString();
    final isDownloaded = downloadedTracksAsync.maybeWhen(
      data: (tracks) => tracks.any((t) => t.songId == songId),
      orElse: () => false,
    );

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
            ZenifyPopoverDivider(colorScheme: colorScheme),
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
            if (!networkState.isOffline) ...[
              ZenifyPopoverDivider(colorScheme: colorScheme),
              _AddToPlaylistSubmenuItem(
                song: song,
                serverId: serverId,
                colorScheme: colorScheme,
                onClose: onClose,
              ),
            ],
            if (isDownloaded) ...[
              ZenifyPopoverDivider(colorScheme: colorScheme),
              ZenifyPopoverItem(
                icon: LucideIcons.trash2,
                label: l10n.delete,
                colorScheme: colorScheme,
                isDestructive: true,
                onTap: () async {
                  onClose();
                  if (songId != null) {
                    await ref.read(downloadServiceProvider).deleteDownload(songId);
                    ref.invalidate(downloadedTracksProvider);
                  }
                },
              ),
            ] else if (!networkState.isOffline) ...[
              ZenifyPopoverDivider(colorScheme: colorScheme),
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
          ],
        ),
      ),
    );
  }
}

class _AddToPlaylistSubmenuItem extends ConsumerStatefulWidget {
  final dynamic song;
  final int serverId;
  final ShadColorScheme colorScheme;
  final VoidCallback onClose;

  const _AddToPlaylistSubmenuItem({
    required this.song,
    required this.serverId,
    required this.colorScheme,
    required this.onClose,
  });

  @override
  ConsumerState<_AddToPlaylistSubmenuItem> createState() => _AddToPlaylistSubmenuItemState();
}

class _AddToPlaylistSubmenuItemState extends ConsumerState<_AddToPlaylistSubmenuItem> {
  final ShadPopoverController _popoverController = ShadPopoverController();
  Timer? _hideTimer;

  void _showSubmenu() {
    _hideTimer?.cancel();
    _popoverController.show();
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(milliseconds: 220), () {
      if (mounted) {
        _popoverController.hide();
      }
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _popoverController.dispose();
    super.dispose();
  }

  Future<void> _showCreatePlaylistDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final api = ref.read(subsonicApiProvider);
    if (api == null) return;

    final controller = TextEditingController();
    final focusNode = FocusNode();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final colorScheme = ShadTheme.of(context).colorScheme;
          return ZenifyDialog(
            icon: LucideIcons.listPlus,
            iconColor: colorScheme.primary,
            title: l10n.createPlaylist,
            description: l10n.createPlaylistDesc,
            content: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: focusNode.hasFocus ? colorScheme.background : colorScheme.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: focusNode.hasFocus ? colorScheme.primary : colorScheme.border,
                    width: 1.0,
                  ),
                ),
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  autofocus: true,
                  style: TextStyle(color: colorScheme.foreground, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: l10n.playlistName,
                    hintStyle: TextStyle(color: colorScheme.mutedForeground.withValues(alpha: 0.6), fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  onChanged: (_) => setDialogState(() {}),
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      Navigator.pop(dialogContext, true);
                    }
                  },
                ),
              ),
            ),
            actions: [
              ZenifyButton(
                variant: ZenifyButtonVariant.outline,
                onPressed: () => Navigator.pop(dialogContext, false),
                text: l10n.cancel,
              ),
              ZenifyButton(
                variant: ZenifyButtonVariant.primary,
                onPressed: controller.text.trim().isEmpty
                    ? null
                    : () => Navigator.pop(dialogContext, true),
                text: l10n.confirm,
              ),
            ],
          );
        },
      ),
    );

    if (result == true && controller.text.trim().isNotEmpty) {
      final name = controller.text.trim();
      final songId = widget.song['id']?.toString();
      final success = await api.createPlaylist(name, songId: songId);
      ref.invalidate(playlistsProvider);
      if (context.mounted) {
        if (success) {
          ZenifyToast.showSuccess(context, l10n.addedToPlaylist);
        } else {
          ZenifyToast.showError(context, l10n.createPlaylistFailed);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final playlistsAsync = ref.watch(playlistsProvider);
    final api = ref.watch(subsonicApiProvider);

    return MouseRegion(
      onEnter: (_) => _showSubmenu(),
      onExit: (_) => _scheduleHide(),
      child: ShadPopover(
        padding: EdgeInsets.zero,
        controller: _popoverController,
        anchor: const ShadAnchor(
          childAlignment: Alignment.topRight,
          overlayAlignment: Alignment.topLeft,
          offset: Offset(-14, -4),
        ),
        popover: (popoverCtx) => MouseRegion(
          onEnter: (_) => _showSubmenu(),
          onExit: (_) => _scheduleHide(),
          child: IntrinsicWidth(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: 260,
                minWidth: 160,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ZenifyPopoverItem(
                      icon: LucideIcons.plus,
                      label: l10n.createPlaylist,
                      colorScheme: widget.colorScheme,
                      onTap: () {
                        _popoverController.hide();
                        widget.onClose();
                        _showCreatePlaylistDialog(context);
                      },
                    ),
                    playlistsAsync.when(
                      data: (playlists) {
                        if (playlists.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ZenifyPopoverDivider(colorScheme: widget.colorScheme),
                            ...playlists.map((playlist) {
                              final pName = playlist['name']?.toString() ?? 'Playlist';
                              final pId = playlist['id']?.toString();
                              return ZenifyPopoverItem(
                                icon: LucideIcons.listMusic,
                                label: pName,
                                colorScheme: widget.colorScheme,
                                onTap: () async {
                                  _popoverController.hide();
                                  widget.onClose();
                                  if (pId != null && api != null) {
                                    final songId = widget.song['id']?.toString();
                                    if (songId != null) {
                                      final ok = await api.updatePlaylist(pId, songIdToAdd: songId);
                                      ref.invalidate(playlistsProvider);
                                      if (context.mounted) {
                                        if (ok) {
                                          ZenifyToast.showSuccess(context, '${l10n.addedToPlaylist}: $pName');
                                        } else {
                                          ZenifyToast.showError(context, l10n.operationFailed('Subsonic Error'));
                                        }
                                      }
                                    }
                                  }
                                },
                              );
                            }),
                          ],
                        );
                      },
                      loading: () => const Padding(
                        padding: EdgeInsets.all(12),
                        child: Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        child: ZenifyPopoverItem(
          icon: LucideIcons.listPlus,
          label: l10n.addToPlaylist,
          colorScheme: widget.colorScheme,
          onTap: () {
            _showSubmenu();
          },
        ),
      ),
    );
  }
}
