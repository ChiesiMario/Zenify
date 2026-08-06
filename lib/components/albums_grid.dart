import 'package:zenify/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenify/components/album_card.dart';
import 'package:zenify/providers/app_providers.dart';
import 'package:zenify/providers/audio_provider.dart';
import 'package:zenify/screens/album_detail_screen.dart';
import 'package:zenify/screens/artist_detail_screen.dart';
import 'package:zenify/providers/download_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:zenify/router/app_router.dart';
import 'dart:convert';
import 'package:zenify/models/album.dart';

class AlbumsGrid extends ConsumerWidget {
  final List<dynamic> albums;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry padding;
  final bool isHome;
  final bool showYearInsteadOfArtist;
  final bool hideOfflineIcon;
  final VoidCallback? onLoadMore;
  final bool isLoadingMore;
  final int? totalCount;

  const AlbumsGrid({
    super.key,
    required this.albums,
    this.shrinkWrap = true,
    this.physics = const NeverScrollableScrollPhysics(),
    this.padding = EdgeInsets.zero,
    this.isHome = false,
    this.showYearInsteadOfArtist = false,
    this.hideOfflineIcon = false,
    this.onLoadMore,
    this.isLoadingMore = false,
    this.totalCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final server = ref.watch(activeServerProvider).value;
    final api = ref.watch(subsonicApiProvider);
    final networkState = ref.watch(networkProvider);
    final downloadedTracksAsync = ref.watch(downloadedTracksProvider);
    final downloadedTracks = downloadedTracksAsync.valueOrNull ?? [];
    final offlineAlbumIds = downloadedTracks
        .where((t) => t.isManualDownload && t.isComplete)
        .map((t) => t.albumId)
        .whereType<String>()
        .toSet();

    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth = constraints.maxWidth - padding.horizontal;
        const double spacing = 16.0;
        
        // 階梯式斷點與對應的列數、單格基準寬度
        int crossAxisCount;
        double cellWidth;
        
        if (isHome) {
          if (availableWidth < 480) {
            crossAxisCount = 3;
            cellWidth = (availableWidth - spacing * 2) / crossAxisCount; 
          } else if (availableWidth < 648) {
            crossAxisCount = 3;
            cellWidth = 140.0;
          } else {
            crossAxisCount = 4 + ((availableWidth - 648) ~/ 200);
            cellWidth = 150.0;
          }
        } else {
          if (availableWidth < 480) {
            crossAxisCount = 3;
            cellWidth = (availableWidth - spacing * 2) / crossAxisCount;
          } else {
            crossAxisCount = ((availableWidth + spacing) / (130.0 + spacing)).floor();
            if (crossAxisCount < 3) crossAxisCount = 3;
            cellWidth = 130.0;
          }
        }

        final double totalHorizontalSpacing = spacing * (crossAxisCount - 1);
        final double gridWidth = (cellWidth * crossAxisCount) + totalHorizontalSpacing;
        
        // cellHeight = 正方形圖片(cellWidth) + 文字預留高度(~38px)
        final double cellHeight = cellWidth + 38.0; 
        final double childAspectRatio = cellWidth / cellHeight;

        final EdgeInsets resolvedBasePadding = padding.resolve(TextDirection.ltr);
        
        EdgeInsets finalPadding;
        if (availableWidth >= 480) {
          if (isHome) {
            final double sidePadding = (constraints.maxWidth - gridWidth) / 2;
            finalPadding = EdgeInsets.only(
              left: sidePadding,
              right: sidePadding - 2.0 > 0 ? sidePadding - 2.0 : 0.0,
              top: resolvedBasePadding.top,
              bottom: resolvedBasePadding.bottom,
            );
          } else {
            final double leftPadding = resolvedBasePadding.left;
            double rightPadding = constraints.maxWidth - 2.0 - leftPadding - gridWidth;
            if (rightPadding < 0) rightPadding = 0;
            finalPadding = EdgeInsets.only(
              left: leftPadding,
              right: rightPadding,
              top: resolvedBasePadding.top,
              bottom: resolvedBasePadding.bottom,
            );
          }
        } else {
          finalPadding = resolvedBasePadding;
        }

        Widget grid = Padding(
          padding: const EdgeInsets.only(right: 2.0),
          child: GridView.builder(
          shrinkWrap: shrinkWrap,
          physics: physics,
          padding: finalPadding,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: 16,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: totalCount ?? albums.length,
          itemBuilder: (context, index) {
            if (index >= albums.length) {
              if (onLoadMore != null && !isLoadingMore) {
                Future.microtask(() => onLoadMore!());
              }
              // Placeholder
              return Opacity(
                opacity: 0.3,
                child: AlbumCard(
                  title: '...',
                  artist: '...',
                  coverArtId: null,
                  fallbackCoverUrl: null,
                  serverId: 0,
                  isDisabled: true,
                  onTap: () {},
                ),
              );
            }
            final item = albums[index];
            late Map<String, dynamic> album;
            if (item is Album) {
              album = jsonDecode(item.rawData) as Map<String, dynamic>;
            } else {
              album = item as Map<String, dynamic>;
            }
            final title = album['title'] ?? album['name'] ?? l10n.unknownAlbum;
            final artist = showYearInsteadOfArtist 
                ? (album['year']?.toString() ?? l10n.unknownYear) 
                : (album['artist'] ?? album['year']?.toString() ?? l10n.unknownArtist);
            final artistId = album['artistId'];
            final albumId = album['id']?.toString();
            final albumCoverId = album['coverArt'] ?? albumId;
            final fallbackUrl = api != null && albumCoverId != null 
                ? api.getCoverArtUrl(albumCoverId, size: 250) 
                : null;
            final isOffline = offlineAlbumIds.contains(albumId);
            final isDisabled = networkState.isOffline && !isOffline;
            
            // 全域覆蓋狀態 (Override State)
            final isStarred = albumId != null 
                ? (ref.watch(favoriteStatusProvider.select((map) => map[albumId])) ?? (album['starred'] != null))
                : false;
            
            return AlbumCard(
              title: title,
              artist: artist,
              coverArtId: albumCoverId,
              fallbackCoverUrl: fallbackUrl,
              serverId: server?.id ?? 0,
              yearText: album['year']?.toString(),
              isOfflineAlbum: hideOfflineIcon ? false : isOffline,
              padding: 0,
              isDisabled: isDisabled,
              isArtistDisabled: networkState.isOffline,
              isStarred: isStarred,
              onStarToggle: api == null || albumId == null ? null : (shouldStar) async {
                await ref.read(favoriteStatusProvider.notifier).toggleStar(
                  id: albumId,
                  isCurrentlyStarred: !shouldStar,
                  api: api,
                  isAlbum: true,
                );
              },
              onTap: () {
                if (album['id'] != null) {
                  context.pushBranch('album/${album['id']}');
                }
              },
              onPlayTap: () async {
                final albumId = album['id'];
                if (albumId != null) {
                  try {
                    final albumData = await ref.read(albumDetailProvider(albumId.toString()).future);
                    if (albumData != null) {
                      var songs = albumData['song'];
                      if (songs != null) {
                        if (songs is! List) songs = [songs];
                        if (songs.isNotEmpty) {
                          ref.read(audioProvider.notifier).playQueue(List<dynamic>.from(songs), 0);
                        }
                      }
                    }
                  } catch (e) {
                    print('Error playing album from grid: $e');
                  }
                }
              },
              onArtistTap: (!showYearInsteadOfArtist && artistId != null)
                  ? () {
                      context.pushBranch('artist/$artistId', extra: artist);
                    }
                  : null,
            );
          },
        ),
      );

      if (onLoadMore != null) {
        grid = NotificationListener<ScrollNotification>(
          onNotification: (scrollInfo) {
            if (!isLoadingMore &&
                scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
              onLoadMore!();
            }
            return false; // let it bubble up if needed
          },
          child: grid,
        );
      }

      if (isLoadingMore) {
        grid = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            shrinkWrap ? grid : Expanded(child: grid),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
        );
      }

      return grid;
      },
    );
  }
}
