import 'package:zenify/l10n/app_localizations.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:zenify/providers/audio_provider.dart';
import 'package:zenify/providers/app_providers.dart';
import 'package:zenify/components/local_cover_image.dart';

class PlayQueueSheet extends ConsumerStatefulWidget {
  const PlayQueueSheet({super.key});

  @override
  ConsumerState<PlayQueueSheet> createState() => _PlayQueueSheetState();
}

class _PlayQueueSheetState extends ConsumerState<PlayQueueSheet> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final audioState = ref.read(audioProvider);
        final currentIndex = audioState.currentIndex;
        if (currentIndex > 0) {
          // 每個項目大約高 66px，減去兩三個項目高度讓他置中顯示
          double offset = (currentIndex * 66.0) - (66.0 * 2);
          offset = offset.clamp(0.0, double.infinity);
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(offset);
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;
    final audioState = ref.watch(audioProvider);
    final audioNotifier = ref.read(audioProvider.notifier);
    
    // Fallback if not ready
    final server = ref.watch(activeServerProvider).value;
    final api = ref.watch(subsonicApiProvider);

    final queue = audioState.queue;
    final currentIndex = audioState.currentIndex;

    return Container(
      padding: const EdgeInsets.only(top: 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colorScheme.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: theme.brightness == Brightness.dark 
            ? Border(
                top: BorderSide(color: colorScheme.border, width: 1),
                left: BorderSide(color: colorScheme.border, width: 1),
                right: BorderSide(color: colorScheme.border, width: 1),
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle for bottom sheet
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: colorScheme.mutedForeground.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 24),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  l10n.playQueue,
                  style: TextStyle(
                    color: colorScheme.foreground,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  l10n.queueSongCount(queue.length.toString()),
                  style: TextStyle(
                    color: colorScheme.mutedForeground,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Queue list
          Flexible(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Theme(
                data: Theme.of(context).copyWith(
                  canvasColor: Colors.transparent,
                  scrollbarTheme: const ScrollbarThemeData(
                    crossAxisMargin: 2.0,
                    radius: Radius.circular(8),
                  ),
                ),
                child: ReorderableListView.builder(
                  scrollController: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  buildDefaultDragHandles: false,
                  itemCount: queue.length,
                  onReorder: (oldIndex, newIndex) {
                    audioNotifier.reorderQueue(oldIndex, newIndex);
                  },
                  proxyDecorator: (child, index, animation) {
                    return Material(
                      color: Colors.transparent,
                      child: Stack(
                        children: [
                          // 精準對齊視覺邊界，排除 child 底部的 6px Padding
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            bottom: 6.0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Color.lerp(colorScheme.background, colorScheme.foreground, 0.05),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          child,
                        ],
                      ),
                    );
                  },
                itemBuilder: (context, index) {
                  final song = queue[index];
                  final isCurrent = index == currentIndex;
                  final duration = song['duration'] != null ? _formatDuration(song['duration']) : '--:--';
                  final albumCoverId = song['albumId']?.toString() ?? song['coverArt']?.toString();
                  final fallbackUrl = api != null && albumCoverId != null
                      ? api.getCoverArtUrl(albumCoverId, size: 250)
                      : null;

                  return _QueueItem(
                    key: ValueKey('${song['id']}_$index'),
                    index: index,
                    song: song,
                    isCurrent: isCurrent,
                    duration: duration,
                    albumCoverId: albumCoverId?.toString(),
                    fallbackUrl: fallbackUrl,
                    serverId: server?.id ?? 0,
                    colorScheme: colorScheme,
                    onTap: () {
                      audioNotifier.playQueue(queue, index);
                    },
                    onRemove: () {
                      audioNotifier.removeFromQueue(index);
                    },
                  );
                },
              ),
            ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QueueItem extends StatefulWidget {
  final int index;
  final dynamic song;
  final bool isCurrent;
  final String duration;
  final String? albumCoverId;
  final String? fallbackUrl;
  final int serverId;
  final ShadColorScheme colorScheme;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _QueueItem({
    super.key,
    required this.index,
    required this.song,
    required this.isCurrent,
    required this.duration,
    this.albumCoverId,
    this.fallbackUrl,
    required this.serverId,
    required this.colorScheme,
    required this.onTap,
    required this.onRemove,
  });

  @override
  State<_QueueItem> createState() => _QueueItemState();
}

class _QueueItemState extends State<_QueueItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: widget.isCurrent
                ? widget.colorScheme.foreground.withOpacity(_isHovered ? 0.12 : 0.08)
                : widget.colorScheme.foreground.withOpacity(_isHovered ? 0.05 : 0.0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              hoverColor: Colors.transparent,
              highlightColor: Colors.transparent,
              focusColor: Colors.transparent,
              splashColor: widget.colorScheme.foreground.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                children: [
                  // 拖曳把手
                  ReorderableDragStartListener(
                    index: widget.index,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12, left: 4),
                      child: Icon(
                        LucideIcons.gripVertical,
                        size: 16,
                        color: widget.colorScheme.mutedForeground.withOpacity(_isHovered || widget.isCurrent ? 0.7 : 0.3),
                      ),
                    ),
                  ),
                  // 專輯封面
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: widget.colorScheme.muted,
                      boxShadow: [
                        if (!widget.isCurrent)
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        if (widget.albumCoverId != null)
                          Positioned.fill(
                            child: LocalCoverImage(
                              id: widget.albumCoverId!,
                              serverId: widget.serverId,
                              fallbackUrl: widget.fallbackUrl,
                            ),
                          )
                        else
                          Center(
                            child: Icon(
                              LucideIcons.music,
                              color: widget.colorScheme.mutedForeground,
                              size: 20,
                            ),
                          ),
                        if (widget.isCurrent)
                          Positioned.fill(
                            child: Container(
                              color: Colors.black.withOpacity(0.3),
                              child: const Center(
                                child: Icon(
                                  LucideIcons.barChart2,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  // 歌曲與藝術家資訊
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.song['title'] ?? l10n.unknownSong,
                          style: TextStyle(
                            color: widget.isCurrent ? widget.colorScheme.primary : widget.colorScheme.foreground,
                            fontSize: 15,
                            fontWeight: widget.isCurrent ? FontWeight.bold : FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.song['artist'] ?? l10n.unknownArtist,
                          style: TextStyle(
                            color: widget.isCurrent 
                                ? widget.colorScheme.primary.withOpacity(0.8) 
                                : widget.colorScheme.mutedForeground,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 時間與移除按鈕
                  Text(
                    widget.duration,
                    style: TextStyle(
                      color: widget.isCurrent ? widget.colorScheme.primary : widget.colorScheme.mutedForeground,
                      fontSize: 13,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 150),
                    opacity: _isHovered ? 1.0 : (widget.isCurrent ? 0.3 : 0.0),
                    child: IconButton(
                      icon: const Icon(LucideIcons.x, size: 16),
                      color: widget.colorScheme.mutedForeground,
                      onPressed: widget.onRemove,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      tooltip: l10n.removeFromQueue,
                      hoverColor: widget.colorScheme.destructive.withOpacity(0.1),
                      highlightColor: widget.colorScheme.destructive.withOpacity(0.2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ));
  }
}
