import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:zenify/providers/download_provider.dart';
import 'package:zenify/providers/theme_provider.dart';
import 'package:zenify/screens/server_management_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  String _formatSize(int bytes) {
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;
    final themeMode = ref.watch(themeModeProvider);
    final downloadsAsync = ref.watch(downloadedTracksProvider);

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.background,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colorScheme.foreground),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '設定',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colorScheme.foreground,
            fontSize: 20,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          _buildSectionHeader('外觀', colorScheme),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              leading: Icon(
                themeMode == ThemeMode.dark
                    ? LucideIcons.moon
                    : (themeMode == ThemeMode.light ? LucideIcons.sun : LucideIcons.sunMoon),
                color: colorScheme.foreground,
              ),
              title: Text('主題外觀', style: TextStyle(color: colorScheme.foreground)),
              trailing: SizedBox(
                width: 150,
                child: ShadSelect<ThemeMode>(
                  placeholder: const Text('選擇主題'),
                  initialValue: themeMode,
                  onChanged: (mode) {
                    if (mode != null) {
                      ref.read(themeModeProvider.notifier).setThemeMode(mode);
                    }
                  },
                  options: [
                    ShadOption(value: ThemeMode.system, child: Text('自動 (系統)')),
                    ShadOption(value: ThemeMode.light, child: Text('淺色模式')),
                    ShadOption(value: ThemeMode.dark, child: Text('深色模式')),
                  ],
                  selectedOptionBuilder: (context, value) {
                    switch (value) {
                      case ThemeMode.light:
                        return const Text('淺色模式');
                      case ThemeMode.dark:
                        return const Text('深色模式');
                      case ThemeMode.system:
                        return const Text('自動 (系統)');
                    }
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          _buildSectionHeader('儲存與快取', colorScheme),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: downloadsAsync.when(
              data: (tracks) {
                final cacheTracks = tracks.where((t) => !t.isManualDownload && File(t.localPath).existsSync()).toList();
                final totalSizeBytes = cacheTracks.fold<int>(0, (sum, t) => sum + t.sizeBytes);
                final formattedSize = _formatSize(totalSizeBytes);

                return ListTile(
                  leading: Icon(LucideIcons.hardDrive, color: colorScheme.foreground),
                  title: Text('播放快取管理', style: TextStyle(color: colorScheme.foreground)),
                  subtitle: Text(
                    '已使用快取: $formattedSize (${cacheTracks.length} 首歌曲)',
                    style: TextStyle(color: colorScheme.mutedForeground, fontSize: 12),
                  ),
                  trailing: ShadButton.outline(
                    size: ShadButtonSize.sm,
                    enabled: cacheTracks.isNotEmpty,
                    onPressed: () async {
                      await ref.read(downloadServiceProvider).clearAllCaches();
                      ref.invalidate(downloadedTracksProvider);
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.trash2, size: 14),
                        SizedBox(width: 6),
                        Text('清除快取'),
                      ],
                    ),
                  ),
                );
              },
              loading: () => ListTile(
                leading: Icon(LucideIcons.hardDrive, color: colorScheme.foreground),
                title: Text('播放快取管理', style: TextStyle(color: colorScheme.foreground)),
                subtitle: Text('計算快取容量中...', style: TextStyle(color: colorScheme.mutedForeground, fontSize: 12)),
              ),
              error: (err, _) => ListTile(
                leading: Icon(LucideIcons.hardDrive, color: colorScheme.foreground),
                title: Text('播放快取管理', style: TextStyle(color: colorScheme.foreground)),
                subtitle: Text('讀取快取資訊失敗', style: TextStyle(color: colorScheme.destructive, fontSize: 12)),
              ),
            ),
          ),
          const SizedBox(height: 32),
          _buildSectionHeader('帳號與伺服器', colorScheme),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              leading: Icon(LucideIcons.server, color: colorScheme.foreground),
              title: Text('伺服器管理', style: TextStyle(color: colorScheme.foreground)),
              subtitle: Text('新增、切換或刪除 Subsonic 伺服器', style: TextStyle(color: colorScheme.mutedForeground, fontSize: 12)),
              trailing: Icon(LucideIcons.chevronRight, color: colorScheme.mutedForeground, size: 20),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ServerManagementScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, ShadColorScheme colorScheme) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: colorScheme.mutedForeground,
      ),
    );
  }
}
