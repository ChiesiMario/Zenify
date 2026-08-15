import 'package:zenify/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:zenify/components/zenify_divider_dot.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:zenify/utils/responsive.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:zenify/providers/app_providers.dart';
import 'package:zenify/router/app_router.dart';
import 'package:zenify/components/zenify_dialog.dart';
import 'package:zenify/components/zenify_button.dart';
import 'package:zenify/components/zenify_toast.dart';
import 'package:zenify/screens/playlist_detail_screen.dart';

final playlistsProvider = FutureProvider<List<dynamic>>((ref) async {
  final networkState = ref.watch(networkProvider);
  if (networkState.isOffline) {
    final serverAsyncValue = ref.read(activeServerProvider);
    if (!serverAsyncValue.hasValue || serverAsyncValue.value == null) {
      return [];
    }
    final db = ref.read(databaseProvider);
    final cachedPlaylists = await db.getPlaylists(serverAsyncValue.value!.id);
    
    List<dynamic> result = [];
    for (var p in cachedPlaylists) {
      try {
        result.add(jsonDecode(p.rawData));
      } catch (_) {}
    }
    return result;
  }

  final api = ref.watch(subsonicApiProvider);
  if (api == null) return [];
  return await api.getPlaylists();
});

class PlaylistsView extends ConsumerWidget {
  const PlaylistsView({super.key});

  Future<void> _showCreatePlaylistDialog(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final focusNode = FocusNode();
    final api = ref.read(subsonicApiProvider);

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final colorScheme = ShadTheme.of(context).colorScheme;
          return ZenifyDialog(
            icon: LucideIcons.listPlus,
            iconColor: colorScheme.primary,
            title: l10n.createPlaylist,
            description: l10n.createPlaylistDesc,
            content: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: focusNode.hasFocus ? colorScheme.background : colorScheme.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: focusNode.hasFocus ? colorScheme.primary : colorScheme.border,
                    width: 1.0,
                  ),
                ),
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  autofocus: true,
                  style: TextStyle(color: colorScheme.foreground, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: l10n.playlistName,
                    hintStyle: TextStyle(color: colorScheme.mutedForeground.withValues(alpha: 0.6), fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  onChanged: (_) => setDialogState(() {}),
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      Navigator.pop(dialogContext, true);
                    }
                  },
                ),
              ),
            ),
            actions: [
              ZenifyButton(
                variant: ZenifyButtonVariant.outline,
                onPressed: () => Navigator.pop(dialogContext, false),
                text: l10n.cancel,
              ),
              ZenifyButton(
                variant: ZenifyButtonVariant.primary,
                onPressed: controller.text.trim().isEmpty
                    ? null
                    : () => Navigator.pop(dialogContext, true),
                text: l10n.confirm,
              ),
            ],
          );
        },
      ),
    );

    if (result == true && controller.text.trim().isNotEmpty && api != null) {
      final name = controller.text.trim();
      final createdId = await api.createPlaylist(name);
      ref.invalidate(playlistsProvider);
      if (createdId != null) {
        ref.invalidate(playlistDetailProvider(createdId));
      }
      if (context.mounted) {
        if (createdId != null) {
          ZenifyToast.showSuccess(context, l10n.createPlaylistSuccess);
        } else {
          ZenifyToast.showError(context, l10n.createPlaylistFailed);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;
    final playlistsAsync = ref.watch(playlistsProvider);
    final networkState = ref.watch(networkProvider);

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: playlistsAsync.when(
        data: (playlists) {
          if (playlists.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.noPlaylistsCurrently, style: TextStyle(color: colorScheme.mutedForeground)),
                  if (!networkState.isOffline) ...[
                    const SizedBox(height: 16),
                    ShadButton(
                      onPressed: () => _showCreatePlaylistDialog(context, ref),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.plus, size: 16),
                          const SizedBox(width: 6),
                          Text(l10n.createPlaylist),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(playlistsProvider),
            child: ListView(
              padding: const EdgeInsets.only(top: 24, bottom: 128),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: getResponsiveMaxWidth(context)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Hero Banner
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: colorScheme.card,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: colorScheme.border, width: 1.0),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.navPlaylists,
                                      style: TextStyle(
                                        color: colorScheme.foreground,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      l10n.totalPlaylistsCount(playlists.length.toString()),
                                      style: TextStyle(color: colorScheme.mutedForeground, fontSize: 13),
                                    ),
                                  ],
                                ),
                                if (!networkState.isOffline)
                                  ShadButton(
                                    onPressed: () => _showCreatePlaylistDialog(context, ref),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(LucideIcons.plus, size: 16),
                                        const SizedBox(width: 6),
                                        Text(l10n.createPlaylist),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Playlist Group Container
                          Container(
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: colorScheme.card,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: colorScheme.border, width: 1.0),
                            ),
                            child: Column(
                              children: playlists.asMap().entries.map((entry) {
                                final index = entry.key;
                                final playlist = entry.value;
                                final title = playlist['name'] ?? 'Unknown Playlist';
                                final songCount = playlist['songCount'] ?? 0;
                                final duration = playlist['duration'] ?? 0;
                                final durationMinutes = duration ~/ 60;
                                final isLast = index == playlists.length - 1;

                                return Container(
                                  decoration: BoxDecoration(
                                    border: isLast
                                        ? null
                                        : Border(
                                            bottom: BorderSide(
                                              color: colorScheme.border.withValues(alpha: 0.5),
                                              width: 0.5,
                                            ),
                                          ),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.vertical(
                                      top: index == 0 ? const Radius.circular(12) : Radius.zero,
                                      bottom: isLast ? const Radius.circular(12) : Radius.zero,
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: ListTile(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(
                                          top: index == 0 ? const Radius.circular(12) : Radius.zero,
                                          bottom: isLast ? const Radius.circular(12) : Radius.zero,
                                        ),
                                      ),
                                      leading: Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: colorScheme.muted,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(LucideIcons.listMusic, size: 20, color: colorScheme.foreground),
                                      ),
                                      title: Text(
                                        title,
                                        style: TextStyle(
                                          color: colorScheme.foreground,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      subtitle: Row(
                                        children: [
                                          Text(
                                            l10n.songsCountOnly(songCount.toString()),
                                            style: TextStyle(color: colorScheme.mutedForeground, fontSize: 12),
                                          ),
                                          const ZenifyDividerDot(),
                                          Text(
                                            l10n.durationMinutesOnly(durationMinutes.toString()),
                                            style: TextStyle(color: colorScheme.mutedForeground, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                      trailing: Icon(
                                        LucideIcons.arrowUpRight,
                                        size: 16,
                                        color: colorScheme.mutedForeground,
                                      ),
                                      onTap: () {
                                        context.pushBranch('playlist/${playlist['id']}', extra: title);
                                      },
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text(l10n.loadFailedErr(err.toString()), style: TextStyle(color: colorScheme.destructive)),
        ),
      ),
    );
  }
}
