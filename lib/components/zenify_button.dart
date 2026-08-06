import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

enum ZenifyButtonVariant { primary, secondary, outline, destructive, ghost }

class ZenifyButton extends StatefulWidget {
  final String text;
  final Widget? icon;
  final VoidCallback? onPressed;
  final ZenifyButtonVariant variant;
  final bool isLoading;
  final double? width;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final bool isCircular;

  const ZenifyButton({
    super.key,
    required this.text,
    this.icon,
    this.onPressed,
    this.variant = ZenifyButtonVariant.primary,
    this.isLoading = false,
    this.width,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.borderRadius = 14.0, // Match ZenifyInput
    this.isCircular = false,
  });

  @override
  State<ZenifyButton> createState() => _ZenifyButtonState();
}

class _ZenifyButtonState extends State<ZenifyButton> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _isPressed = false;

  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerEvent details) {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() => _isPressed = true);
      _scaleController.forward();
    }
  }

  void _onPointerUp(PointerEvent details) {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() => _isPressed = false);
      _scaleController.reverse();
    }
  }

  void _onPointerCancel(PointerEvent details) {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() => _isPressed = false);
      _scaleController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;
    final bool isDisabled = widget.onPressed == null || widget.isLoading;

    Color backgroundColor;
    Color foregroundColor;
    Color borderColor = Colors.transparent;

    switch (widget.variant) {
      case ZenifyButtonVariant.primary:
        backgroundColor = colorScheme.primary;
        foregroundColor = colorScheme.primaryForeground;
        break;
      case ZenifyButtonVariant.secondary:
        backgroundColor = colorScheme.secondary;
        foregroundColor = colorScheme.secondaryForeground;
        break;
      case ZenifyButtonVariant.destructive:
        backgroundColor = colorScheme.destructive;
        foregroundColor = colorScheme.destructiveForeground;
        break;
      case ZenifyButtonVariant.outline:
        backgroundColor = _isHovered ? colorScheme.foreground.withValues(alpha: 0.08) : Colors.transparent;
        foregroundColor = colorScheme.foreground;
        borderColor = _isHovered ? Colors.transparent : colorScheme.border;
        break;
      case ZenifyButtonVariant.ghost:
        backgroundColor = _isHovered ? colorScheme.foreground.withValues(alpha: 0.08) : Colors.transparent;
        foregroundColor = colorScheme.foreground;
        borderColor = Colors.transparent;
        break;
    }

    if (isDisabled) {
      backgroundColor = colorScheme.muted;
      foregroundColor = colorScheme.mutedForeground;
      borderColor = widget.variant == ZenifyButtonVariant.outline ? colorScheme.border : Colors.transparent;
    } else if (_isHovered && widget.variant != ZenifyButtonVariant.outline && widget.variant != ZenifyButtonVariant.ghost) {
      backgroundColor = backgroundColor.withValues(alpha: 0.85);
    }

    return MouseRegion(
      cursor: isDisabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Listener(
        onPointerDown: _onPointerDown,
        onPointerUp: _onPointerUp,
        onPointerCancel: _onPointerCancel,
        child: GestureDetector(
          onTap: isDisabled ? null : widget.onPressed,
          behavior: HitTestBehavior.opaque,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: widget.width,
              padding: widget.padding,
              decoration: BoxDecoration(
                color: backgroundColor,
                shape: widget.isCircular ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: widget.isCircular ? null : BorderRadius.circular(widget.borderRadius),
                border: widget.isCircular && borderColor == Colors.transparent 
                    ? null 
                    : Border.all(color: borderColor, width: 1.0),
              ),
              child: Row(
                mainAxisSize: widget.width == null ? MainAxisSize.min : MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.isLoading) ...[
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        color: foregroundColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ] else if (widget.icon != null) ...[
                    widget.icon!,
                    if (widget.text.isNotEmpty) const SizedBox(width: 8),
                  ],
                  if (widget.text.isNotEmpty)
                    Text(
                      widget.text,
                      style: TextStyle(
                        color: foregroundColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
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
