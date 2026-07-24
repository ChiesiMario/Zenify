import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenify/components/artist_card.dart';
import 'package:zenify/providers/app_providers.dart';
import 'package:zenify/screens/artist_detail_screen.dart';

class ArtistsGrid extends ConsumerWidget {
  final List<dynamic> artists;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry padding;

  const ArtistsGrid({
    super.key,
    required this.artists,
    this.shrinkWrap = true,
    this.physics = const NeverScrollableScrollPhysics(),
    this.padding = EdgeInsets.zero,
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
        
        if (availableWidth < 490) {
          // 手機螢幕自動填滿
          crossAxisCount = 4;
          cellWidth = (availableWidth - spacing * 3) / crossAxisCount; 
        } else if (availableWidth < 620) {
          // 提早鎖定寬度，避免封面無限制放大
          crossAxisCount = 4;
          cellWidth = 110.0; 
        } else if (availableWidth < 800) {
          crossAxisCount = 5;
          cellWidth = 110.0;
        } else {
          // 800px 以上：寬度上限嚴格鎖定為 120px
          // 利用整數除法，每增加 200px 寬度，系統自動無縫增加 1 列
          crossAxisCount = 6 + ((availableWidth - 800) ~/ 200);
          cellWidth = 120.0;
        }

        final double totalHorizontalSpacing = spacing * (crossAxisCount - 1);
        final double gridWidth = (cellWidth * crossAxisCount) + totalHorizontalSpacing;
        
        // cellHeight = 正方形圖片(cellWidth) + 文字預留高度(~30px)
        final double cellHeight = cellWidth + 30.0; 
        final double childAspectRatio = cellWidth / cellHeight;

        final double sidePadding = (constraints.maxWidth - gridWidth) / 2;
        final EdgeInsets resolvedBasePadding = padding.resolve(TextDirection.ltr);
        
        final EdgeInsets finalPadding = availableWidth >= 490
            ? EdgeInsets.only(
                left: sidePadding,
                right: sidePadding - 2.0 > 0 ? sidePadding - 2.0 : 0.0,
                top: resolvedBasePadding.top,
                bottom: resolvedBasePadding.bottom,
              )
            : resolvedBasePadding;

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
          itemCount: artists.length,
          itemBuilder: (context, index) {
            final artist = artists[index];
            final name = artist['name'] ?? '未知藝術家';
            final artistId = artist['id'];
            final coverArtId = artist['coverArt'] ?? artistId;
            final fallbackUrl = api != null && coverArtId != null 
                ? api.getCoverArtUrl(coverArtId, size: 250) 
                : null;
            
            return ArtistCard(
              name: name,
              artistId: artistId,
              coverArtId: coverArtId,
              fallbackCoverUrl: fallbackUrl,
              serverId: server?.id ?? 0,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    settings: RouteSettings(name: name),
                    builder: (context) => ArtistDetailScreen(
                      artistId: artistId,
                      artistName: name,
                      coverUrl: fallbackUrl,
                    ),
                  ),
                );
              },
            );
          },
        ),
      );
      },
    );
  }
}
