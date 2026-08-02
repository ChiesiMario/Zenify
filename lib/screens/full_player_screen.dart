import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:zenify/providers/audio_provider.dart';
import 'package:zenify/providers/app_providers.dart';
import 'package:zenify/components/local_cover_image.dart';
import 'package:zenify/components/zenify_toast.dart';
import 'package:zenify/components/play_queue_sheet.dart';
import 'package:zenify/screens/album_detail_screen.dart';
import 'package:zenify/screens/artist_detail_screen.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:file_selector/file_selector.dart';
import 'package:zenify/api/subsonic_api.dart';

class FullPlayerScreen extends ConsumerWidget {
  const FullPlayerScreen({super.key});

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(audioProvider);
    final audioNotifier = ref.read(audioProvider.notifier);
    final api = ref.watch(subsonicApiProvider);
    final server = ref.watch(activeServerProvider).value;
    final networkState = ref.watch(networkProvider);
    final currentSong = audioState.currentSong;
    
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;

    if (currentSong == null) {
      return Container(
        color: colorScheme.background,
        child: const Center(child: Text('無播放中的歌曲')),
      );
    }

    final coverUrl = api != null && currentSong['coverArt'] != null
        ? api.getCoverArtUrl(currentSong['coverArt'], size: 800)
        : null;

    final position = audioState.position;
    final duration = audioState.duration;
    double sliderValue = duration.inMilliseconds > 0 
        ? position.inMilliseconds / duration.inMilliseconds 
        : 0.0;
    sliderValue = sliderValue.clamp(0.0, 1.0);

