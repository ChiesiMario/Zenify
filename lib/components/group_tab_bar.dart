import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class GroupTabBar extends StatelessWidget {
  final List<Widget> tabs;
  final TabController? controller;
  final double? maxWidth;

  const GroupTabBar({
    super.key,
    required this.tabs,
    this.controller,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Default max width is roughly 120px per tab if not provided
    final calculatedMaxWidth = maxWidth ?? (tabs.length * 120.0);

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: calculatedMaxWidth),
      child: Container(
        height: 52,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: colorScheme.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: colorScheme.border,
            width: 1.0,
          ),
        ),
        child: TabBar(
          controller: controller,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          dividerColor: Colors.transparent,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(10),
          ),
          labelColor: colorScheme.primaryForeground,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700, 
            fontSize: 13, 
            letterSpacing: 0.2,
          ),
          unselectedLabelColor: colorScheme.foreground.withValues(alpha: 0.5),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500, 
            fontSize: 13,
          ),
          tabs: tabs,
        ),
      ),
    );
  }
}
