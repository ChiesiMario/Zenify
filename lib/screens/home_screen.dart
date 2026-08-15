import 'dart:ui';
import 'package:zenify/models/server.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:zenify/screens/full_player_screen.dart';
import 'package:zenify/components/local_cover_image.dart';
import 'package:zenify/screens/playlist_detail_screen.dart';
import 'package:zenify/views/playlists_view.dart';
import 'package:zenify/components/zenify_toast.dart';
import 'package:zenify/components/zenify_popover.dart';


import 'package:zenify/services/sync_service.dart';
import 'package:zenify/providers/app_providers.dart';
import 'package:zenify/providers/audio_provider.dart';
import 'package:zenify/providers/sort_providers.dart';
import 'package:zenify/l10n/app_localizations.dart';


import 'package:go_router/go_router.dart';
import 'package:zenify/router/app_router.dart';
import 'package:zenify/components/zenify_dialog.dart';
import 'package:zenify/components/zenify_button.dart';
import 'package:zenify/providers/download_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _popoverController = ShadPopoverController();
  final _sortPopoverController = ShadPopoverController();

  bool _isTestingConnection = false;

  bool _shouldShowSortButton(bool canPop, String currentSubTitle, String location) {
    if (location.contains('/playlist/')) return true;
    final currentIndex = widget.navigationShell.currentIndex;
    if (currentIndex == 0 || currentIndex == 1) {
      return !canPop;
    } else if (currentIndex == 2) {
      return canPop && (
        currentSubTitle == AppLocalizations.of(context)!.songs ||
        currentSubTitle == AppLocalizations.of(context)!.navAlbums ||
        currentSubTitle == AppLocalizations.of(context)!.offlineStatus
      );
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(syncProvider.notifier).startSync(AppLocalizations.of(context)!);
    });
  }

  @override
  void dispose() {
    _popoverController.dispose();
    _sortPopoverController.dispose();
    super.dispose();
  }


  Widget _buildNavItem(int index, IconData icon, String label, ShadColorScheme colorScheme, {bool isDisabled = false}) {
    final isSelected = widget.navigationShell.currentIndex == index;
    
    return Expanded(
      child: _NavItemButton(
        isSelected: isSelected,
        isDisabled: isDisabled,
        icon: icon,
        label: label,
        colorScheme: colorScheme,
        onTap: () {
          widget.navigationShell.goBranch(
            index,
            initialLocation: index == widget.navigationShell.currentIndex,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;
    final syncState = ref.watch(syncProvider);


    ref.listen<AsyncValue<Server?>>(activeServerProvider, (previous, next) {
      final prevId = previous?.value?.id;
      final nextId = next.value?.id;
      if (prevId != nextId && nextId != null) {
        ref.read(syncProvider.notifier).startSync(l10n, force: true);
      }
    });
    final networkState = ref.watch(networkProvider);

    final routerState = GoRouterState.of(context);
    final location = routerState.uri.path;
    final isRoot = location == '/albums' || location == '/artists' || location == '/favorites' || location == '/settings' || location == '/servers';
    final canPop = !isRoot;

    final downloadsAsync = ref.watch(downloadedTracksProvider);
    final hasDownloads = downloadsAsync.maybeWhen(
      data: (tracks) => tracks.any((t) => t.isManualDownload),
      orElse: () => false,
    );
    
    String currentSubTitle = '';
    if (location.endsWith('/search')) {
      currentSubTitle = l10n.navSearch;
    } else if (routerState.extra is String) {
      currentSubTitle = routerState.extra as String;
    }

    ref.listen<NavigationRequest?>(navigationRequestProvider, (previous, next) {
      if (next != null) {
        if (next.type == 'album') {
          context.pushBranch('album/${next.id}');
        } else if (next.type == 'artist') {
          context.pushBranch('artist/${next.id}', extra: next.name);
        }
        Future.microtask(() => ref.read(navigationRequestProvider.notifier).state = null);
      }
    });

    return Scaffold(
      extendBody: true,
      backgroundColor: colorScheme.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
              backgroundColor: colorScheme.background,
              surfaceTintColor: Colors.transparent,
              scrolledUnderElevation: 0,
              elevation: 0,
              titleSpacing: 16,
              automaticallyImplyLeading: false,
              title: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
                  return Stack(
                    alignment: Alignment.centerLeft,
                    children: <Widget>[
                      ...previousChildren,
                      if (currentChild != null) currentChild,
                    ],
                  );
                },
                transitionBuilder: (child, animation) {
                  final isBackBtn = child.key == const ValueKey('back_btn');
                  
                  final slideTween = isBackBtn
                      ? Tween<Offset>(begin: const Offset(0.15, 0.0), end: Offset.zero)
                      : Tween<Offset>(begin: const Offset(-0.15, 0.0), end: Offset.zero);

                  return FadeTransition(
                    opacity: CurvedAnimation(
                      parent: animation,
                      curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
                    ),
                    child: SlideTransition(
                      position: slideTween.animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutQuint, // very smooth deceleration
                      )),
                      child: child,
                    ),
                  );
                },
                child: canPop
                    ? Row(
                        key: ValueKey('back_btn_$currentSubTitle'),
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Transform.translate(
                            offset: const Offset(-8.0, 0.0),
                            child: IconButton(
                              icon: Icon(LucideIcons.arrowLeft, color: colorScheme.foreground),
                              onPressed: () {
                                context.pop();
                              },
                            ),
                          ),
                          if (currentSubTitle.isNotEmpty)
                            Flexible(
                              child: Text(
                                currentSubTitle,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: colorScheme.foreground,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      )
                    : Container(
                        key: const ValueKey('title'),
                        child: MouseRegion(
                          cursor: networkState.isOffline && !_isTestingConnection 
                              ? SystemMouseCursors.click 
                              : SystemMouseCursors.basic,
                          child: GestureDetector(
                            onTap: networkState.isOffline && !_isTestingConnection ? () async {
                              setState(() {
                                _isTestingConnection = true;
                              });
                              
                              final success = await ref.read(networkProvider.notifier).testConnectionManual();
                              
                              if (context.mounted) {
                                setState(() {
                                  _isTestingConnection = false;
                                });
                                if (!success) {
                                  ZenifyToast.showError(context, l10n.homeTestConnectionFailed);
                                } else {
                                  ZenifyToast.showSuccess(context, l10n.homeTestConnectionSuccess);
                                }
                              }
                            } : null,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_isTestingConnection) ...[
                                  SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: colorScheme.foreground,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Text(
                                  networkState.isOffline 
                                      ? (_isTestingConnection ? l10n.homeConnectionTesting : l10n.homeOffline) 
                                      : 'Zenify.',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: colorScheme.foreground,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
              ),
              actions: [
                if (_shouldShowSortButton(canPop, currentSubTitle, location)) ...[
                  ZenifyPopover(
                    builder: (context, close) => SortPopoverContent(
                      currentIndex: widget.navigationShell.currentIndex,
                      subTitle: currentSubTitle,
                      location: location,
                      onClose: close,
                    ),
                    child: IconButton(
                      icon: Icon(LucideIcons.arrowUpDown, color: colorScheme.mutedForeground, size: 20),
                      onPressed: null,
                    ),
                  ),
                  if (currentSubTitle == l10n.offlineStatus)
                    IconButton(
                      icon: Icon(
                        ref.watch(showCachedDownloadsProvider) ? LucideIcons.hardDriveDownload : LucideIcons.download, 
                        color: colorScheme.mutedForeground, 
                        size: 20
                      ),
                      onPressed: () {
                        ref.read(showCachedDownloadsProvider.notifier).toggle();
                        final isCached = ref.read(showCachedDownloadsProvider);
                        if (isCached) {
                          ZenifyToast.showSuccess(context, '顯示所有已離線和已快取的歌曲');
                        } else {
                          ZenifyToast.showSuccess(context, '僅顯示所有已離線歌曲');
                        }
                      },
                    ),
                  if (currentSubTitle == l10n.offlineStatus)
                    IconButton(
                      icon: Icon(LucideIcons.trash2, color: hasDownloads ? colorScheme.mutedForeground : colorScheme.mutedForeground.withValues(alpha: 0.3), size: 20),
                      onPressed: !hasDownloads ? null : () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => ZenifyDialog(
                            icon: LucideIcons.alertTriangle,
                            iconColor: theme.colorScheme.destructive,
                            title: l10n.deleteAll,
                            description: l10n.deleteAllConfirmDesc,
                            actions: [
                              ZenifyButton(
                                variant: ZenifyButtonVariant.outline,
                                onPressed: () => Navigator.pop(context, false),
                                text: l10n.cancel,
                              ),
                              ZenifyButton(
                                variant: ZenifyButtonVariant.destructive,
                                onPressed: () => Navigator.pop(context, true),
                                text: l10n.confirm,
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          final serverId = ref.read(activeServerProvider).value?.id;
                          if (serverId != null) {
                            await ref.read(downloadServiceProvider).deleteAllManualDownloads(serverId);
                            ref.invalidate(downloadedTracksProvider);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(l10n.deletedAllOfflineMusic, style: const TextStyle(color: Colors.white)),
                                  backgroundColor: theme.colorScheme.primary,
                                ),
                              );
                            }
                          }
                        }
                      },
                    ),
                  if (!location.contains('/playlist/'))
                    Container(
                      width: 1,
                      height: 20,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      color: colorScheme.border,
                    ),
                ],
                if (location.contains('/playlist/')) ...[
                  IconButton(
                    icon: Icon(LucideIcons.trash2, color: colorScheme.mutedForeground, size: 20),
                    tooltip: l10n.deletePlaylist,
                    onPressed: () async {
                      final playlistId = location.split('/playlist/').last.split('?').first;
                      final playlistName = currentSubTitle.isNotEmpty ? currentSubTitle : l10n.navPlaylists;
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => ZenifyDialog(
                          icon: LucideIcons.alertTriangle,
                          iconColor: theme.colorScheme.destructive,
                          title: l10n.deletePlaylist,
                          description: l10n.deletePlaylistConfirm(playlistName),
                          actions: [
                            ZenifyButton(
                              variant: ZenifyButtonVariant.outline,
                              onPressed: () => Navigator.pop(context, false),
                              text: l10n.cancel,
                            ),
                            ZenifyButton(
                              variant: ZenifyButtonVariant.destructive,
                              onPressed: () => Navigator.pop(context, true),
                              text: l10n.confirm,
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        final api = ref.read(subsonicApiProvider);
                        final server = ref.read(activeServerProvider).value;
                        final db = ref.read(databaseProvider);
                        if (api != null) {
                          await api.deletePlaylist(playlistId);
                        }
                        if (server != null) {
                          await db.deletePlaylist(server.id, playlistId);
                        }
                        ref.invalidate(playlistsProvider);
                        ref.invalidate(playlistDetailProvider(playlistId));
                        if (context.mounted) {
                          context.pop();
                          ZenifyToast.showSuccess(context, l10n.playlistDeleted);
                        }
                      }
                    },
                  ),
                  Container(
                    width: 1,
                    height: 20,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    color: colorScheme.border,
                  ),
                ],
                IconButton(
                  icon: Icon(LucideIcons.search, color: networkState.isOffline ? colorScheme.mutedForeground.withValues(alpha: 0.5) : colorScheme.mutedForeground, size: 20),
                  onPressed: networkState.isOffline ? null : () {
                    context.pushBranch('search');
                  },
                ),
                ShadPopover(
                  controller: _popoverController,
                  anchor: const ShadAnchor(
                    childAlignment: Alignment.topRight,
                    overlayAlignment: Alignment.bottomRight,
                    offset: Offset(0, 8),
                  ),
                  popover: (context) => const SyncPopoverContent(),
                  child: IconButton(
                    icon: Icon(LucideIcons.refreshCw, color: networkState.isOffline ? colorScheme.mutedForeground.withValues(alpha: 0.5) : (syncState.isSyncing ? colorScheme.primary : colorScheme.mutedForeground), size: 20),
                    onPressed: networkState.isOffline ? null : () {
                      _popoverController.toggle();
                    },
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
      body: widget.navigationShell,
      bottomNavigationBar: SafeArea(
        bottom: true,
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Left navigation card (Glassmorphism)
              Container(
                width: 250,
                height: 72,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      decoration: BoxDecoration(
                        color: colorScheme.background.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.foreground.withValues(alpha: 0.12),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildNavItem(0, LucideIcons.disc, l10n.navAlbums, colorScheme),
                          _buildNavItem(1, LucideIcons.users, l10n.navArtists, colorScheme, isDisabled: networkState.isOffline),
                          _buildNavItem(2, LucideIcons.heart, l10n.navFavorites, colorScheme),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Right player status card (Glassmorphism)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  FullPlayerScreen.show(context);
                },
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Container(
                        decoration: BoxDecoration(
                          color: colorScheme.background.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colorScheme.foreground.withValues(alpha: 0.12),
                            width: 1.0,
                          ),
                        ),
                        child: const Center(
                          child: NowPlayingTabIcon(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SyncPopoverContent extends ConsumerWidget {
  const SyncPopoverContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;
    final syncState = ref.watch(syncProvider);
    final statsAsync = ref.watch(serverStatsProvider);

    return Container(
      width: 300,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.homeStatsTitle, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.popoverForeground)),
          const SizedBox(height: 16),
          
          statsAsync.when(
            data: (stats) {
              return Column(
                children: [
                  _buildStatRow(l10n.homeStatsAlbums, '${stats['albums']}', colorScheme),
                  const SizedBox(height: 8),
                  _buildStatRow(l10n.homeStatsArtists, '${stats['artists']}', colorScheme),
                  const SizedBox(height: 8),
                  _buildStatRow(l10n.homeStatsCovers, '${stats['covers']}', colorScheme),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Text('Error', style: TextStyle(color: colorScheme.destructive)),
          ),

          const SizedBox(height: 16),
          Divider(color: colorScheme.border),
          const SizedBox(height: 16),

          if (syncState.isSyncing) ...[
            Text(l10n.homeSyncing, style: TextStyle(color: colorScheme.popoverForeground, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: syncState.progress, backgroundColor: colorScheme.muted, color: colorScheme.primary),
            const SizedBox(height: 4),
            Text(syncState.message, style: TextStyle(fontSize: 12, color: colorScheme.mutedForeground)),
            const SizedBox(height: 16),
          ],

          SizedBox(
            width: double.infinity,
            child: ShadButton(
              onPressed: syncState.isSyncing 
                ? null 
                : () {
                    ref.read(syncProvider.notifier).startSync(l10n);
                  },
              child: Text(l10n.homeSyncNow),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, ShadColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: colorScheme.mutedForeground)),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.popoverForeground)),
      ],
    );
  }
}

class SortPopoverContent extends ConsumerWidget {
  final int currentIndex;
  final String subTitle;
  final String location;
  final VoidCallback onClose;

  const SortPopoverContent({
    super.key, 
    required this.currentIndex, 
    required this.subTitle, 
    required this.location,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;

    if (location.contains('/playlist/')) {
      final currentSort = ref.watch(songSortProvider);
      return _buildMenu<SongSortOption>(
        context, ref, colorScheme, currentSort,
        [
          (SongSortOption.defaultOrder, l10n.homeSortDefault),
          (SongSortOption.nameAsc, l10n.homeSortNameAsc),
          (SongSortOption.nameDesc, l10n.homeSortNameDesc),
          (SongSortOption.random, l10n.homeSortRandom),
        ]
      );
    }

    if (currentIndex == 0 || (currentIndex == 2 && subTitle == AppLocalizations.of(context)!.navAlbums)) {
      final currentSort = ref.watch(albumSortProvider);
      return _buildMenu<AlbumSortOption>(
        context, ref, colorScheme, currentSort,
        [
          (AlbumSortOption.defaultOrder, l10n.homeSortDefault),
          (AlbumSortOption.nameAsc, l10n.homeSortNameAsc),
          (AlbumSortOption.nameDesc, l10n.homeSortNameDesc),
          (AlbumSortOption.yearDesc, l10n.homeSortYearDesc),
          (AlbumSortOption.yearAsc, l10n.homeSortYearAsc),
          (AlbumSortOption.random, l10n.homeSortRandom),
        ]
      );
    } else if (currentIndex == 1) {
      final currentSort = ref.watch(artistSortProvider);
      return _buildMenu<ArtistSortOption>(
        context, ref, colorScheme, currentSort,
        [
          (ArtistSortOption.defaultOrder, l10n.homeSortDefault),
          (ArtistSortOption.nameAsc, l10n.homeSortNameAsc),
          (ArtistSortOption.nameDesc, l10n.homeSortNameDesc),
          (ArtistSortOption.albumCountDesc, l10n.homeSortAlbumCountDesc),
          (ArtistSortOption.random, l10n.homeSortRandom),
        ]
      );
    } else if (currentIndex == 2) {
      if (subTitle == l10n.offlineStatus) {
        final tabIndex = ref.watch(downloadsTabProvider);
        if (tabIndex == 0) {
          final currentSort = ref.watch(albumSortProvider);
          return _buildMenu<AlbumSortOption>(
            context, ref, colorScheme, currentSort,
            [
              (AlbumSortOption.defaultOrder, l10n.homeSortDefault),
              (AlbumSortOption.nameAsc, l10n.homeSortNameAsc),
              (AlbumSortOption.nameDesc, l10n.homeSortNameDesc),
              (AlbumSortOption.random, l10n.homeSortRandom),
            ]
          );
        } else {
          final currentSort = ref.watch(songSortProvider);
          return _buildMenu<SongSortOption>(
            context, ref, colorScheme, currentSort,
            [
              (SongSortOption.defaultOrder, l10n.homeSortRecentDownload),
              (SongSortOption.nameAsc, l10n.homeSortNameAsc),
              (SongSortOption.nameDesc, l10n.homeSortNameDesc),
              (SongSortOption.random, l10n.homeSortRandom),
            ]
          );
        }
      } else {
        // Other favorites subpages, assuming albums by default
        final currentSort = ref.watch(albumSortProvider);
        return _buildMenu<AlbumSortOption>(
          context, ref, colorScheme, currentSort,
          [
            (AlbumSortOption.defaultOrder, l10n.homeSortDefault),
            (AlbumSortOption.nameAsc, l10n.homeSortNameAsc),
            (AlbumSortOption.nameDesc, l10n.homeSortNameDesc),
            (AlbumSortOption.random, l10n.homeSortRandom),
          ]
        );
      }
    }

    return const SizedBox.shrink();
  }

  Widget _buildMenu<T>(
    BuildContext context, 
    WidgetRef ref, 
    ShadColorScheme colorScheme, 
    T currentValue,
    List<(T, String)> options,
  ) {
    return IntrinsicWidth(
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: options.map((option) => ZenifyPopoverItem(
            label: option.$2,
            isSelected: option.$1 == currentValue,
            colorScheme: colorScheme,
            icon: option.$1 == currentValue ? LucideIcons.check : null,
            onTap: () {
              if (option.$1 is AlbumSortOption) {
                ref.read(albumSortProvider.notifier).setSort(option.$1 as AlbumSortOption);
              } else if (option.$1 is ArtistSortOption) {
                ref.read(artistSortProvider.notifier).setSort(option.$1 as ArtistSortOption);
              } else if (option.$1 is SongSortOption) {
                ref.read(songSortProvider.notifier).setSort(option.$1 as SongSortOption);
              }
              onClose();
            },
          )).toList(),
        ),
      ),
    );
  }
}

class NowPlayingTabIcon extends ConsumerStatefulWidget {
  const NowPlayingTabIcon({super.key});

  @override
  ConsumerState<NowPlayingTabIcon> createState() => _NowPlayingTabIconState();
}

class _NowPlayingTabIconState extends ConsumerState<NowPlayingTabIcon> with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audioState = ref.watch(audioProvider);
    final currentSong = audioState.currentSong;
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;
    
    if (audioState.isPlaying) {
      if (!_rotationController.isAnimating) {
        _rotationController.repeat();
      }
    } else {
      if (_rotationController.isAnimating) {
        _rotationController.stop();
      }
    }

    if (currentSong == null) {
      return Icon(LucideIcons.playCircle, color: colorScheme.mutedForeground, size: 28);
    }
    
    final api = ref.watch(subsonicApiProvider);
    final server = ref.watch(activeServerProvider).value;
    
    final coverUrl = api != null && currentSong['coverArt'] != null
        ? api.getCoverArtUrl(currentSong['coverArt'])
        : null;

    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: RotationTransition(
              turns: _rotationController,
              child: ClipOval(
                child: coverUrl == null
                    ? Container(color: colorScheme.muted, child: Icon(LucideIcons.music, size: 24, color: colorScheme.mutedForeground))
                    : LocalCoverImage(
                        id: currentSong['albumId']?.toString() ?? currentSong['coverArt'],
                        serverId: server?.id ?? 0,
                        fallbackUrl: coverUrl,
                        isThumb: true,
                      ),
              ),
            ),
          ),
          // 狀態指示燈 (固定在右上角，不隨專輯旋轉，具備霓虹光暈)
          Positioned(
            top: -8,
            right: -8,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: audioState.isPlaying ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (audioState.isPlaying ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withValues(alpha: 0.4),
                    blurRadius: 2,
                    spreadRadius: 0,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItemButton extends StatefulWidget {
  final bool isSelected;
  final IconData icon;
  final String label;
  final ShadColorScheme colorScheme;
  final VoidCallback onTap;
  final bool isDisabled;

  const _NavItemButton({
    required this.isSelected,
    required this.icon,
    required this.label,
    required this.colorScheme,
    required this.onTap,
    this.isDisabled = false,
  });

  @override
  State<_NavItemButton> createState() => _NavItemButtonState();
}

class _NavItemButtonState extends State<_NavItemButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isHighlit = widget.isSelected || _isHovered;
    final color = isHighlit ? widget.colorScheme.foreground : widget.colorScheme.mutedForeground;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.isDisabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) {
          if (!widget.isDisabled) setState(() => _isPressed = true);
        },
        onTapUp: (_) {
          if (widget.isDisabled) {
            ZenifyToast.showError(context, AppLocalizations.of(context)!.serverOffline);
            return;
          }
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: Opacity(
          opacity: widget.isDisabled ? 0.4 : 1.0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(
            0,
            _isPressed ? 0.5 : (_isHovered ? -1.5 : 0.0),
            0,
          ),
          child: AnimatedScale(
            scale: _isPressed ? 0.95 : (_isHovered ? 1.04 : 1.0),
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            child: AnimatedOpacity(
              opacity: _isPressed ? 0.7 : (isHighlit ? 1.0 : 0.65),
              duration: const Duration(milliseconds: 180),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(widget.icon, color: color, size: 22),
                  const SizedBox(height: 4),
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: widget.isSelected ? FontWeight.bold : (_isHovered ? FontWeight.w600 : FontWeight.normal),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        ),
      ),
    );
  }
}