    final screenSize = MediaQuery.of(context).size;
    final isCompact = screenSize.width <= 400 && screenSize.height <= 600;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.pop(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {}, // 攔截卡片本身的點擊，避免關閉
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 350, maxWidth: 400, maxHeight: 600),
              child: Container(
            margin: isCompact ? EdgeInsets.zero : const EdgeInsets.only(top: 10),
            decoration: ShapeDecoration(
              color: colorScheme.card,
              shape: RoundedRectangleBorder(
                borderRadius: isCompact ? BorderRadius.zero : const BorderRadius.vertical(top: Radius.circular(20)),
                side: theme.brightness == Brightness.dark 
                    ? BorderSide(color: colorScheme.border, width: 1) 
                    : BorderSide.none,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
              // 頂部列：左側為縮小淡化收起按鈕，中間為喜歡按鈕，右側為播放佇列按鈕
              Builder(
                builder: (context) {
                  final favoritesAsync = ref.watch(favoritesProvider);
                  final isFavorite = favoritesAsync.value?['songs']?.any(
                    (s) => s['id']?.toString() == currentSong['id']?.toString(),
                  ) ?? (currentSong['starred'] != null);

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _TopUtilityButton(
                          icon: LucideIcons.info,
                          tooltip: '歌曲資訊',
                          onPressed: () => _showSongInfoDialog(context, currentSong, colorScheme, ref),
                        ),
                        _TopUtilityButton(
                          icon: isFavorite ? Icons.favorite : LucideIcons.heart,
                          tooltip: isFavorite ? '取消最愛' : '加入最愛',
                          iconColor: isFavorite ? const Color(0xFFEF4444) : null,
                          isDisabled: networkState.isOffline,
                          onPressed: () async {
                            final songId = currentSong['id']?.toString();
                            if (songId == null || api == null) return;
                            if (isFavorite) {
                              await api.unstar(id: songId);
                            } else {
                              await api.star(id: songId);
                            }
                            ref.invalidate(favoritesProvider);
                          },
                        ),
                        _TopUtilityButton(
                          icon: LucideIcons.listMusic,
                          tooltip: '播放佇列',
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              constraints: const BoxConstraints(maxWidth: 500),
                              builder: (context) => FractionallySizedBox(
                                heightFactor: 0.8,
                                child: const PlayQueueSheet(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                          // 浮空立體專輯封面與歌曲資訊群組
                          Expanded(
                            flex: 5,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 250, maxHeight: 250),
                                    child: AspectRatio(
                                      aspectRatio: 1,
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 300),
                                        curve: Curves.easeOutCubic,
                                        decoration: BoxDecoration(
                                          color: colorScheme.muted,
                                          borderRadius: BorderRadius.circular(8),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.15),
                                              blurRadius: 40,
                                              spreadRadius: 4,
                                              offset: const Offset(0, 20),
                                            ),
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.1),
                                              blurRadius: 10,
                                              spreadRadius: 0,
                                              offset: const Offset(0, 5),
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          clipBehavior: Clip.antiAliasWithSaveLayer,
                                          child: Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              (currentSong['albumId'] == null && currentSong['coverArt'] == null) 
                                                  ? Center(child: Icon(LucideIcons.music, size: 80, color: colorScheme.mutedForeground))
                                                  : LocalCoverImage(
                                                      id: currentSong['albumId']?.toString() ?? currentSong['coverArt'].toString(),
                                                      serverId: server?.id ?? 0,
                                                      fallbackUrl: coverUrl,
                                                      isThumb: false,
                                                      fit: BoxFit.cover,
                                                    ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                      const SizedBox(height: 8),
                          
                          // 歌曲資訊 (置中、極簡字體排版)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                currentSong['title'] ?? '未知歌曲',
                                style: TextStyle(
                                  color: colorScheme.foreground,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                  height: 1.2,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Flexible(
                                    child: _HoverableLink(
                                      text: currentSong['artist'] ?? '未知藝術家',
                                      isDisabled: networkState.isOffline,
                                      style: TextStyle(
                                        color: colorScheme.mutedForeground,
                                        fontSize: 14,
                                        fontWeight: FontWeight.normal,
                                        letterSpacing: -0.2,
                                        height: 1.1,
                                      ),
                                      onTap: () {
                                        Navigator.pop(context);
                                        final artistId = currentSong['artistId'];
                                        if (artistId != null && artistId.toString().isNotEmpty) {
                                          ref.read(navigationRequestProvider.notifier).state = NavigationRequest(
                                            type: 'artist',
                                            id: artistId.toString(),
                                            name: currentSong['artist'] ?? '未知藝術家',
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                  Text(
                                    ' • ',
                                    style: TextStyle(
                                      color: colorScheme.mutedForeground,
                                      fontSize: 14,
                                      fontWeight: FontWeight.normal,
                                      fontFamily: 'NotoSansTC',
                                      height: 1.1,
                                    ),
                                  ),
                                  Flexible(
                                    child: _HoverableLink(
                                      text: currentSong['album'] ?? '未知專輯',
                                      style: TextStyle(
                                        color: colorScheme.mutedForeground,
                                        fontSize: 14,
                                        fontWeight: FontWeight.normal,
                                        letterSpacing: -0.2,
                                        height: 1.1,
                                      ),
                                      onTap: () {
                                        Navigator.pop(context);
                                        final albumId = currentSong['albumId'];
                                        if (albumId != null && albumId.toString().isNotEmpty) {
                                          ref.read(navigationRequestProvider.notifier).state = NavigationRequest(
                                            type: 'album',
                                            id: albumId.toString(),
                                            name: currentSong['album'] ?? '未知專輯',
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 48),

                          // 播放進度條 (極簡細線設計)
                          SliderTheme(
                            data: SliderThemeData(
                              trackHeight: 3.0,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
                              activeTrackColor: colorScheme.foreground,
                              inactiveTrackColor: colorScheme.foreground.withValues(alpha: 0.1),
                              thumbColor: colorScheme.foreground,
                              overlayColor: colorScheme.foreground.withValues(alpha: 0.1),
                            ),
                            child: Slider(
                              value: sliderValue,
                              min: 0.0,
                              max: 1.0,
                              onChanged: (val) {
                                final newPos = Duration(milliseconds: (val * duration.inMilliseconds).round());
                                audioNotifier.seek(newPos);
                              },
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_formatDuration(position), style: TextStyle(color: colorScheme.mutedForeground, fontSize: 13, fontWeight: FontWeight.w500)),
                              Text(_formatDuration(duration), style: TextStyle(color: colorScheme.mutedForeground, fontSize: 13, fontWeight: FontWeight.w500)),
                            ],
                          ),
                          const SizedBox(height: 40),

                          // 播放控制區塊 (全新極簡與層次設計)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _SecondaryPlayerButton(
                                icon: LucideIcons.shuffle,
                                size: 20,
                                isActive: audioState.isShuffled,
                                onPressed: () => audioNotifier.toggleShuffle(),
                              ),
                              _SecondaryPlayerButton(
                                icon: LucideIcons.skipBack,
                                size: 32,
                                isActive: true,
                                onPressed: () => audioNotifier.skipToPrevious(),
                              ),
                              _PrimaryPlayButton(
                                isPlaying: audioState.isPlaying,
                                onPressed: () => audioNotifier.togglePlayPause(),
                              ),
                              _SecondaryPlayerButton(
                                icon: LucideIcons.skipForward,
                                size: 32,
                                isActive: true,
                                onPressed: () => audioNotifier.skipToNext(),
                              ),
                              _SecondaryPlayerButton(
                                icon: audioState.repeatMode == AudioRepeatMode.one 
                                    ? LucideIcons.repeat1 
                                    : LucideIcons.repeat,
                                size: 20,
                                isActive: audioState.repeatMode != AudioRepeatMode.off,
                                onPressed: () => audioNotifier.toggleRepeat(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 34),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ),
),
      ),
    );
  }
}

class _HoverableLink extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  final TextStyle style;
  final bool isDisabled;

  const _HoverableLink({
    Key? key,
    required this.text,
    required this.onTap,
    required this.style,
    this.isDisabled = false,
  }) : super(key: key);

  @override
  State<_HoverableLink> createState() => _HoverableLinkState();
}

class _HoverableLinkState extends State<_HoverableLink> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.isDisabled ? () {
            ZenifyToast.showError(context, '服務器已離線');
          } : widget.onTap,
          child: Text(
            widget.text,
            style: widget.style.copyWith(
              decoration: (_isHovered && !widget.isDisabled) ? TextDecoration.underline : TextDecoration.none,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
    );
  }
}

class _PrimaryPlayButton extends StatefulWidget {
  final bool isPlaying;
  final VoidCallback onPressed;

  const _PrimaryPlayButton({
    Key? key,
    required this.isPlaying,
    required this.onPressed,
  }) : super(key: key);

  @override
  State<_PrimaryPlayButton> createState() => _PrimaryPlayButtonState();
}

class _PrimaryPlayButtonState extends State<_PrimaryPlayButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onPressed();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.90 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            opacity: _isPressed ? 0.5 : (_isHovered ? 0.7 : 1.0),
            duration: const Duration(milliseconds: 150),
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.foreground, // 實心反白高對比
              ),
              child: Center(
                child: Icon(
                  widget.isPlaying ? LucideIcons.pause : LucideIcons.play,
                  size: 28, // 刻意縮小的圖示，利用留白增加精緻感
                  color: colorScheme.background,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryPlayerButton extends StatefulWidget {
  final IconData icon;
  final double size;
  final VoidCallback onPressed;
  final bool isActive;

  const _SecondaryPlayerButton({
    Key? key,
    required this.icon,
    required this.size,
    required this.onPressed,
    this.isActive = false,
  }) : super(key: key);

  @override
  State<_SecondaryPlayerButton> createState() => _SecondaryPlayerButtonState();
}

class _SecondaryPlayerButtonState extends State<_SecondaryPlayerButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;
    
    // 統一基礎色，完全由 AnimatedOpacity 控制層次
    final color = colorScheme.foreground;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onPressed();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.85 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            opacity: _isPressed 
                ? (widget.isActive ? 0.5 : 0.2) 
                : (_isHovered 
                    ? (widget.isActive ? 0.7 : 0.5) 
                    : (widget.isActive ? 1.0 : 0.3)),
            duration: const Duration(milliseconds: 150),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(
                widget.icon,
                size: widget.size,
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopUtilityButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final Color? iconColor;

  final bool isDisabled;

  const _TopUtilityButton({
    Key? key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.iconColor,
    this.isDisabled = false,
  }) : super(key: key);

  @override
  State<_TopUtilityButton> createState() => _TopUtilityButtonState();
}

class _TopUtilityButtonState extends State<_TopUtilityButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = ShadTheme.of(context).colorScheme;
    final bool isDisabled = widget.isDisabled || widget.onPressed == null;

    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) { if (!isDisabled) setState(() => _isHovered = true); },
        onExit: (_) { if (!isDisabled) setState(() => _isHovered = false); },
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) { if (!isDisabled) setState(() => _isPressed = true); },
          onTapUp: (_) {
            if (isDisabled) {
              ZenifyToast.showError(context, '服務器已離線');
            } else if (widget.onPressed != null) {
              setState(() => _isPressed = false);
              widget.onPressed!();
            }
          },
          onTapCancel: () { if (!isDisabled) setState(() => _isPressed = false); },
          child: AnimatedScale(
            scale: _isPressed ? 0.85 : (_isHovered ? 1.15 : 1.0),
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            child: AnimatedOpacity(
              opacity: isDisabled ? 0.3 : (_isPressed ? 0.5 : (_isHovered ? 1.0 : (widget.iconColor != null ? 0.85 : 0.7))),
              duration: const Duration(milliseconds: 150),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  widget.icon,
                  size: 20, // 稍微加大一點點，增加精緻感與點擊識別度
                  color: widget.iconColor ?? colorScheme.mutedForeground,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void _showSongInfoDialog(BuildContext context, Map<String, dynamic> song, ShadColorScheme colorScheme, WidgetRef ref) {
  final title = song['title'] ?? '未知歌曲';
  final artist = song['artist'] ?? '未知藝術家';
  final album = song['album'] ?? '未知專輯';
  final year = song['year']?.toString() ?? '未知';
  final bitRate = song['bitRate'] != null ? '${song['bitRate']} kbps' : null;
  final suffix = song['suffix']?.toString().toUpperCase() ?? song['contentType']?.toString().split('/').last.toUpperCase();
  final durationSec = song['duration'] as int?;
  final durationStr = durationSec != null ? '${durationSec ~/ 60}:${(durationSec % 60).toString().padLeft(2, '0')}' : null;
  final fileSizeMb = song['size'] != null ? '${((song['size'] as int) / (1024 * 1024)).toStringAsFixed(2)} MB' : null;

  showDialog(
    context: context,
    builder: (context) {
      bool isDownloading = false;
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              width: 340,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.background,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '歌曲詳細資訊',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.foreground,
                        ),
                      ),
                      IconButton(
                        icon: Icon(LucideIcons.x, size: 18, color: colorScheme.mutedForeground),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('標題', title, colorScheme),
                  _buildInfoRow('藝術家', artist, colorScheme),
                  _buildInfoRow('專輯', album, colorScheme),
                  _buildInfoRow('年份', year, colorScheme),
                  if (durationStr != null) _buildInfoRow('時長', durationStr, colorScheme),
                  if (suffix != null) _buildInfoRow('格式', suffix, colorScheme),
                  if (bitRate != null) _buildInfoRow('位元率', bitRate, colorScheme),
                  if (fileSizeMb != null) _buildInfoRow('檔案大小', fileSizeMb, colorScheme),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ShadButton(
                      onPressed: (isDownloading) ? null : () async {
                        final api = ref.read(subsonicApiProvider);
                        final songId = song['id']?.toString();
                        if (songId == null) return;
                        
                        try {
                          final fileExtension = song['suffix']?.toString().toLowerCase() ?? 'mp3';
                          final suggestedName = '${artist.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')} - ${title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')}.$fileExtension';
                          
                          final location = await getSaveLocation(
                            suggestedName: suggestedName,
                          );
                          
                          if (location == null) return; // User canceled
                          
                          setState(() => isDownloading = true);
                          ZenifyToast.showSuccess(context, '開始下載...');
                          
                          final db = ref.read(databaseProvider);
                          final downloadedTrack = await db.getDownloadedTrack(songId);
                          
                          if (downloadedTrack != null && downloadedTrack.isComplete) {
                            final localFile = File(downloadedTrack.localPath);
                            if (await localFile.exists()) {
                              // 從本機快取複製
                              await localFile.copy(location.path);
                              if (context.mounted) {
                                ZenifyToast.showSuccess(context, '下載完成！');
                              }
                              return;
                            }
                          }
                          
                          if (api == null) {
                            if (context.mounted) {
                              ZenifyToast.showError(context, '無法連接伺服器，且無本機快取');
                            }
                            return;
                          }
                          
                          // 如果沒有快取或快取不完整，回退到從網路下載
                          final url = api.getStreamUrl(songId);
                          final response = await http.get(Uri.parse(url));
                          
                          if (response.statusCode == 200) {
                            final file = File(location.path);
                            await file.writeAsBytes(response.bodyBytes);
                            if (context.mounted) {
                              ZenifyToast.showSuccess(context, '下載完成！');
                            }
                          } else {
                            if (context.mounted) {
                              ZenifyToast.showError(context, '下載失敗：HTTP ${response.statusCode}');
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ZenifyToast.showError(context, '下載時發生錯誤：$e');
                          }
                        } finally {
                          if (context.mounted) {
                            setState(() => isDownloading = false);
                          }
                        }
                      },
                      child: isDownloading 
                          ? SizedBox(
                              width: 16, 
                              height: 16, 
                              child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.primaryForeground)
                            )
                          : const Text('匯出音樂檔案'),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      );
    },
  );
}

Widget _buildInfoRow(String label, String value, ShadColorScheme colorScheme) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 5.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 75,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.mutedForeground,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}