import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:zenify/components/local_cover_image.dart';
import 'package:zenify/components/album_card.dart';
import 'package:zenify/providers/app_providers.dart';
import 'package:zenify/providers/audio_provider.dart';
import 'package:zenify/screens/album_detail_screen.dart';

class ArtistDetailScreen extends ConsumerStatefulWidget {
  final String artistId;
  final String artistName;
  final String? coverUrl; // Optional fallback

  const ArtistDetailScreen({
    super.key,
    required this.artistId,
    required this.artistName,
    this.coverUrl,
  });

  @override
  ConsumerState<ArtistDetailScreen> createState() => _ArtistDetailScreenState();
}

class _ArtistDetailScreenState extends ConsumerState<ArtistDetailScreen> {
  bool _isBioExpanded = false;

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;
    final artistDetailAsync = ref.watch(artistDetailProvider(widget.artistId));
    final server = ref.watch(activeServerProvider).value;
    final api = ref.watch(subsonicApiProvider);

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: artistDetailAsync.when(
        data: (artistData) {
          if (artistData == null) {
            return Center(
              child: Text('無法載入藝術家資料', style: TextStyle(color: colorScheme.destructive)),
            );
          }

          final String name = artistData['name'] ?? widget.artistName;
          final String? bio = artistData['biography'];
          final List<dynamic> topSongs = artistData['topSongs'] ?? [];
          final List<dynamic> albums = artistData['album'] ?? [];
          
          return CustomScrollView(
            slivers: [
              // Cover Art
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 300,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      LocalCoverImage(
                        id: widget.artistId,
                        serverId: server?.id ?? 0,
                        fallbackUrl: widget.coverUrl,
                        fit: BoxFit.cover,
                        isThumb: false,
                      ),
                      // Gradient to make text readable
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 24,
                        bottom: 24,
                        child: Text(
                          name,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            shadows: [Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 8)],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Bio
                      if (bio != null && bio.isNotEmpty) ...[
                        Text('簡介', style: theme.textTheme.h4),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isBioExpanded = !_isBioExpanded;
                            });
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bio,
                                maxLines: _isBioExpanded ? null : 3,
                                overflow: _isBioExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                                style: TextStyle(color: colorScheme.mutedForeground, height: 1.5),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isBioExpanded ? '顯示較少' : '閱讀更多',
                                style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],

                      // Top Songs
                      if (topSongs.isNotEmpty) ...[
                        Text('熱門歌曲', style: theme.textTheme.h4),
                        const SizedBox(height: 16),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: topSongs.length,
                          itemBuilder: (context, index) {
                            final song = topSongs[index];
                            final title = song['title'] ?? 'Unknown';
                            final duration = _formatDuration(song['duration'] as int? ?? 0);
                            final coverArtId = song['coverArt'] ?? song['albumId'];
                            final fallbackUrl = api != null && coverArtId != null ? api.getCoverArtUrl(coverArtId, size: 250) : null;
                            
                            return ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: LocalCoverImage(
                                    id: coverArtId ?? '',
                                    serverId: server?.id ?? 0,
                                    fallbackUrl: fallbackUrl,
                                    isThumb: true,
                                  ),
                                ),
                              ),
                              title: Text(title, style: TextStyle(color: colorScheme.foreground, fontWeight: FontWeight.w500)),
                              subtitle: Text(song['album'] ?? '', style: TextStyle(color: colorScheme.mutedForeground)),
                              trailing: Text(duration, style: TextStyle(color: colorScheme.mutedForeground)),
                              onTap: () {
                                ref.read(audioProvider.notifier).playQueue(
                                  List<dynamic>.from(topSongs), 
                                  index
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 32),
                      ],

                      // Albums
                      if (albums.isNotEmpty) ...[
                        Text('歷年專輯', style: theme.textTheme.h4),
                        const SizedBox(height: 16),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            const double cardWidth = 140.0;
                            const double cardPadding = 8.0;
                            const double cardTotalWidth = cardWidth + (cardPadding * 2);
                            const double spacing = 16.0;
                            
                            int crossAxisCount = (constraints.maxWidth) ~/ (cardTotalWidth + spacing);
                            if (crossAxisCount < 2) crossAxisCount = 2;
                            
                            final double totalHorizontalSpacing = spacing * (crossAxisCount - 1);
                            final double cellWidth = (constraints.maxWidth - totalHorizontalSpacing) / crossAxisCount;
                            
                            const double fixedCellHeight = 194.0;
                            final double childAspectRatio = cellWidth / fixedCellHeight;

                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: spacing,
                                mainAxisSpacing: 12.0,
                                childAspectRatio: childAspectRatio,
                              ),
                              itemCount: albums.length,
                              itemBuilder: (context, index) {
                                final album = albums[index];
                                final title = album['title'] ?? album['name'] ?? 'Unknown';
                                final year = album['year'];
                                final albumCoverId = album['coverArt'] ?? album['id'];
                                final fallbackUrl = api != null && albumCoverId != null ? api.getCoverArtUrl(albumCoverId, size: 250) : null;
                                
                                return AlbumCard(
                                  title: title,
                                  artist: year != null ? year.toString() : name,
                                  coverArtId: albumCoverId,
                                  fallbackCoverUrl: fallbackUrl,
                                  serverId: server?.id ?? 0,
                                  width: 140,
                                  padding: 8,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AlbumDetailScreen(
                                          albumId: album['id'],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 32),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('載入失敗: $err', style: TextStyle(color: colorScheme.destructive)),
        ),
      ),
    );
  }
}
