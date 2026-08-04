import 'package:zenify/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:zenify/components/local_cover_image.dart';
import 'package:zenify/components/zenify_toast.dart';
import 'package:zenify/components/zenify_toast.dart';

class AlbumCard extends StatefulWidget {
  final String title;
  final String artist;
  final String? coverArtId;
  final String? fallbackCoverUrl;
  final int serverId;
  final String? yearText;
  final bool isOfflineAlbum;
  final VoidCallback onTap;
  final VoidCallback? onPlayTap;
  final VoidCallback? onMoreTap;
  final VoidCallback? onArtistTap;
  final double padding;
  final bool isDisabled;
  final bool isArtistDisabled;
  final bool isStarred;
  final Future<void> Function(bool)? onStarToggle;

  const AlbumCard({
    super.key,
    required this.title,
    required this.artist,
    required this.coverArtId,
    required this.fallbackCoverUrl,
    required this.serverId,
    required this.onTap,
    this.yearText,
    this.isOfflineAlbum = false,
    this.onPlayTap,
    this.onMoreTap,
    this.onArtistTap,
    this.padding = 10.0,
    this.isDisabled = false,
    this.isArtistDisabled = false,
    this.isStarred = false,
    this.onStarToggle,
  });

  @override
  State<AlbumCard> createState() => _AlbumCardState();
}

class _AlbumCardState extends State<AlbumCard> {
  bool _isHovered = false;
  bool _isArtistHovered = false;
  bool _isStarHovered = false;
  bool? _optimisticIsStarred;
  bool _isUpdatingStar = false;

  @override
  void didUpdateWidget(covariant AlbumCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isStarred != widget.isStarred) {
      _optimisticIsStarred = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;

    return MouseRegion(
      cursor: widget.isDisabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.isDisabled ? () {
          ZenifyToast.showError(context, l10n.serverOffline);
        } : widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Opacity(
          opacity: widget.isDisabled ? 0.4 : 1.0,
          child: AbsorbPointer(
            absorbing: widget.isDisabled,
            child: Container(
              padding: EdgeInsets.all(widget.padding),
          decoration: const BoxDecoration(
            color: Colors.transparent,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Apple Music Web Album Cover Container
              AspectRatio(
                aspectRatio: 1,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
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
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return Icon(
                                  LucideIcons.music,
                                  color: colorScheme.mutedForeground,
                                  size: constraints.maxWidth * 0.28,
                                );
                              },
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
                                // Translucent darkening mask on hover (50%)
                                Container(
                                  color: Colors.black.withValues(alpha: 0.50),
                                ),
                                  // Top Left Year Label
                                  if (widget.yearText != null && widget.yearText!.isNotEmpty)
                                    Positioned(
                                      left: 10,
                                      top: 10,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.2),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          widget.yearText!,
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  // Top Right Star Button
                                  if ((_isHovered || _isUpdatingStar) && widget.onStarToggle != null)
                                    Positioned(
                                      right: 10,
                                      top: 10,
                                      child: MouseRegion(
                                        cursor: SystemMouseCursors.click,
                                        onEnter: (_) {
                                          if (!widget.isArtistDisabled) setState(() => _isStarHovered = true);
                                        },
                                        onExit: (_) {
                                          if (!widget.isArtistDisabled) setState(() => _isStarHovered = false);
                                        },
                                        child: GestureDetector(
                                          onTap: widget.isArtistDisabled
                                            ? () {
                                                ZenifyToast.showError(context, l10n.serverOffline);
                                              }
                                            : (_isUpdatingStar ? null : () async {
                                                setState(() => _isUpdatingStar = true);
                                                try {
                                                  final isCurrentlyStarred = _optimisticIsStarred ?? widget.isStarred;
                                                  await widget.onStarToggle!(!isCurrentlyStarred);
                                                  if (mounted) {
                                                    setState(() {
                                                      _optimisticIsStarred = !isCurrentlyStarred;
                                                    });
                                                    ZenifyToast.showSuccess(context, isCurrentlyStarred ? l10n.unfavorited : l10n.favorited);
                                                  }
                                                } catch (e) {
                                                  if (mounted) {
                                                    ZenifyToast.showError(context, l10n.favoriteFailed(e.toString()));
                                                  }
                                                } finally {
                                                  if (mounted) {
                                                    setState(() => _isUpdatingStar = false);
                                                  }
                                                }
                                              }),
                                          child: Opacity(
                                            opacity: widget.isArtistDisabled ? 0.5 : 1.0,
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: _isStarHovered ? Colors.black : Colors.white,
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withValues(alpha: 0.2),
                                                    blurRadius: 6,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: _isUpdatingStar
                                                  ? SizedBox(
                                                      width: 16,
                                                      height: 16,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: _isStarHovered ? Colors.white : Colors.black,
                                                      ),
                                                    )
                                                  : Icon(
                                                      (_optimisticIsStarred ?? widget.isStarred) ? Icons.favorite : Icons.favorite_border,
                                                      color: (_optimisticIsStarred ?? widget.isStarred) 
                                                        ? Colors.red 
                                                        : (_isStarHovered ? Colors.white : Colors.black),
                                                      size: 16,
                                                    ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                // Bottom Left Play Button
                                Positioned(
                                  left: 10,
                                  bottom: 10,
                                  child: _AlbumPlayButton(
                                    onTap: () {
                                      if (widget.onPlayTap != null) {
                                        widget.onPlayTap!();
                                      } else {
                                        widget.onTap();
                                      }
                                    },
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
              ),
              const SizedBox(height: 2),
              // Title (Apple Music w600 weight)
              Text(
                widget.title,
                style: TextStyle(
                  color: colorScheme.foreground,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  letterSpacing: 0.1,
                  height: 1.15,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.left,
              ),
              const SizedBox(height: 2),
              // Artist (Apple Music 11px muted text, clickable)
              MouseRegion(
                  cursor: (widget.onArtistTap != null) ? SystemMouseCursors.click : SystemMouseCursors.basic,
                  onEnter: (_) => setState(() => _isArtistHovered = true),
                  onExit: (_) => setState(() => _isArtistHovered = false),
                  child: GestureDetector(
                    onTap: widget.isArtistDisabled ? () {
                      ZenifyToast.showError(context, l10n.serverOffline);
                    } : widget.onArtistTap,
                    child: Text(
                      widget.artist,
                      style: TextStyle(
                        color: _isArtistHovered && widget.onArtistTap != null && !widget.isArtistDisabled
                            ? colorScheme.foreground
                            : colorScheme.mutedForeground,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.15,
                        height: 1.15,
                        decoration: _isArtistHovered && widget.onArtistTap != null && !widget.isArtistDisabled
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
  ),
);
  }
}

class _AlbumPlayButton extends StatefulWidget {
  final VoidCallback onTap;

  const _AlbumPlayButton({required this.onTap});

  @override
  State<_AlbumPlayButton> createState() => _AlbumPlayButtonState();
}

class _AlbumPlayButtonState extends State<_AlbumPlayButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          customBorder: const CircleBorder(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isHovered ? Colors.black : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              LucideIcons.play,
              color: _isHovered ? Colors.white : Colors.black,
              size: 16,
            ),
          ),
        ),
      ),
    );
  }
}

