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

  const ArtistCard({
    super.key,
    required this.name,
    required this.artistId,
    required this.coverArtId,
    required this.fallbackCoverUrl,
    required this.serverId,
    required this.onTap,
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                decoration: BoxDecoration(
                  color: colorScheme.muted,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: _isHovered ? 0.15 : 0.05),
                      blurRadius: _isHovered ? 16 : 8,
                      offset: Offset(0, _isHovered ? 6 : 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if ((widget.coverArtId == null || widget.coverArtId!.isEmpty) && widget.fallbackCoverUrl == null)
                      Center(child: Icon(LucideIcons.user, color: colorScheme.mutedForeground, size: 40))
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
            ),
            const SizedBox(height: 2),
            Text(
              widget.name,
              style: TextStyle(
                color: colorScheme.foreground,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                letterSpacing: 0.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
