import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:zenify/services/image_service.dart';

class LocalCoverImage extends StatefulWidget {
  final String id;
  final int serverId;
  final String fallbackUrl;
  final BoxFit fit;
  final bool isThumb;

  const LocalCoverImage({
    super.key,
    required this.id,
    required this.serverId,
    required this.fallbackUrl,
    this.fit = BoxFit.cover,
    this.isThumb = true,
  });

  @override
  State<LocalCoverImage> createState() => _LocalCoverImageState();
}

class _LocalCoverImageState extends State<LocalCoverImage> {
  File? _localFile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _syncCheckFile();
  }

  @override
  void didUpdateWidget(covariant LocalCoverImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id || oldWidget.serverId != widget.serverId || oldWidget.isThumb != widget.isThumb) {
      _syncCheckFile();
    }
  }

  void _syncCheckFile() {
    try {
      final isCached = ImageService().isCoverCachedSync(widget.id, widget.serverId, isThumb: widget.isThumb);
      if (isCached) {
        final path = ImageService().getCoverPathSync(widget.id, widget.serverId, isThumb: widget.isThumb);
        _localFile = File(path);
        _isLoading = false;
      } else {
        _isLoading = true;
        _checkLocalFileAsync();
      }
    } catch (_) {
      _isLoading = false;
    }
  }

  Future<void> _checkLocalFileAsync() async {
    try {
      final path = ImageService().getCoverPathSync(widget.id, widget.serverId, isThumb: widget.isThumb);
      final file = File(path);
      
      final success = await ImageService().downloadImage(widget.fallbackUrl, widget.id, widget.serverId, isThumb: widget.isThumb);
      if (mounted) {
        setState(() {
          _localFile = success ? file : null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _localFile = null;
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildPlaceholder(BuildContext context) {
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      color: colorScheme.muted,
      child: Center(
        child: Icon(LucideIcons.music, color: colorScheme.mutedForeground),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _localFile == null) {
      return _buildPlaceholder(context);
    }
    
    return Image.file(
      _localFile!, 
      fit: widget.fit, 
      cacheWidth: widget.isThumb ? 250 : null,
      errorBuilder: (context, error, stackTrace) {
        return _buildPlaceholder(context);
      }
    );
  }
}
