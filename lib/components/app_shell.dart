import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenify/components/custom_title_bar.dart';
import 'package:zenify/providers/theme_provider.dart';

class AppShell extends ConsumerWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            View.of(context).platformDispatcher.platformBrightness == Brightness.dark);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 32.0),
            child: child,
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 32.0,
            child: Material(
              type: MaterialType.transparency,
              child: CustomTitleBar(isDark: isDark),
            ),
          ),
        ],
      ),
    );
  }
}
