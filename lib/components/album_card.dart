import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:zenify/components/local_cover_image.dart';

class AlbumCard extends StatefulWidget {
  final String title;
  final String artist;
  final String? coverArtId;
  final String? fallbackCoverUrl;
  final int serverId;
  final VoidCallback onTap;
  final VoidCallback? onPlayTap;
  final VoidCallback? onMoreTap;
  final VoidCallback? onArtistTap;
  final double width;
  final double padding;

  const AlbumCard({
    super.key,
    required this.title,
    required this.artist,
    required this.coverArtId,
    required this.fallbackCoverUrl,
    required this.serverId,
    required this.onTap,
    this.onPlayTap,
    this.onMoreTap,
    this.onArtistTap,
    this.width = 150.0,
    this.padding = 10.0,
  });

  @override
  State<AlbumCard> createState() => _AlbumCardState();
}

class _AlbumCardState extends State<AlbumCard> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isArtistHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;
    final isActive = _isHovered || _isPressed;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _isPressed = false;
      }),
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: isActive ? 1.025 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            width: widget.width + (widget.padding * 2),
            padding: EdgeInsets.all(widget.padding),
            decoration: BoxDecoration(
              color: isActive
                  ? colorScheme.foreground.withValues(alpha: 0.05)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Apple Music Web Album Cover Container
                AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  width: widget.width,
                  height: widget.width,
                  decoration: BoxDecoration(
                    color: colorScheme.muted,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: _isHovered ? 0.15 : 0.08),
                        blurRadius: _isHovered ? 16 : 10,
                        offset: Offset(0, _isHovered ? 6 : 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    clipBehavior: Clip.antiAliasWithSaveLayer,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Cover Image
                        LocalCoverImage(
                          id: widget.coverArtId ?? '',
                          serverId: widget.serverId,
                          fallbackUrl: widget.fallbackCoverUrl,
                        ),
                        // Fallback Music Icon
                        if ((widget.coverArtId == null || widget.coverArtId!.isEmpty) && widget.fallbackCoverUrl == null)
                          Center(
                            child: Icon(
                              LucideIcons.music,
                              color: colorScheme.mutedForeground,
                              size: widget.width * 0.28,
                            ),
                          ),
                        // Apple Music Sub-pixel Inner Border
                        IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: colorScheme.foreground.withValues(alpha: 0.08),
                                width: 1.0,
                              ),
                            ),
                          ),
                        ),
                        // Apple Music Hover Play & More Buttons Overlay
                        Positioned.fill(
                          child: AnimatedOpacity(
                            opacity: _isHovered ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 150),
                            child: Stack(
                              children: [
                                 // Bottom Left Play Button
                                Positioned(
                                  left: 10,
                                  bottom: 10,
                                  child: MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: GestureDetector(
                                      onTap: () {
                                        if (widget.onPlayTap != null) {
                                          widget.onPlayTap!();
                                        } else {
                                          widget.onTap();
                                        }
                                      },
                                      child: Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white.withValues(alpha: 0.9),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.2),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          LucideIcons.play,
                                          color: Colors.black,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                // Title (Apple Music w600 weight)
                Text(
                  widget.title,
                  style: TextStyle(
                    color: colorScheme.foreground,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: 2),
                // Artist (Apple Music 11px muted text, clickable)
                MouseRegion(
                  cursor: widget.onArtistTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
                  onEnter: (_) => setState(() => _isArtistHovered = true),
                  onExit: (_) => setState(() => _isArtistHovered = false),
                  child: GestureDetector(
                    onTap: widget.onArtistTap,
                    child: Text(
                      widget.artist,
                      style: TextStyle(
                        color: _isArtistHovered && widget.onArtistTap != null
                            ? colorScheme.foreground
                            : colorScheme.mutedForeground,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        height: 1.1,
                        decoration: _isArtistHovered && widget.onArtistTap != null
                            ? TextDecoration.underline
                            : TextDecoration.none,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.left,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
