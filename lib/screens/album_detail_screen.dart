import 'package:zenify/l10n/app_localizations.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:zenify/components/zenify_divider_dot.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenify/providers/app_providers.dart';
import 'package:zenify/providers/audio_provider.dart';
import 'package:zenify/providers/download_provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:zenify/components/local_cover_image.dart';
import 'package:zenify/screens/artist_detail_screen.dart';
import 'package:zenify/components/zenify_toast.dart';
import 'package:file_selector/file_selector.dart';
import 'package:zenify/services/image_service.dart';
import 'package:zenify/providers/offline_preference_provider.dart';
import 'package:zenify/utils/responsive.dart';
import 'package:zenify/components/zenify_song_list.dart';

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
    final l10n = AppLocalizations.of(context)!;
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
            return Center(child: Text(l10n.albumInfoNotFound, style: TextStyle(color: colorScheme.mutedForeground)));
          }

          final coverUrl = api != null && album['coverArt'] != null
              ? api.getCoverArtUrl(album['coverArt'])
              : null;
              
          var songs = album['song'];
          if (songs != null && songs is! List) {
            songs = [songs];
          }
          final songList = songs as List<dynamic>? ?? [];
          final albumIdStr = album['id']?.toString();
          final isAlbumStarred = albumIdStr != null 
              ? (ref.watch(favoriteStatusProvider.select((map) => map[albumIdStr])) ?? (album['starred'] != null))
              : false;

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

          return CustomScrollView(
            slivers: [
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                  // Header
                  SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: getResponsiveMaxWidth(context)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Album Cover
                              Builder(
                            builder: (context) {
                              bool isCoverHovered = false;
                              bool isEnlargeHovered = false;
                              bool isStarHovered = false;
                              bool isUpdatingStar = false;
                              return StatefulBuilder(
                                builder: (context, setState) {
                                  return MouseRegion(
                                    onEnter: (_) => setState(() => isCoverHovered = true),
                                    onExit: (_) => setState(() => isCoverHovered = false),
                                    child: Container(
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
                                            // Overlay gradient on hover
                                            AnimatedOpacity(
                                              opacity: isCoverHovered ? 1.0 : 0.0,
                                              duration: const Duration(milliseconds: 200),
                                              child: Container(
                                                color: Colors.black.withValues(alpha: 0.50),
                                              ),
                                            ),
                                            // Action Buttons on Hover
                                            if (isCoverHovered) ...[
                                              // Top Right: View Original Image
                                              Positioned(
                                                top: 10,
                                                right: 10,
                                                child: MouseRegion(
                                                  cursor: SystemMouseCursors.click,
                                                  onEnter: (_) => setState(() => isEnlargeHovered = true),
                                                  onExit: (_) => setState(() => isEnlargeHovered = false),
                                                  child: GestureDetector(
                                                    onTap: () {
                                                    showDialog(
                                                      context: context,
                                                      barrierColor: colorScheme.background,
                                                      builder: (context) {
                                                        bool isDialogHovered = false;
                                                        return StatefulBuilder(
                                                          builder: (context, setDialogState) {
                                                            return GestureDetector(
                                                              onTap: () => Navigator.pop(context),
                                                              child: Center(
                                                                child: MouseRegion(
                                                                  onEnter: (_) => setDialogState(() => isDialogHovered = true),
                                                                  onExit: (_) => setDialogState(() => isDialogHovered = false),
                                                                  child: Stack(
                                                                    alignment: Alignment.center,
                                                                    children: [
                                                                      Container(
                                                                        constraints: BoxConstraints(
                                                                          maxWidth: MediaQuery.of(context).size.width * 0.7,
                                                                          maxHeight: MediaQuery.of(context).size.height * 0.8,
                                                                        ),
                                                                        decoration: BoxDecoration(
                                                                          boxShadow: [
                                                                            BoxShadow(
                                                                              color: Colors.black.withValues(alpha: 0.3),
                                                                              blurRadius: 40,
                                                                              offset: const Offset(0, 20),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                        child: coverUrl == null 
                                                                          ? const SizedBox.shrink()
                                                                          : LocalCoverImage(
                                                                              id: album['albumId']?.toString() ?? album['parent']?.toString() ?? album['coverArt']?.toString() ?? album['id'],
                                                                              serverId: server?.id ?? 0,
                                                                              fallbackUrl: coverUrl,
                                                                              isThumb: false,
                                                                              fit: BoxFit.contain,
                                                                            ),
                                                                      ),
                                                                      if (isDialogHovered)
                                                                        Positioned.fill(
                                                                          child: Container(color: Colors.black.withValues(alpha: 0.4)),
                                                                        ),
                                                                      if (isDialogHovered)
                                                                        Positioned.fill(
                                                                          child: LayoutBuilder(
                                                                            builder: (context, constraints) {
                                                                              final size = (constraints.maxWidth * 0.15).clamp(16.0, 48.0);
                                                                              return Center(
                                                                                child: IconButton(
                                                                                  iconSize: size,
                                                                                  icon: Icon(LucideIcons.download, color: Colors.white, size: size),
                                                                                  style: IconButton.styleFrom(
                                                                                    hoverColor: Colors.black,
                                                                                    shape: RoundedRectangleBorder(
                                                                                      borderRadius: BorderRadius.circular(14),
                                                                                    ),
                                                                                  ),
                                                                                  onPressed: () async {
                                                                            final coverId = album['albumId']?.toString() ?? album['parent']?.toString() ?? album['coverArt']?.toString() ?? album['id'];
                                                                            final highResPath = ImageService().getCoverPathSync(coverId, server?.id ?? 0, isThumb: false);
                                                                            final thumbPath = ImageService().getCoverPathSync(coverId, server?.id ?? 0, isThumb: true);
                                                                            File sourceFile = File(highResPath);
                                                                            if (!sourceFile.existsSync()) {
                                                                              sourceFile = File(thumbPath);
                                                                            }
                                                                            if (!sourceFile.existsSync()) {
                                                                              ZenifyToast.showError(context, l10n.cannotGetLocalImage);
                                                                              return;
                                                                            }
                                                                            final saveLocation = await getSaveLocation(
                                                                              suggestedName: '${album['name'] ?? 'cover'}.png',
                                                                              acceptedTypeGroups: [
                                                                                const XTypeGroup(label: 'PNG Image', extensions: ['png']),
                                                                              ],
                                                                            );
                                                                            if (saveLocation != null) {
                                                                              try {
                                                                                await sourceFile.copy(saveLocation.path);
                                                                                if (context.mounted) ZenifyToast.showSuccess(context, l10n.imageExportedSuccessfully);
                                                                              } catch (e) {
                                                                                if (context.mounted) ZenifyToast.showError(context, l10n.exportFailed(e.toString()));
                                                                              }
                                                                            }
                                                                                   }
                                                                                 ),
                                                                               );
                                                                             },
                                                                           ),
                                                                         ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                        );
                                                      },
                                                    );
                                                  },
                                                  child: Container(
                                                    padding: const EdgeInsets.all(6),
                                                    decoration: BoxDecoration(
                                                      color: isEnlargeHovered ? Colors.black : Colors.white,
                                                      shape: BoxShape.circle,
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black.withValues(alpha: 0.2),
                                                          blurRadius: 6,
                                                          offset: const Offset(0, 2),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Icon(
                                                      LucideIcons.maximize2,
                                                      color: isEnlargeHovered ? Colors.white : Colors.black,
                                                      size: 16,
                                                    ),
                                                  ),
                                                ),
                                                ),
                                              ),
                                              // Bottom Right: Star/Unstar
                                              Positioned(
                                                bottom: 10,
                                                right: 10,
                                                child: MouseRegion(
                                                  cursor: SystemMouseCursors.click,
                                                  onEnter: (_) {
                                                    if (!networkState.isOffline) setState(() => isStarHovered = true);
                                                  },
                                                  onExit: (_) {
                                                    if (!networkState.isOffline) setState(() => isStarHovered = false);
                                                  },
                                                  child: GestureDetector(
                                                    onTap: networkState.isOffline
                                                      ? () {
                                                          ZenifyToast.showError(context, l10n.serverOffline);
                                                        }
                                                        : (isUpdatingStar ? null : () async {
                                                          setState(() => isUpdatingStar = true);
                                                          try {
                                                            if (api != null && albumIdStr != null) {
                                                              await ref.read(favoriteStatusProvider.notifier).toggleStar(
                                                                id: albumIdStr,
                                                                isCurrentlyStarred: isAlbumStarred,
                                                                api: api,
                                                                isAlbum: true,
                                                              );
                                                            }
                                                          } catch (e) {
                                                            if (context.mounted) ZenifyToast.showError(context, l10n.operationFailed(e.toString()));
                                                          } finally {
                                                            if (context.mounted) setState(() => isUpdatingStar = false);
                                                          }
                                                        }),
                                                    child: Opacity(
                                                      opacity: networkState.isOffline ? 0.5 : 1.0,
                                                      child: Container(
                                                        padding: const EdgeInsets.all(6),
                                                        decoration: BoxDecoration(
                                                          color: isStarHovered ? Colors.black : Colors.white,
                                                          shape: BoxShape.circle,
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: Colors.black.withValues(alpha: 0.2),
                                                              blurRadius: 6,
                                                              offset: const Offset(0, 2),
                                                            ),
                                                          ],
                                                        ),
                                                        child: isUpdatingStar
                                                            ? SizedBox(
                                                                width: 16,
                                                                height: 16,
                                                                child: CircularProgressIndicator(
                                                                  strokeWidth: 2,
                                                                  color: isStarHovered ? Colors.white : Colors.black,
                                                                ),
                                                              )
                                                            : Icon(
                                                                isAlbumStarred ? Icons.favorite : Icons.favorite_border,
                                                                color: isAlbumStarred 
                                                                  ? Colors.red 
                                                                  : (isStarHovered ? Colors.white : Colors.black),
                                                                size: 16,
                                                              ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          // Typography
                          Text(
                            album['name'] ?? l10n.unknownAlbum,
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
                                        onTap: networkState.isOffline ? () {
                                          ZenifyToast.showError(context, l10n.serverOffline);
                                        } : () {
                                          final artistId = album['artistId'];
                                          if (artistId != null) {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                settings: RouteSettings(name: album['artist']),
                                                builder: (context) => ArtistDetailScreen(
                                                  artistId: artistId, 
                                                  artistName: album['artist'] ?? l10n.unknownArtist,
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                        child: Text(
                                          album['artist'] ?? l10n.unknownArtist,
                                          style: TextStyle(
                                            color: colorScheme.mutedForeground,
                                            fontSize: 13,
                                            fontWeight: FontWeight.normal,
                                            height: 1.1,
                                            decoration: (isHovered && !networkState.isOffline) ? TextDecoration.underline : TextDecoration.none,
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
                              parts.add(l10n.songCount(songList.length.toString()));
                              
                              final List<InlineSpan> spans = [];
                              for (int i = 0; i < parts.length; i++) {
                                spans.add(TextSpan(text: parts[i]));
                                if (i != parts.length - 1) {
                                  spans.add(const WidgetSpan(alignment: PlaceholderAlignment.middle, child: ZenifyDividerDot()));
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
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(LucideIcons.play, size: 20),
                                      const SizedBox(width: 8),
                                      Text(l10n.playerPlay, style: const TextStyle(fontSize: 16)),
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
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(LucideIcons.shuffle, size: 20),
                                      const SizedBox(width: 8),
                                      Text(l10n.playerShuffle, style: const TextStyle(fontSize: 16)),
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
                              constraints: BoxConstraints(maxWidth: getResponsiveMaxWidth(context)),
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
                            constraints: BoxConstraints(maxWidth: getResponsiveMaxWidth(context)),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: ZenifySongList(
                              songs: group.map((item) {
                                final absoluteIndex = item['index'] as int;
                                final song = item['song'];
                                final songId = song['id']?.toString() ?? '';
                                final isOfflineUnplayable = networkState.isOffline && !downloadedIds.contains(songId);
                                
                                return SongTileData(
                                  id: songId,
                                  title: song['title'] ?? l10n.unknownSong,
                                  subtitle: song['artist'] != album['artist'] ? song['artist'] : null,
                                  trackNumber: song['track']?.toString() ?? '',
                                  duration: song['duration'] != null ? _formatDuration(song['duration']) : '--:--',
                                  isOfflineUnplayable: isOfflineUnplayable,
                                  serverId: server?.id ?? 0,
                                  rawSong: song,
                                  onTap: () {
                                    ref.read(audioProvider.notifier).playQueue(songList, absoluteIndex);
                                  },
                                  isFavorite: song['starred'] != null,
                                );
                              }).toList(),
                              showTrackNumber: true,
                              showFavoriteButton: true,
                              shrinkWrap: true,
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
                          constraints: BoxConstraints(maxWidth: getResponsiveMaxWidth(context)),
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
                                        albumId: album['id']?.toString() ?? '',
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
              );
        },
        loading: () => Center(child: CircularProgressIndicator(color: colorScheme.foreground)),
        error: (err, stack) => Center(child: Text(l10n.loadFailed(err.toString()), style: TextStyle(color: colorScheme.destructive))),
      ),
    );
  }
}

class _AlbumOfflineBentoCard extends ConsumerStatefulWidget {
  final List<dynamic> songList;
  final int serverId;
  final String albumId;

  const _AlbumOfflineBentoCard({
    required this.songList,
    required this.serverId,
    required this.albumId,
  });

  @override
  ConsumerState<_AlbumOfflineBentoCard> createState() => _AlbumOfflineBentoCardState();
}

class _AlbumOfflineBentoCardState extends ConsumerState<_AlbumOfflineBentoCard> {
  bool _isHovered = false;

  Future<void> _handleToggle(bool turnOn) async {
    if (widget.albumId.isEmpty) return;
    await ref.read(offlinePreferenceProvider.notifier).setAlbumOffline(widget.albumId, turnOn);
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
    final effectiveOfflined = prefsState?.albumPreferences[widget.albumId] ?? false;

    final String titleStr = effectiveOfflined ? l10n.offlineStatus : l10n.offline;
    final String subtitleStr = effectiveOfflined ? l10n.savedToOfflineMusic : l10n.offlineAllAlbumSongs;

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

    final isDisabled = isOffline;

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
                  Flexible(
                    child: Container(
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
                            TextSpan(text: l10n.songCountWidget(widget.songList.length.toString())),
                            if (sizeFormatted.isNotEmpty) ...[
                              const WidgetSpan(alignment: PlaceholderAlignment.middle, child: ZenifyDividerDot()),
                              TextSpan(text: sizeFormatted),
                            ],
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colorScheme.mutedForeground,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
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
    final l10n = AppLocalizations.of(context)!;
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
      {'id': 'qq', 'name': l10n.qqMusic, 'icon': LucideIcons.disc},
      {'id': 'netease', 'name': l10n.neteaseMusic, 'icon': LucideIcons.flame},
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
          l10n.searchInOtherPlatforms,
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
    final l10n = AppLocalizations.of(context)!;
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
