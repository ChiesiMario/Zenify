import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:zenify/components/local_cover_image.dart';

class ArtistCard extends StatefulWidget {
  final String name;
  final String artistId;
  final String? coverArtId;
  final String? fallbackCoverUrl;
  final int serverId;
  final VoidCallback onTap;
  final double width;

  const ArtistCard({
    super.key,
    required this.name,
    required this.artistId,
    required this.coverArtId,
    required this.fallbackCoverUrl,
    required this.serverId,
    required this.onTap,
    this.width = 100.0,
  });

  @override
  State<ArtistCard> createState() => _ArtistCardState();
}

class _ArtistCardState extends State<ArtistCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: widget.width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: widget.width,
                height: widget.width,
                decoration: BoxDecoration(
                  color: colorScheme.muted,
                  shape: BoxShape.circle,
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if ((widget.coverArtId == null || widget.coverArtId!.isEmpty) && widget.fallbackCoverUrl == null)
                      Center(child: Icon(LucideIcons.user, color: colorScheme.mutedForeground, size: widget.width * 0.24))
                    else
                      LocalCoverImage(
                        id: widget.coverArtId ?? widget.artistId,
                        serverId: widget.serverId,
                        fallbackUrl: widget.fallbackCoverUrl,
                        isThumb: true,
                      ),
                    // Translucent darkening mask on hover (50%)
                    Positioned.fill(
                      child: AnimatedOpacity(
                        opacity: _isHovered ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 150),
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.50),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.name,
                style: TextStyle(
                  color: colorScheme.foreground,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  decoration: _isHovered ? TextDecoration.underline : TextDecoration.none,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
