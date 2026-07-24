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

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth <= 400;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
          child: Container(
            margin: isSmallScreen ? EdgeInsets.zero : const EdgeInsets.only(top: 10),
            decoration: ShapeDecoration(
              color: colorScheme.background,
              shape: RoundedRectangleBorder(
                borderRadius: isSmallScreen ? BorderRadius.zero : const BorderRadius.vertical(top: Radius.circular(20)),
                side: isSmallScreen ? BorderSide.none : BorderSide(color: colorScheme.border, width: 1.0),
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
                    IconButton(
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      icon: Icon(
                        LucideIcons.chevronDown,
                        size: 18,
                        color: colorScheme.mutedForeground.withValues(alpha: 0.7),
                      ),
                      onPressed: () => Navigator.pop(context),
                      tooltip: '收起',
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                    ),
                    IconButton(
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      icon: Icon(
                        LucideIcons.listMusic,
                        size: 18,
                        color: colorScheme.mutedForeground.withValues(alpha: 0.7),
                      ),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => FractionallySizedBox(
                            heightFactor: 0.8,
                            child: const PlayQueueSheet(),
                          ),
                        );
                      },
                      tooltip: '播放佇列',
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      hoverColor: Colors.transparent,
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
                                        foregroundDecoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: colorScheme.foreground.withValues(alpha: 0.08),
                                            width: 1.0,
                                          ),
                                        ),
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

                          // 播放控制區塊
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              IconButton(
                                icon: Icon(
                                  LucideIcons.shuffle, 
                                  color: audioState.isShuffled ? colorScheme.foreground : colorScheme.mutedForeground.withValues(alpha: 0.5)
                                ),
                                iconSize: 22,
                                onPressed: () => audioNotifier.toggleShuffle(),
                                splashColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                              ),
                              IconButton(
                                icon: Icon(LucideIcons.skipBack, color: colorScheme.foreground),
                                iconSize: 36,
                                onPressed: () => audioNotifier.skipToPrevious(),
                                splashColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                              ),
                              // 播放暫停按鈕
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: colorScheme.foreground,
                                  boxShadow: [
                                    BoxShadow(
                                      color: colorScheme.foreground.withValues(alpha: 0.2),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    audioState.isPlaying ? LucideIcons.pause : LucideIcons.play, 
                                    color: colorScheme.background
                                  ),
                                  iconSize: 32,
                                  onPressed: () => audioNotifier.togglePlayPause(),
                                ),
                              ),
                              IconButton(
                                icon: Icon(LucideIcons.skipForward, color: colorScheme.foreground),
                                iconSize: 36,
                                onPressed: () => audioNotifier.skipToNext(),
                                splashColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                              ),
                              IconButton(
                                icon: Icon(
                                  audioState.repeatMode == AudioRepeatMode.one 
                                      ? LucideIcons.repeat1 
                                      : LucideIcons.repeat,
                                  color: audioState.repeatMode != AudioRepeatMode.off 
                                      ? colorScheme.foreground 
                                      : colorScheme.mutedForeground.withValues(alpha: 0.5),
                                ),
                                iconSize: 22,
                                onPressed: () => audioNotifier.toggleRepeat(),
                                splashColor: Colors.transparent,
                                highlightColor: Colors.transparent,
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