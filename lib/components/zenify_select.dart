import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:zenify/components/zenify_button.dart';

class ZenifySelect<T> extends StatefulWidget {
  final T? initialValue;
  final Widget? placeholder;
  final List<Widget> options;
  final Widget Function(BuildContext, T)? selectedOptionBuilder;
  final ValueChanged<T?>? onChanged;
  final ZenifyButtonVariant variant;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  const ZenifySelect({
    super.key,
    this.initialValue,
    this.placeholder,
    required this.options,
    this.selectedOptionBuilder,
    this.onChanged,
    this.variant = ZenifyButtonVariant.outline,
    this.borderRadius = 14.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  });

  @override
  State<ZenifySelect<T>> createState() => _ZenifySelectState<T>();
}

class _ZenifySelectState<T> extends State<ZenifySelect<T>> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;
    final bool isDisabled = widget.onChanged == null;

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
        backgroundColor = _isHovered ? colorScheme.secondary : Colors.transparent;
        foregroundColor = colorScheme.foreground;
        borderColor = colorScheme.border;
        break;
      case ZenifyButtonVariant.ghost:
        backgroundColor = _isHovered ? colorScheme.secondary : Colors.transparent;
        foregroundColor = colorScheme.foreground;
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
      child: SizedBox(
        height: 48,
        child: ShadSelect<T>(
          initialValue: widget.initialValue,
          placeholder: widget.placeholder,
          options: widget.options,
          selectedOptionBuilder: widget.selectedOptionBuilder,
          onChanged: widget.onChanged,
          decoration: ShadDecoration(
            color: backgroundColor,
            border: ShadBorder.all(
              color: borderColor,
              width: 1.0,
              radius: BorderRadius.circular(widget.borderRadius),
            ),
            focusedBorder: ShadBorder.all(
              color: colorScheme.primary,
              width: 1.0,
              radius: BorderRadius.circular(widget.borderRadius),
            ),
          ),
        ),
      ),
    );
  }
}
