import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:zenify/providers/app_providers.dart';
import 'package:zenify/screens/playlist_detail_screen.dart';

final playlistsProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.watch(subsonicApiProvider);
  if (api == null) return [];
  return await api.getPlaylists();
});

class PlaylistsView extends ConsumerWidget {
  const PlaylistsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;
    final playlistsAsync = ref.watch(playlistsProvider);

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: playlistsAsync.when(
        data: (playlists) {
          if (playlists.isEmpty) {
            return Center(
              child: Text('目前沒有播放清單', style: TextStyle(color: colorScheme.mutedForeground)),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(playlistsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: playlists.length,
              itemBuilder: (context, index) {
                final playlist = playlists[index];
                final title = playlist['name'] ?? 'Unknown Playlist';
                final songCount = playlist['songCount'] ?? 0;
                final duration = playlist['duration'] ?? 0;
                
                final durationMinutes = duration ~/ 60;
                
                return Card(
                  color: colorScheme.card,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: colorScheme.secondary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(LucideIcons.listMusic, color: colorScheme.secondaryForeground),
                    ),
                    title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('$songCount 首歌曲 • $durationMinutes 分鐘', style: TextStyle(color: colorScheme.mutedForeground)),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PlaylistDetailScreen(
                            playlistId: playlist['id'].toString(),
                            playlistName: title,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
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
