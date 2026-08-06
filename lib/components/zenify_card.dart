import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class ZenifyCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final bool withBorder;

  const ZenifyCard({
    super.key,
    required this.child,
    this.borderRadius = 14.0, // Match ZenifyInput
    this.padding = const EdgeInsets.all(16.0),
    this.withBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: colorScheme.card,
        borderRadius: BorderRadius.circular(borderRadius),
        border: withBorder
            ? Border.all(color: colorScheme.border, width: 1.0)
            : null,
      ),
      child: child,
    );
  }
}
