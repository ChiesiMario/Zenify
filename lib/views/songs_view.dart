import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class SongsView extends ConsumerWidget {
  const SongsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.music, size: 64, color: colorScheme.mutedForeground.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            '歌曲清單即將推出',
            style: TextStyle(color: colorScheme.mutedForeground, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
