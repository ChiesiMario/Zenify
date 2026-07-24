import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:zenify/components/local_cover_image.dart';
import 'package:zenify/components/albums_grid.dart';
import 'package:zenify/providers/app_providers.dart';
import 'package:zenify/providers/audio_provider.dart';

class ArtistDetailScreen extends ConsumerStatefulWidget {
  final String artistId;
  final String artistName;
  final String? coverUrl;

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
  bool _showAllTopSongs = false;

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
              // 1. Hero Header
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 380.0,
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
                      // Smooth gradient overlay for text readability
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.1),
                              Colors.black.withValues(alpha: 0.8),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.only(left: 24, bottom: 24),
                            child: Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                shadows: [Shadow(color: Colors.black54, blurRadius: 10)],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Content below header
              SliverToBoxAdapter(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),

                          // 2. Play Actions & Bio
                          Row(
                            children: [
                              if (topSongs.isNotEmpty)
                                ShadButton(
                                  onPressed: () {
                                    ref.read(audioProvider.notifier).playQueue(List<dynamic>.from(topSongs), 0);
                                  },
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(LucideIcons.play, size: 16),
                                      SizedBox(width: 8),
                                      Text('播放熱門歌曲', style: TextStyle(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              const SizedBox(width: 12),
                              if (topSongs.isNotEmpty)
                                ShadButton.secondary(
                                  onPressed: () {
                                    final shuffled = List<dynamic>.from(topSongs)..shuffle();
                                    ref.read(audioProvider.notifier).playQueue(shuffled, 0);
                                  },
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(LucideIcons.shuffle, size: 16),
                                      SizedBox(width: 8),
                                      Text('隨機播放'),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          if (bio != null && bio.isNotEmpty) ...[
                            const SizedBox(height: 32),
                            Text('關於', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.foreground, letterSpacing: -0.5)),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isBioExpanded = !_isBioExpanded;
                                });
                              },
                              child: AnimatedCrossFade(
                                duration: const Duration(milliseconds: 300),
                                crossFadeState: _isBioExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                                firstChild: _buildBioText(bio, colorScheme, 4),
                                secondChild: _buildBioText(bio, colorScheme, null),
                              ),
                            ),
                          ],

                          const SizedBox(height: 48),

                          // 3. Top Songs
                          if (topSongs.isNotEmpty) ...[
                            Text('熱門歌曲', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colorScheme.foreground, letterSpacing: -0.5)),
                            const SizedBox(height: 16),
                            Container(
                              decoration: BoxDecoration(
                                color: colorScheme.card,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: colorScheme.border, width: 1.0),
                              ),
                              child: Column(
                                children: [
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    padding: EdgeInsets.zero,
                                    itemCount: _showAllTopSongs ? topSongs.length : (topSongs.length > 5 ? 5 : topSongs.length),
                                    itemBuilder: (context, index) {
                                      final song = topSongs[index];
                                      final title = song['title'] ?? '未知歌曲';
                                      final duration = _formatDuration(song['duration'] as int? ?? 0);
                                      final coverArtId = song['coverArt'] ?? song['albumId'];
                                      final fallbackUrl = api != null && coverArtId != null ? api.getCoverArtUrl(coverArtId, size: 250) : null;
                                      
                                      final isFirst = index == 0;
                                      final isLastIndex = _showAllTopSongs ? topSongs.length - 1 : (topSongs.length > 5 ? 4 : topSongs.length - 1);
                                      final isLast = index == isLastIndex;
                                      final showShowMoreButton = !_showAllTopSongs && topSongs.length > 5;

                                      return Container(
                                        decoration: BoxDecoration(
                                          border: (isLast && !showShowMoreButton) ? null : Border(bottom: BorderSide(color: colorScheme.border.withValues(alpha: 0.5), width: 0.5)),
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          borderRadius: BorderRadius.vertical(
                                            top: isFirst ? const Radius.circular(12) : Radius.zero,
                                            bottom: (isLast && !showShowMoreButton) ? const Radius.circular(12) : Radius.zero,
                                          ),
                                          clipBehavior: Clip.antiAlias,
                                          child: ListTile(
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                            leading: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                SizedBox(
                                                  width: 24,
                                                  child: Text(
                                                    '${index + 1}',
                                                    style: TextStyle(color: colorScheme.mutedForeground, fontSize: 13, fontWeight: FontWeight.w600),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                ClipRRect(
                                                  borderRadius: BorderRadius.circular(6),
                                                  child: SizedBox(
                                                    width: 44,
                                                    height: 44,
                                                    child: LocalCoverImage(
                                                      id: coverArtId ?? '',
                                                      serverId: server?.id ?? 0,
                                                      fallbackUrl: fallbackUrl,
                                                      isThumb: true,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            title: Text(title, style: TextStyle(color: colorScheme.foreground, fontWeight: FontWeight.w600, fontSize: 14)),
                                            subtitle: Text(song['album'] ?? '', style: TextStyle(color: colorScheme.mutedForeground, fontSize: 12)),
                                            trailing: Text(duration, style: TextStyle(color: colorScheme.mutedForeground, fontSize: 13, fontWeight: FontWeight.w500)),
                                            onTap: () {
                                              ref.read(audioProvider.notifier).playQueue(List<dynamic>.from(topSongs), index);
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  if (!_showAllTopSongs && topSongs.length > 5)
                                    Material(
                                      color: Colors.transparent,
                                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                                      clipBehavior: Clip.antiAlias,
                                      child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            _showAllTopSongs = true;
                                          });
                                        },
                                        child: Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          alignment: Alignment.center,
                                          child: Text(
                                            '顯示更多',
                                            style: TextStyle(
                                              color: colorScheme.foreground,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 48),
                          ],

                          // 4. Albums
                          if (albums.isNotEmpty) ...[
                            Text('專輯', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colorScheme.foreground, letterSpacing: -0.5)),
                            const SizedBox(height: 16),
                            AlbumsGrid(
                              albums: albums.toList(),
                              showYearInsteadOfArtist: true,
                            ),
                          ],
                          const SizedBox(height: 128),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => Center(child: CircularProgressIndicator(color: colorScheme.foreground)),
        error: (err, stack) => Center(
          child: Text('載入失敗: $err', style: TextStyle(color: colorScheme.destructive)),
        ),
      ),
    );
  }

  Widget _buildBioText(String bio, ShadColorScheme colorScheme, int? maxLines) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          bio,
          maxLines: maxLines,
          overflow: maxLines != null ? TextOverflow.ellipsis : null,
          style: TextStyle(
            color: colorScheme.mutedForeground,
            height: 1.6,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          maxLines != null ? '閱讀更多' : '收起',
          style: TextStyle(
            color: colorScheme.foreground,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
