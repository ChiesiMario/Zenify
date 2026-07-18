import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:zenify/screens/server_management_screen.dart';
import 'package:zenify/views/album_view.dart';
import 'package:zenify/components/mini_player.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _views = [
    const AlbumView(),
    const Center(child: Text('Artists', style: TextStyle(color: Colors.white))),
    const Center(child: Text('Songs', style: TextStyle(color: Colors.white))),
    const Center(child: Text('Favorites', style: TextStyle(color: Colors.white))),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Zenify', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.server, color: Colors.white70),
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
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFF2C2C2C), width: 1)),
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              backgroundColor: const Color(0xFF1E1E1E),
              selectedItemColor: Colors.white,
              unselectedItemColor: Colors.white54,
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
