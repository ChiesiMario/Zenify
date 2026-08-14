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
    this.borderRadius = 8.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  });

  @override
  State<ZenifySelect<T>> createState() => _ZenifySelectState<T>();
}

class _ZenifySelectState<T> extends State<ZenifySelect<T>> {
  bool _isHovered = false;
  late final FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    }
  }

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
        borderColor = _isHovered ? colorScheme.foreground.withValues(alpha: 0.4) : colorScheme.border;
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 48,
        decoration: BoxDecoration(
          color: _isFocused ? colorScheme.background : (widget.variant == ZenifyButtonVariant.outline ? colorScheme.card : backgroundColor),
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(
            color: _isFocused ? colorScheme.primary : borderColor,
            width: 1.0,
          ),
        ),
        child: ShadSelect<T>(
          focusNode: _focusNode,
          initialValue: widget.initialValue,
          placeholder: widget.placeholder,
          options: widget.options,
          selectedOptionBuilder: widget.selectedOptionBuilder,
          onChanged: widget.onChanged,
          decoration: const ShadDecoration(
            color: Colors.transparent,
            border: ShadBorder.none,
            focusedBorder: ShadBorder.none,
            secondaryBorder: ShadBorder.none,
            secondaryFocusedBorder: ShadBorder.none,
          ),
        ),
      ),
    );
  }
}
