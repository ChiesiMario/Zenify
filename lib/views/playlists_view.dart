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
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 24),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Hero Banner
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: colorScheme.card,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: colorScheme.border, width: 1.0),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '播放清單',
                                  style: TextStyle(
                                    color: colorScheme.foreground,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '共 ${playlists.length} 個歌單',
                                  style: TextStyle(color: colorScheme.mutedForeground, fontSize: 13),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Playlist Group Container
                          Container(
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: colorScheme.card,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: colorScheme.border, width: 1.0),
                            ),
                            child: Column(
                              children: playlists.asMap().entries.map((entry) {
                                final index = entry.key;
                                final playlist = entry.value;
                                final title = playlist['name'] ?? 'Unknown Playlist';
                                final songCount = playlist['songCount'] ?? 0;
                                final duration = playlist['duration'] ?? 0;
                                final durationMinutes = duration ~/ 60;
                                final isLast = index == playlists.length - 1;

                                return Container(
                                  decoration: BoxDecoration(
                                    border: isLast
                                        ? null
                                        : Border(
                                            bottom: BorderSide(
                                              color: colorScheme.border.withValues(alpha: 0.5),
                                              width: 0.5,
                                            ),
                                          ),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.vertical(
                                      top: index == 0 ? const Radius.circular(12) : Radius.zero,
                                      bottom: isLast ? const Radius.circular(12) : Radius.zero,
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: ListTile(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(
                                          top: index == 0 ? const Radius.circular(12) : Radius.zero,
                                          bottom: isLast ? const Radius.circular(12) : Radius.zero,
                                        ),
                                      ),
                                      leading: Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: colorScheme.muted,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(LucideIcons.listMusic, size: 20, color: colorScheme.foreground),
                                      ),
                                      title: Text(
                                        title,
                                        style: TextStyle(
                                          color: colorScheme.foreground,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '$songCount 首歌曲 • $durationMinutes 分鐘',
                                        style: TextStyle(color: colorScheme.mutedForeground, fontSize: 12),
                                      ),
                                      trailing: Icon(
                                        LucideIcons.arrowUpRight,
                                        size: 16,
                                        color: colorScheme.mutedForeground,
                                      ),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            settings: RouteSettings(name: title),
                                            builder: (context) => PlaylistDetailScreen(
                                              playlistId: playlist['id'].toString(),
                                              playlistName: title,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
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
