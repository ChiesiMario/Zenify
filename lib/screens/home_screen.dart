import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:zenify/screens/server_management_screen.dart';
import 'package:zenify/views/album_view.dart';
import 'package:zenify/views/artists_view.dart';
import 'package:zenify/views/songs_view.dart';
import 'package:zenify/views/favorites_view.dart';
import 'package:zenify/components/mini_player.dart';
import 'package:zenify/providers/theme_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _views = [
    const AlbumView(),
    const ArtistsView(),
    const SongsView(),
    const FavoritesView(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Zenify', style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.foreground)),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.sunMoon, color: colorScheme.mutedForeground),
            onPressed: () {
              ref.read(themeModeProvider.notifier).toggleTheme();
            },
          ),
          IconButton(
            icon: Icon(LucideIcons.server, color: colorScheme.mutedForeground),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ServerManagementScreen()),
              );
            },
          ),
        ],
      ),
      body: _views[_currentIndex],
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: colorScheme.border, width: 1)),
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              backgroundColor: colorScheme.background,
              selectedItemColor: colorScheme.foreground,
              unselectedItemColor: colorScheme.mutedForeground,
              type: BottomNavigationBarType.fixed,
              showSelectedLabels: true,
              showUnselectedLabels: true,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(LucideIcons.disc),
                  label: '專輯',
                ),
                BottomNavigationBarItem(
                  icon: Icon(LucideIcons.users),
                  label: '藝術家',
                ),
                BottomNavigationBarItem(
                  icon: Icon(LucideIcons.music),
                  label: '歌曲',
                ),
                BottomNavigationBarItem(
                  icon: Icon(LucideIcons.heart),
                  label: '喜愛',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
