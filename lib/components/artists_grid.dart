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
        const double maxExtent = 120.0;
        const double spacing = 0.0;
        
        final double availableWidth = constraints.maxWidth - padding.horizontal;
        int crossAxisCount = (availableWidth / maxExtent).ceil();
        if (crossAxisCount < 2) crossAxisCount = 2;
        
        final double totalHorizontalSpacing = spacing * (crossAxisCount - 1);
        final double cellWidth = (availableWidth - totalHorizontalSpacing) / crossAxisCount;
        
        // cellHeight = square image (cellWidth) + text height (~40px)
        final double cellHeight = cellWidth + 40.0; 
        final double childAspectRatio = cellWidth / cellHeight;

        return GridView.builder(
          shrinkWrap: shrinkWrap,
          physics: physics,
          padding: padding,
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
        );
      },
    );
  }
}
