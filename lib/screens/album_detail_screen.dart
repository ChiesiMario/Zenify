import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenify/providers/app_providers.dart';
import 'package:zenify/providers/audio_provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:zenify/components/local_cover_image.dart';

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
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;
    final albumAsync = ref.watch(albumDetailProvider(albumId));
    final api = ref.watch(subsonicApiProvider);
    final server = ref.watch(activeServerProvider).value;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colorScheme.foreground),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: albumAsync.when(
        data: (album) {
          if (album == null) {
            return Center(child: Text('找不到專輯資訊', style: TextStyle(color: colorScheme.mutedForeground)));
          }

          final coverUrl = api != null && album['coverArt'] != null
              ? api.getCoverArtUrl(album['coverArt'])
              : null;
              
          var songs = album['song'];
          if (songs != null && songs is! List) {
            songs = [songs];
          }
          final songList = songs as List<dynamic>? ?? [];

          return CustomScrollView(
            slivers: [
              // Header with blurred background
              SliverToBoxAdapter(
                child: Stack(
                  children: [
                    // Blurred background
                    if (coverUrl != null)
                      Positioned.fill(
                        child: ImageFiltered(
                          imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                          child: ColorFiltered(
                            colorFilter: ColorFilter.mode(
                              colorScheme.background.withOpacity(0.5),
                              BlendMode.darken,
                            ),
                            child: LocalCoverImage(
                              id: album['coverArt'],
                              serverId: server?.id ?? 0,
                              fallbackUrl: coverUrl,
                              fit: BoxFit.cover,
                              isThumb: false,
                            ),
                          ),
                        ),
                      ),
                    
                    // Album Info Content
                    Padding(
                      padding: const EdgeInsets.fromLTRB(32, 100, 32, 32),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Album Cover
                          Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              color: colorScheme.muted,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: coverUrl == null
                                ? Icon(LucideIcons.music, size: 64, color: colorScheme.mutedForeground)
                                : LocalCoverImage(
                                    id: album['coverArt'],
                                    serverId: server?.id ?? 0,
                                    fallbackUrl: coverUrl,
                                    isThumb: false,
                                  ),
                          ),
                          const SizedBox(width: 32),
                          // Text Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  album['artist'] ?? '未知藝術家',
                                  style: TextStyle(
                                    color: colorScheme.foreground,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  album['name'] ?? '未知專輯',
                                  style: TextStyle(
                                    color: colorScheme.foreground,
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    if (album['year'] != null) ...[
                                      Text('${album['year']}', style: TextStyle(color: colorScheme.mutedForeground)),
                                      const SizedBox(width: 8),
                                      Text('•', style: TextStyle(color: colorScheme.mutedForeground)),
                                      const SizedBox(width: 8),
                                    ],
                                    if (album['genre'] != null) ...[
                                      Text('${album['genre']}', style: TextStyle(color: colorScheme.mutedForeground)),
                                      const SizedBox(width: 8),
                                      Text('•', style: TextStyle(color: colorScheme.mutedForeground)),
                                      const SizedBox(width: 8),
                                    ],
                                    Text('${songList.length} 首歌', style: TextStyle(color: colorScheme.mutedForeground)),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                ShadButton(
                                  onPressed: () {
                                    if (songList.isNotEmpty) {
                                      ref.read(audioProvider.notifier).playQueue(songList, 0);
                                    }
                                  },
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(LucideIcons.play, size: 16),
                                      SizedBox(width: 8),
                                      Text('播放'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Tracklist
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final song = songList[index];
                    final duration = song['duration'] != null ? _formatDuration(song['duration']) : '--:--';
                    
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
                      leading: SizedBox(
                        width: 40,
                        child: Center(
                          child: Text(
                            song['track']?.toString() ?? '${index + 1}',
                            style: TextStyle(color: colorScheme.mutedForeground),
                          ),
                        ),
                      ),
                      title: Text(
                        song['title'] ?? '未知歌曲',
                        style: TextStyle(color: colorScheme.foreground),
                      ),
                      subtitle: song['artist'] != album['artist']
                          ? Text(song['artist'] ?? '', style: TextStyle(color: colorScheme.mutedForeground, fontSize: 12))
                          : null,
                      trailing: Text(
                        duration,
                        style: TextStyle(color: colorScheme.mutedForeground),
                      ),
                      onTap: () {
                        ref.read(audioProvider.notifier).playQueue(songList, index);
                      },
                    );
                  },
                  childCount: songList.length,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          );
        },
        loading: () => Center(child: CircularProgressIndicator(color: colorScheme.foreground)),
        error: (err, stack) => Center(child: Text('加載失敗: $err', style: TextStyle(color: colorScheme.destructive))),
      ),
    );
  }
}
