import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenify/components/album_card.dart';
import 'package:zenify/providers/app_providers.dart';
import 'package:zenify/screens/album_detail_screen.dart';

class AlbumsGrid extends ConsumerWidget {
  final List<dynamic> albums;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry padding;

  const AlbumsGrid({
    super.key,
    required this.albums,
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
        const double maxExtent = 160.0;
        const double spacing = 16.0;
        
        int crossAxisCount = (constraints.maxWidth / maxExtent).ceil();
        if (crossAxisCount < 2) crossAxisCount = 2;
        
        final double totalHorizontalSpacing = spacing * (crossAxisCount - 1);
        final double cellWidth = (constraints.maxWidth - totalHorizontalSpacing) / crossAxisCount;
        
        // cellHeight = square image (cellWidth) + text height (~50px)
        final double cellHeight = cellWidth + 50.0; 
        final double childAspectRatio = cellWidth / cellHeight;

        return GridView.builder(
          shrinkWrap: shrinkWrap,
          physics: physics,
          padding: padding,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: 24,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: albums.length,
          itemBuilder: (context, index) {
            final album = albums[index];
            final title = album['title'] ?? album['name'] ?? '未知專輯';
            final artist = album['artist'] ?? album['year']?.toString() ?? '未知藝術家';
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
              width: cellWidth, // Use the dynamically calculated cellWidth
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
            );
          },
        );
      },
    );
  }
}
