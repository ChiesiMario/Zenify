import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:zenify/models/downloaded_track.dart';
import 'package:zenify/providers/app_providers.dart';
import 'package:zenify/providers/download_provider.dart';
import 'package:zenify/providers/theme_provider.dart';
import 'package:zenify/screens/server_management_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  String _formatSize(int bytes) {
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  String _getThemeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return '淺色模式';
      case ThemeMode.dark:
        return '深色模式';
      case ThemeMode.system:
        return '系統自動';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;
    final themeMode = ref.watch(themeModeProvider);
    final downloadsAsync = ref.watch(downloadedTracksProvider);
    final server = ref.watch(activeServerProvider).value;

    final validDownloads = downloadsAsync.when(
      data: (t) => t.where((x) => File(x.localPath).existsSync()).toList(),
      loading: () => <DownloadedTrack>[],
      error: (_, _) => <DownloadedTrack>[],
    );

    final cacheTracks = validDownloads.where((t) => !t.isManualDownload).toList();
    final totalCacheSizeBytes = cacheTracks.fold<int>(0, (sum, t) {
      int sz = t.sizeBytes;
      if (sz <= 0) {
        try {
          final f = File(t.localPath);
          if (f.existsSync()) sz = f.lengthSync();
        } catch (_) {}
      }
      return sum + sz;
    });

    final formattedCacheSize = _formatSize(totalCacheSizeBytes);

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: ListView(
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
                    // 1. Craftsman System Overview Hero Banner
                    _buildHeroBanner(
                      context,
                      colorScheme,
                      _getThemeName(themeMode),
                      formattedCacheSize,
                      server != null ? '${server.username}@${server.url}' : '未設定伺服器',
                    ),
                    const SizedBox(height: 24),

                    // 2. 外觀 SECTION
                    _buildSectionHeader('外觀與體驗', colorScheme),
                    const SizedBox(height: 12),
                    _VercelSettingTile(
                      title: '主題外觀',
                      subtitle: '切換深色模式、淺色模式或跟隨系統設定',
                      icon: themeMode == ThemeMode.dark
                          ? LucideIcons.moon
                          : (themeMode == ThemeMode.light ? LucideIcons.sun : LucideIcons.sunMoon),
                      trailing: SizedBox(
                        width: 130,
                        child: ShadSelect<ThemeMode>(
                          placeholder: const Text('選擇主題'),
                          initialValue: themeMode,
                          onChanged: (mode) {
                            if (mode != null) {
                              ref.read(themeModeProvider.notifier).setThemeMode(mode);
                            }
                          },
                          options: const [
                            ShadOption(value: ThemeMode.system, child: Text('自動 (系統)')),
                            ShadOption(value: ThemeMode.light, child: Text('淺色模式')),
                            ShadOption(value: ThemeMode.dark, child: Text('深色模式')),
                          ],
                          selectedOptionBuilder: (context, value) {
                            return Text(_getThemeName(value));
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // 3. 儲存與快取 SECTION
                    _buildSectionHeader('儲存與快取', colorScheme),
                    const SizedBox(height: 12),
                    _VercelSettingTile(
                      title: '播放快取管理',
                      subtitle: '已使用快取: $formattedCacheSize (${cacheTracks.length} 首歌曲)',
                      icon: LucideIcons.hardDrive,
                      trailing: ShadButton.outline(
                        size: ShadButtonSize.sm,
                        enabled: cacheTracks.isNotEmpty,
                        onPressed: () async {
                          await ref.read(downloadServiceProvider).clearAllCaches();
                          ref.invalidate(downloadedTracksProvider);
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.trash2, size: 13, color: colorScheme.mutedForeground),
                            const SizedBox(width: 6),
                            Text(
                              '清除快取',
                              style: TextStyle(
                                color: colorScheme.foreground,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // 4. 帳號與伺服器 SECTION
                    _buildSectionHeader('帳號與伺服器', colorScheme),
                    const SizedBox(height: 12),
                    _VercelSettingTile(
                      title: '伺服器管理',
                      subtitle: server != null ? '已連線至 ${server.url} (${server.username})' : '尚未設定 Subsonic 伺服器',
                      icon: LucideIcons.server,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            settings: const RouteSettings(name: '伺服器管理'),
                            builder: (context) => const ServerManagementScreen(),
                          ),
                        );
                      },
                      showArrow: true,
                    ),

                    const SizedBox(height: 32),

                    // 5. 關於與版本 SECTION
                    _buildSectionHeader('關於 ZENIFY', colorScheme),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: colorScheme.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.border,
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: colorScheme.foreground,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                'Z',
                                style: TextStyle(
                                  color: colorScheme.background,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -1,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Zenify Player',
                                      style: TextStyle(
                                        color: colorScheme.foreground,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: colorScheme.muted.withValues(alpha: 0.5),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: colorScheme.border.withValues(alpha: 0.5),
                                          width: 0.5,
                                        ),
                                      ),
                                      child: Text(
                                        'v1.0.0',
                                        style: TextStyle(
                                          color: colorScheme.mutedForeground,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '極簡現代黑白風 Subsonic 音樂播放器',
                                  style: TextStyle(
                                    color: colorScheme.mutedForeground,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBanner(
    BuildContext context,
    ShadColorScheme colorScheme,
    String themeName,
    String cacheSize,
    String serverName,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.border,
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '系統設定與偏好',
            style: TextStyle(
              color: colorScheme.foreground,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                themeName,
                style: TextStyle(color: colorScheme.mutedForeground, fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 8),
              Text('•', style: TextStyle(color: colorScheme.mutedForeground, fontSize: 12)),
              const SizedBox(width: 8),
              Text(
                cacheSize,
                style: TextStyle(color: colorScheme.mutedForeground, fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 8),
              Text('•', style: TextStyle(color: colorScheme.mutedForeground, fontSize: 12)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  serverName,
                  style: TextStyle(color: colorScheme.mutedForeground, fontSize: 13, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, ShadColorScheme colorScheme) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: colorScheme.mutedForeground,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _VercelSettingTile extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showArrow;

  const _VercelSettingTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.trailing,
    this.onTap,
    this.showArrow = false,
  });

  @override
  State<_VercelSettingTile> createState() => _VercelSettingTileState();
}

class _VercelSettingTileState extends State<_VercelSettingTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;

    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: colorScheme.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (widget.onTap != null && _isHovered)
                  ? colorScheme.foreground.withValues(alpha: 0.4)
                  : colorScheme.border,
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              // Monochromatic Icon Container
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: (widget.onTap != null && _isHovered)
                      ? colorScheme.foreground
                      : colorScheme.muted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (widget.onTap != null && _isHovered)
                        ? colorScheme.foreground
                        : colorScheme.border.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Icon(
                  widget.icon,
                  size: 19,
                  color: (widget.onTap != null && _isHovered)
                      ? colorScheme.background
                      : colorScheme.foreground,
                ),
              ),
              const SizedBox(width: 16),
              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        color: colorScheme.foreground,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        color: colorScheme.mutedForeground,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.trailing != null) widget.trailing!,
              if (widget.showArrow) ...[
                const SizedBox(width: 8),
                AnimatedSlide(
                  duration: const Duration(milliseconds: 150),
                  offset: _isHovered ? const Offset(0.1, -0.1) : Offset.zero,
                  child: Icon(
                    LucideIcons.arrowUpRight,
                    size: 18,
                    color: _isHovered
                        ? colorScheme.foreground
                        : colorScheme.mutedForeground.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
