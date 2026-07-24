import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenify/components/album_card.dart';
import 'package:zenify/providers/app_providers.dart';
import 'package:zenify/screens/album_detail_screen.dart';
import 'package:zenify/screens/artist_detail_screen.dart';

class AlbumsGrid extends ConsumerWidget {
  final List<dynamic> albums;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry padding;

  final bool isHome;

  const AlbumsGrid({
    super.key,
    required this.albums,
    this.shrinkWrap = true,
    this.physics = const NeverScrollableScrollPhysics(),
    this.padding = EdgeInsets.zero,
    this.isHome = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final server = ref.watch(activeServerProvider).value;
    final api = ref.watch(subsonicApiProvider);

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

        return Padding(
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
          itemCount: albums.length,
          itemBuilder: (context, index) {
            final album = albums[index];
            final title = album['title'] ?? album['name'] ?? '未知專輯';
            final artist = album['artist'] ?? album['year']?.toString() ?? '未知藝術家';
            final artistId = album['artistId'];
            final albumCoverId = album['coverArt'] ?? album['id'];
            final fallbackUrl = api != null && albumCoverId != null 
                ? api.getCoverArtUrl(albumCoverId, size: 250) 
                : null;
            
            return AlbumCard(
              title: title,
              artist: artist,
              coverArtId: albumCoverId,
              fallbackCoverUrl: fallbackUrl,
              serverId: server?.id ?? 0,
              padding: 0,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    settings: RouteSettings(name: title),
                    builder: (context) => AlbumDetailScreen(albumId: album['id']),
                  ),
                );
              },
              onArtistTap: artistId != null 
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          settings: RouteSettings(name: artist),
                          builder: (context) => ArtistDetailScreen(
                            artistId: artistId,
                            artistName: artist,
                          ),
                        ),
                      );
                    }
                  : null,
            );
          },
        ),
      );
      },
    );
  }
}
