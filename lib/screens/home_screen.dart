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
import 'package:zenify/services/sync_service.dart';
import 'package:zenify/providers/app_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  final _popoverController = ShadPopoverController();

  final List<Widget> _views = [
    const AlbumView(),
    const ArtistsView(),
    const SongsView(),
    const FavoritesView(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(syncProvider.notifier).startSync();
    });
  }

  @override
  void dispose() {
    _popoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;
    final syncState = ref.watch(syncProvider);

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Zenify', style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.foreground)),
        actions: [
          ShadPopover(
            controller: _popoverController,
            popover: (context) => const SyncPopoverContent(),
            child: IconButton(
              icon: Icon(LucideIcons.refreshCw, color: syncState.isSyncing ? colorScheme.primary : colorScheme.mutedForeground),
              onPressed: () {
                _popoverController.toggle();
              },
            ),
          ),
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

class SyncPopoverContent extends ConsumerWidget {
  const SyncPopoverContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;
    final syncState = ref.watch(syncProvider);
    final statsAsync = ref.watch(serverStatsProvider);

    return Container(
      width: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.popover,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('本地資料統計', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.popoverForeground)),
          const SizedBox(height: 16),
          
          statsAsync.when(
            data: (stats) {
              return Column(
                children: [
                  _buildStatRow('專輯數量', '${stats['albums']}', colorScheme),
                  const SizedBox(height: 8),
                  _buildStatRow('藝術家數量', '${stats['artists']}', colorScheme),
                  const SizedBox(height: 8),
                  _buildStatRow('已下載封面', '${stats['covers']}', colorScheme),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Text('讀取失敗', style: TextStyle(color: colorScheme.destructive)),
          ),

          const SizedBox(height: 16),
          Divider(color: colorScheme.border),
          const SizedBox(height: 16),

          if (syncState.isSyncing) ...[
            Text('同步中...', style: TextStyle(color: colorScheme.popoverForeground, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: syncState.progress, backgroundColor: colorScheme.muted, color: colorScheme.primary),
            const SizedBox(height: 4),
            Text(syncState.message, style: TextStyle(fontSize: 12, color: colorScheme.mutedForeground)),
            const SizedBox(height: 16),
          ],

          SizedBox(
            width: double.infinity,
            child: ShadButton(
              onPressed: syncState.isSyncing 
                ? null 
                : () {
                    ref.read(syncProvider.notifier).startSync();
                  },
              child: const Text('立即同步'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, ShadColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: colorScheme.mutedForeground)),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.popoverForeground)),
      ],
    );
  }
}
