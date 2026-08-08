import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:zenify/models/downloaded_track.dart';
import 'package:zenify/providers/app_providers.dart';
import 'package:zenify/providers/download_provider.dart';
import 'package:zenify/providers/theme_provider.dart';
import 'package:file_selector/file_selector.dart';
import 'package:zenify/services/path_service.dart';
import 'package:zenify/screens/server_management_screen.dart';
import 'package:zenify/providers/audio_provider.dart';
import 'package:zenify/l10n/app_localizations.dart';
import 'package:zenify/components/zenify_button.dart';
import 'package:zenify/components/zenify_slider.dart';
import 'package:zenify/components/zenify_dialog.dart';
import 'package:zenify/components/zenify_select.dart';
import 'package:zenify/utils/responsive.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _currentDownloadRoot = '';
  double? _draggingCacheLimit;

  @override
  void initState() {
    super.initState();
    _loadDownloadRoot();
  }

  Future<void> _loadDownloadRoot() async {
    final path = await PathService.getRootDownloadPath();
    if (mounted) {
      setState(() {
        _currentDownloadRoot = path;
      });
    }
  }

  String _formatSize(int bytes) {
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  String _getThemeName(ThemeMode mode, AppLocalizations l10n) {
    switch (mode) {
      case ThemeMode.light:
        return l10n.themeLight;
      case ThemeMode.dark:
        return l10n.themeDark;
      case ThemeMode.system:
        return l10n.themeSystem;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
          backgroundColor: colorScheme.background,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          elevation: 0,
          titleSpacing: 0,
          leading: Center(
            child: ZenifyButton(
              variant: ZenifyButtonVariant.ghost,
              isCircular: true,
              text: '',
              padding: const EdgeInsets.all(8),
              icon: Icon(LucideIcons.arrowLeft, color: colorScheme.foreground, size: 20),
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  context.go('/albums');
                }
              },
            ),
          ),
          title: Text(
            l10n.settingsTitle,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: colorScheme.foreground,
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 128),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: getResponsiveMaxWidth(context)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Craftsman System Overview Hero Banner
                    _buildHeroBanner(
                      context,
                      colorScheme,
                      l10n.settingsTitle,
                      _getThemeName(themeMode, l10n),
                      formattedCacheSize,
                      server != null ? '${server.username}@${server.url}' : l10n.noServerConfigured,
                    ),
                    const SizedBox(height: 24),

                    // 2. 外觀 SECTION
                    _buildSectionHeader(l10n.themeAppearance, colorScheme),
                    const SizedBox(height: 12),
                    _VercelSettingTile(
                      title: l10n.languageSetting,
                      subtitle: l10n.languageDescription,
                      icon: LucideIcons.languages,
                      trailing: SizedBox(
                        width: 180,
                        child: ZenifySelect<String>(
                          placeholder: Text(l10n.languageSystem),
                          initialValue: ref.watch(localeProvider)?.toString() ?? 'system',
                          onChanged: (val) {
                            if (val == 'system') {
                              ref.read(localeProvider.notifier).setLocale(null);
                            } else if (val == 'en') {
                              ref.read(localeProvider.notifier).setLocale(const Locale('en'));
                            } else if (val == 'zh_TW') {
                              ref.read(localeProvider.notifier).setLocale(const Locale('zh', 'TW'));
                            } else if (val == 'zh_CN') {
                              ref.read(localeProvider.notifier).setLocale(const Locale('zh', 'CN'));
                            }
                          },
                          options: [
                            ShadOption(value: 'system', child: Text(l10n.languageSystem)),
                            ShadOption(value: 'en', child: Text(l10n.languageEnglish)),
                            ShadOption(value: 'zh_TW', child: Text(l10n.languageTraditionalChinese)),
                            ShadOption(value: 'zh_CN', child: Text(l10n.languageSimplifiedChinese)),
                          ],
                          selectedOptionBuilder: (context, value) {
                            if (value == 'en') return Text(l10n.languageEnglish);
                            if (value == 'zh_TW') return Text(l10n.languageTraditionalChinese);
                            if (value == 'zh_CN') return Text(l10n.languageSimplifiedChinese);
                            return Text(l10n.languageSystem);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _VercelSettingTile(
                      title: l10n.themeAppearance,
                      subtitle: l10n.themeDescription,
                      icon: themeMode == ThemeMode.dark
                          ? LucideIcons.moon
                          : (themeMode == ThemeMode.light ? LucideIcons.sun : LucideIcons.sunMoon),
                      trailing: SizedBox(
                        width: 180,
                        child: ZenifySelect<ThemeMode>(
                          placeholder: Text(l10n.selectTheme),
                          initialValue: themeMode,
                          onChanged: (mode) {
                            if (mode != null) {
                              ref.read(themeModeProvider.notifier).setThemeMode(mode);
                            }
                          },
                          options: [
                            ShadOption(value: ThemeMode.system, child: Text(l10n.themeSystem)),
                            ShadOption(value: ThemeMode.light, child: Text(l10n.themeLight)),
                            ShadOption(value: ThemeMode.dark, child: Text(l10n.themeDark)),
                          ],
                          selectedOptionBuilder: (context, value) {
                            return Text(_getThemeName(value, l10n));
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // 2.5 播放 SECTION
                    _buildSectionHeader(l10n.playbackSettings, colorScheme),
                    const SizedBox(height: 12),
                    Consumer(
                      builder: (context, ref, child) {
                        final isEnabled = ref.watch(replayGainEnabledProvider);
                        return _VercelSettingTile(
                          title: l10n.replayGainTitle,
                          subtitle: l10n.replayGainSubtitle,
                          icon: LucideIcons.volume2,
                          trailing: ShadSwitch(
                            value: isEnabled,
                            onChanged: (v) {
                              ref.read(replayGainEnabledProvider.notifier).toggle();
                            },
                          ),
                        );
                      }
                    ),
                    
                    const SizedBox(height: 32),

                    // 3. 儲存與快取 SECTION
                    _buildSectionHeader(l10n.storageAndCache, colorScheme),
                    const SizedBox(height: 12),
                    _VercelSettingTile(
                      title: l10n.playbackCacheManagement,
                      subtitle: l10n.cacheUsed(formattedCacheSize.toString(), cacheTracks.length.toString()),
                      icon: LucideIcons.hardDrive,
                      trailing: ZenifyButton(
                        variant: ZenifyButtonVariant.outline,
                        onPressed: cacheTracks.isEmpty ? null : () async {
                          await ref.read(downloadServiceProvider).clearAllCaches();
                          ref.invalidate(downloadedTracksProvider);
                        },
                        text: l10n.clearCache,
                        icon: Icon(LucideIcons.trash2, size: 13, color: colorScheme.mutedForeground),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _VercelSettingTile(
                      title: l10n.offlineMusicCacheLocation,
                      subtitle: _currentDownloadRoot.isEmpty ? l10n.loading : _currentDownloadRoot,
                      icon: LucideIcons.folderClosed,
                      trailing: ZenifyButton(
                        variant: ZenifyButtonVariant.outline,
                        onPressed: () async {
                          String? result;
                          try {
                            result = await getDirectoryPath(confirmButtonText: l10n.selectThisDirectory);
                          } catch (e) {
                            print('FileSelector error: $e');
                          }
                          if (result != null && context.mounted) {
                            final progressNotifier = ValueNotifier<double>(0);
                            final textNotifier = ValueNotifier<String>(l10n.preparingToMoveFiles);
                            
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) {
                                return AlertDialog(
                                  backgroundColor: theme.colorScheme.card,
                                  title: Text(
                                    l10n.movingFiles, 
                                    style: TextStyle(color: theme.colorScheme.foreground, fontSize: 16, fontWeight: FontWeight.bold)
                                  ),
                                  content: SizedBox(
                                    width: 300,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        ValueListenableBuilder<String>(
                                          valueListenable: textNotifier,
                                          builder: (context, text, child) => Text(
                                            text, 
                                            style: TextStyle(color: theme.colorScheme.mutedForeground, fontSize: 13)
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        ValueListenableBuilder<double>(
                                          valueListenable: progressNotifier,
                                          builder: (context, value, child) => LinearProgressIndicator(
                                            value: value > 0 ? value : null,
                                            backgroundColor: theme.colorScheme.border,
                                            valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );

                            try {
                              // 停止播放以釋放檔案鎖定
                              await ref.read(audioProvider.notifier).stop();

                              final db = ref.read(databaseProvider);
                              await PathService.setRootDownloadPath(
                                result,
                                onProgress: (current, total) {
                                  progressNotifier.value = current / total;
                                  textNotifier.value = l10n.movedFilesProgress(current.toString(), total.toString());
                                },
                              );
                              textNotifier.value = l10n.updatingDatabase;
                              await db.updateAllDownloadPaths(_currentDownloadRoot, result);
                              await _loadDownloadRoot();
                              
                              // 重新載入當前歌曲（使用新路徑）並保持暫停狀態
                              await ref.read(audioProvider.notifier).reloadCurrentTrack();
                            } catch (e, stack) {
                              print('Change directory error: $e\n$stack');
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(l10n.errorOccurred(e.toString()))),
                                );
                              }
                            } finally {
                              if (context.mounted) {
                                Navigator.of(context, rootNavigator: true).pop(); // properly close dialog
                              }
                            }
                          }
                        },
                        text: l10n.changeDirectory,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Consumer(
                      builder: (context, ref, child) {
                        final cacheLimitFromProvider = ref.watch(cacheLimitProvider);
                        final cacheLimit = _draggingCacheLimit ?? cacheLimitFromProvider;
                        final isUnlimited = cacheLimit > 10.0;
                        final displayValue = isUnlimited ? l10n.noLimit : '${cacheLimit.toInt()} GB';

                        return _VercelSettingTile(
                          title: l10n.cacheSizeLimit,
                          subtitle: displayValue,
                          icon: LucideIcons.hardDrive,
                          bottom: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
                            child: Row(
                              children: [
                                Text('1 GB', style: TextStyle(color: theme.colorScheme.mutedForeground, fontSize: 12)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ZenifySlider(
                                    value: cacheLimit.clamp(1.0, 11.0),
                                    min: 1,
                                    max: 11,
                                    divisions: 10,
                                    onChanged: (val) {
                                      setState(() {
                                        _draggingCacheLimit = val;
                                      });
                                    },
                                    onChangeEnd: (val) async {
                                        if (val <= 10.0) {
                                          final newMaxBytes = (val * 1024 * 1024 * 1024).toInt();
                                          if (totalCacheSizeBytes > newMaxBytes) {
                                            final excessBytes = totalCacheSizeBytes - newMaxBytes;
                                            final currentStr = _formatSize(totalCacheSizeBytes);
                                            final excessStr = _formatSize(excessBytes);
                                            
                                            final confirm = await showDialog<bool>(
                                              context: context,
                                              builder: (context) => ZenifyDialog(
                                                icon: LucideIcons.alertTriangle,
                                                iconColor: theme.colorScheme.destructive,
                                                title: l10n.reduceCacheSize,
                                                description: l10n.currentCacheUsedStr(currentStr.toString()) + l10n.cacheLimitWarning(val.toInt().toString(), excessStr.toString()),
                                                actions: [
                                                  ZenifyButton(
                                                    variant: ZenifyButtonVariant.outline,
                                                    onPressed: () => Navigator.pop(context, false),
                                                    text: l10n.cancel,
                                                  ),
                                                  ZenifyButton(
                                                    variant: ZenifyButtonVariant.destructive,
                                                    onPressed: () => Navigator.pop(context, true),
                                                    text: l10n.confirmClear,
                                                  ),
                                                ],
                                              ),
                                            );

                                            if (confirm == true) {
                                              ref.read(cacheLimitProvider.notifier).setLimit(val);
                                              final db = ref.read(databaseProvider);
                                              await db.enforceCacheLimit(val);
                                              ref.invalidate(downloadedTracksProvider);
                                            }
                                            
                                            setState(() {
                                              _draggingCacheLimit = null;
                                            });
                                            return;
                                          }
                                        }

                                        ref.read(cacheLimitProvider.notifier).setLimit(val);
                                        setState(() {
                                          _draggingCacheLimit = null;
                                        });
                                      },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(l10n.noLimit, style: TextStyle(color: theme.colorScheme.mutedForeground, fontSize: 12)),
                              ],
                            ),
                          ),
                        );
                      }
                    ),


                    const SizedBox(height: 32),

                    // 4. 帳號與伺服器 SECTION
                    _buildSectionHeader(l10n.accountAndServer, colorScheme),
                    const SizedBox(height: 12),
                    _VercelSettingTile(
                      title: l10n.serverManagement,
                      subtitle: server != null ? l10n.connectedToServer(server.url.toString(), server.username.toString()) : l10n.noSubsonicServerConfigured,
                      icon: LucideIcons.server,
                      onTap: () {
                        context.push('/servers');
                      },
                      showArrow: true,
                    ),

                    const SizedBox(height: 32),

                    if (kDebugMode) ...[
                      // Developer SECTION
                      _buildSectionHeader('Developer Settings', colorScheme),
                      const SizedBox(height: 12),
                      _VercelSettingTile(
                        title: 'Dispose AudioPlayer',
                        subtitle: 'Forces audio player disposal. Useful for hot reload.',
                        icon: LucideIcons.bug,
                        trailing: ZenifyButton(
                          variant: ZenifyButtonVariant.outline,
                          onPressed: () {
                            ref.read(audioProvider.notifier).disposePlayer();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('AudioPlayer disposed successfully')),
                            );
                          },
                          text: 'Dispose',
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],

                    // 5. 關於與版本 SECTION
                    _buildSectionHeader(l10n.aboutZenify, colorScheme),
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
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset(
                              'assets/icon/app_icon.png',
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
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
                                      'Zenify',
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
                                                  l10n.appSlogan,
                                  style: TextStyle(
                                    color: colorScheme.mutedForeground,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          ZenifyButton(
                            variant: ZenifyButtonVariant.outline,
                            onPressed: () async {
                              final url = Uri.parse('https://github.com/ChiesiMario/Zenify');
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url);
                              }
                            },
                            text: 'GitHub',
                            icon: Icon(LucideIcons.code, size: 16, color: colorScheme.foreground),
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
    String title,
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
            title,
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
              const SizedBox(width: 6),
              Text('•', style: TextStyle(color: colorScheme.mutedForeground, fontSize: 12)),
              const SizedBox(width: 6),
              Text(
                cacheSize,
                style: TextStyle(color: colorScheme.mutedForeground, fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 6),
              Text('•', style: TextStyle(color: colorScheme.mutedForeground, fontSize: 12)),
              const SizedBox(width: 6),
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
  final Widget? bottom;
  final VoidCallback? onTap;
  final bool showArrow;

  const _VercelSettingTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.trailing,
    this.bottom,
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 450;
        
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
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
                            if (widget.subtitle.isNotEmpty) ...[
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
                          ],
                        ),
                      ),
                      if (!isSmallScreen && widget.trailing != null) ...[
                        const SizedBox(width: 16),
                        widget.trailing!,
                      ],
                      if (!isSmallScreen && widget.showArrow) ...[
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
                  if (isSmallScreen && (widget.trailing != null || widget.showArrow)) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
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
                  ],
                  if (widget.bottom != null) ...[
                    const SizedBox(height: 16),
                    widget.bottom!,
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
