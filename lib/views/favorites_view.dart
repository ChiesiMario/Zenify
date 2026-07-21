import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:zenify/screens/favorite_songs_screen.dart';
import 'package:zenify/screens/favorite_albums_screen.dart';
import 'package:zenify/views/playlists_view.dart';
import 'package:zenify/views/downloads_view.dart';

class FavoritesView extends StatelessWidget {
  const FavoritesView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;

    final List<Map<String, dynamic>> hubItems = [
      {
        'title': '歌曲',
        'icon': LucideIcons.music,
        'color': Colors.redAccent,
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FavoriteSongsScreen()),
            ),
      },
      {
        'title': '專輯',
        'icon': LucideIcons.disc,
        'color': Colors.blueAccent,
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FavoriteAlbumsScreen()),
            ),
      },
      {
        'title': '播放清單',
        'icon': LucideIcons.listMusic,
        'color': Colors.green,
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PlaylistsView()),
            ),
      },
      {
        'title': '已下載',
        'icon': LucideIcons.downloadCloud,
        'color': Colors.orangeAccent,
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DownloadsView()),
            ),
      },
    ];

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        itemCount: hubItems.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = hubItems[index];
          return Card(
            color: colorScheme.card,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colorScheme.border, width: 1),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (item['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  item['icon'] as IconData,
                  color: item['color'] as Color,
                  size: 24,
                ),
              ),
              title: Text(
                item['title'] as String,
                style: TextStyle(
                  color: colorScheme.foreground,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: Icon(LucideIcons.chevronRight, color: colorScheme.mutedForeground),
              onTap: item['onTap'] as VoidCallback,
            ),
          );
        },
      ),
    );
  }
}
