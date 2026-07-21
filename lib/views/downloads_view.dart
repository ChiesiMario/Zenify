import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenify/providers/download_provider.dart';
import 'package:zenify/providers/audio_provider.dart';
import 'package:zenify/providers/app_providers.dart';
import 'package:zenify/components/local_cover_image.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class DownloadsView extends ConsumerWidget {
  const DownloadsView({super.key});

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _formatSize(int bytes) {
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;
    final downloadsAsync = ref.watch(downloadedTracksProvider);
    final api = ref.watch(subsonicApiProvider);

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.background,
        title: const Text('已下載'),
      ),
      body: downloadsAsync.when(
        data: (tracks) {
          if (tracks.isEmpty) {
            return Center(
              child: Text(
                '尚無下載的音樂',
                style: TextStyle(color: colorScheme.mutedForeground),
              ),
            );
          }

          // Check if files actually exist
          final validTracks = tracks.where((t) => File(t.localPath).existsSync()).toList();

          return CustomScrollView(
            slivers: [
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final track = validTracks[index];
                    final duration = _formatDuration(track.duration);
                    final size = _formatSize(track.sizeBytes);

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: colorScheme.muted,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: track.coverArt != null
                            ? LocalCoverImage(
                                id: track.coverArt!,
                                serverId: track.serverId,
                                fallbackUrl: api?.getCoverArtUrl(track.coverArt!),
                              )
                            : Icon(LucideIcons.music, color: colorScheme.mutedForeground),
                      ),
                      title: Text(
                        track.title,
                        style: TextStyle(color: colorScheme.foreground, fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        '${track.artist} • $size',
                        style: TextStyle(color: colorScheme.mutedForeground, fontSize: 12),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(LucideIcons.trash2, color: colorScheme.destructive, size: 20),
                            onPressed: () async {
                              await ref.read(downloadServiceProvider).deleteDownload(track.songId);
                              ref.invalidate(downloadedTracksProvider);
                            },
                            tooltip: '刪除',
                          ),
                          const SizedBox(width: 8),
                          Text(
                            duration,
                            style: TextStyle(color: colorScheme.mutedForeground),
                          ),
                        ],
                      ),
                      onTap: () {
                        final allSongs = validTracks.map((t) => jsonDecode(t.rawData)).toList();
                        ref.read(audioProvider.notifier).playQueue(allSongs, index);
                      },
                    );
                  },
                  childCount: validTracks.length,
                ),
              ),
            ],
          );
        },
        loading: () => Center(child: CircularProgressIndicator(color: colorScheme.foreground)),
        error: (err, stack) => Center(
          child: Text('加載失敗: $err', style: TextStyle(color: colorScheme.destructive)),
        ),
      ),
    );
  }
}
