import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:zenify/providers/audio_provider.dart';
import 'package:zenify/providers/app_providers.dart';
import 'package:zenify/components/local_cover_image.dart';
import 'package:zenify/components/play_queue_sheet.dart';
import 'package:zenify/screens/album_detail_screen.dart';
import 'package:zenify/screens/artist_detail_screen.dart';

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
              color: colorScheme.background,
              shape: RoundedRectangleBorder(
                borderRadius: isCompact ? BorderRadius.zero : const BorderRadius.vertical(top: Radius.circular(20)),
                side: BorderSide.none,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
              // 頂部列：左側為縮小淡化收起按鈕，右側為播放佇列按鈕
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _TopUtilityButton(
                      icon: LucideIcons.chevronDown,
                      tooltip: '收起',
                      onPressed: () => Navigator.pop(context),
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
              ),
              
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
                                              coverUrl == null 
                                                  ? Center(child: Icon(LucideIcons.music, size: 80, color: colorScheme.mutedForeground))
                                                  : LocalCoverImage(
                                                      id: currentSong['coverArt'],
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
                      const SizedBox(height: 16),
                          
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

  const _HoverableLink({
    Key? key,
    required this.text,
    required this.onTap,
    required this.style,
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
        onTap: widget.onTap,
        child: Text(
          widget.text,
          style: widget.style.copyWith(
            decoration: _isHovered ? TextDecoration.underline : TextDecoration.none,
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
  final VoidCallback onPressed;
  final String tooltip;

  const _TopUtilityButton({
    Key? key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
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
    
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
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
              opacity: _isPressed ? 0.5 : (_isHovered ? 1.0 : 0.7),
              duration: const Duration(milliseconds: 150),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  widget.icon,
                  size: 20, // 稍微加大一點點，增加精緻感與點擊識別度
                  color: colorScheme.mutedForeground,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}