import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class ZenifyPopover extends StatefulWidget {
  final Widget child;
  final Widget Function(BuildContext context, VoidCallback close) builder;
  final ShadAnchor? anchor;
  final ValueChanged<bool>? onOpenChanged;

  const ZenifyPopover({
    super.key,
    required this.child,
    required this.builder,
    this.anchor,
    this.onOpenChanged,
  });

  @override
  State<ZenifyPopover> createState() => _ZenifyPopoverState();
}

class _ZenifyPopoverState extends State<ZenifyPopover> {
  final ShadPopoverController _controller = ShadPopoverController();
  ShadAnchor? _dynamicAnchor;

  @override
  void initState() {
    super.initState();
    if (widget.onOpenChanged != null) {
      _controller.addListener(() {
        widget.onOpenChanged!(_controller.isOpen);
      });
    }
  }

  void _close() {
    _controller.hide();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    // 強制解除可能因為點擊而被觸發的 ListTile 焦點
    FocusManager.instance.primaryFocus?.unfocus();

    if (widget.anchor != null) {
      _controller.toggle();
      return;
    }

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final position = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;
      final screenHeight = MediaQuery.of(context).size.height;
      final screenWidth = MediaQuery.of(context).size.width;

      final safeBottomEdge = screenHeight - 120; // 底部導航欄與播放器預估
      final safeTopEdge = 80; // 頂部導航列預估
      
      final spaceBelow = safeBottomEdge - (position.dy + size.height);
      final spaceAbove = position.dy - safeTopEdge;

      final popoverHeight = 260.0;
      
      final bool canFitBelow = spaceBelow >= popoverHeight;
      final bool canFitAbove = spaceAbove >= popoverHeight;

      bool shouldFlipUp = false;
      if (canFitAbove && !canFitBelow) {
        shouldFlipUp = true;
      } else {
        shouldFlipUp = false; // 如果兩者都成立（或兩者都不成立）就在底部顯示
      }

      final triggerRightX = position.dx + size.width;
      double dxOffset = 0;
      final margin = 16.0;
      if (screenWidth - triggerRightX < margin) {
        dxOffset = -(margin - (screenWidth - triggerRightX));
      }

      final newAnchor = shouldFlipUp
          ? ShadAnchor(
              // 向上翻轉：選單的右下角 (bottomRight) 對齊觸發按鈕的右上角 (topRight)
              childAlignment: Alignment.bottomRight,
              overlayAlignment: Alignment.topRight,
              offset: Offset(dxOffset, -8),
            )
          : ShadAnchor(
              // 向下展開：選單的右上角 (topRight) 對齊觸發按鈕的右下角 (bottomRight)
              childAlignment: Alignment.topRight,
              overlayAlignment: Alignment.bottomRight,
              offset: Offset(dxOffset, 8),
            );

      if (_dynamicAnchor != newAnchor) {
        setState(() {
          _dynamicAnchor = newAnchor;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _controller.toggle();
        });
        return;
      }
    }

    _controller.toggle();
  }

  @override
  Widget build(BuildContext context) {
    return ShadPopover(
      controller: _controller,
      anchor: widget.anchor ?? _dynamicAnchor,
      popover: (context) => widget.builder(context, _close),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _handleTap,
          child: widget.child,
        ),
      ),
    );
  }
}

class ZenifyPopoverItem extends StatefulWidget {
  final IconData? icon;
  final String label;
  final ShadColorScheme colorScheme;
  final VoidCallback onTap;
  final bool isSelected;
  final Widget? trailing;

  const ZenifyPopoverItem({
    super.key,
    this.icon,
    required this.label,
    required this.colorScheme,
    required this.onTap,
    this.isSelected = false,
    this.trailing,
  });

  @override
  State<ZenifyPopoverItem> createState() => _ZenifyPopoverItemState();
}

class _ZenifyPopoverItemState extends State<ZenifyPopoverItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bool highlight = _isHovered || widget.isSelected;
    final fgColor = highlight ? widget.colorScheme.foreground : widget.colorScheme.mutedForeground;
    
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: _isHovered
                ? widget.colorScheme.foreground.withValues(alpha: 0.06)
                : (widget.isSelected ? widget.colorScheme.muted.withValues(alpha: 0.3) : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 14,
                  color: fgColor,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  color: fgColor,
                  fontWeight: highlight ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
              if (widget.trailing != null) ...[
                const SizedBox(width: 16),
                widget.trailing!,
              ] else if (widget.icon != null) ...[
                // If there's an icon, add trailing padding for consistent width
                const SizedBox(width: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
