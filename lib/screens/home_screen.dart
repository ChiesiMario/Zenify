import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:zenify/screens/search_screen.dart';
import 'package:zenify/screens/settings_screen.dart';
import 'package:zenify/views/album_view.dart';
import 'package:zenify/views/artists_view.dart';
import 'package:zenify/views/favorites_view.dart';
import 'package:zenify/components/mini_player.dart';
import 'package:zenify/screens/full_player_screen.dart';
import 'package:zenify/components/local_cover_image.dart';
import 'package:zenify/screens/album_detail_screen.dart';
import 'package:zenify/screens/artist_detail_screen.dart';

import 'package:flutter/foundation.dart';
import 'package:zenify/services/sync_service.dart';
import 'package:zenify/providers/app_providers.dart';
import 'package:zenify/providers/audio_provider.dart';
import 'package:zenify/providers/sort_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _TabObserver extends NavigatorObserver {
  final VoidCallback onNavigated;
  _TabObserver(this.onNavigated);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => onNavigated();
  
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => onNavigated();
  
  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) => onNavigated();
  
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) => onNavigated();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  bool _canPop = false;
  late final List<NavigatorObserver> _observers;
  final _popoverController = ShadPopoverController();
  final _sortPopoverController = ShadPopoverController();

  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  final List<Widget> _views = [
    const AlbumView(),
    const ArtistsView(),
    const FavoritesView(),
  ];

  String _currentSubTitle = '';

  bool _shouldShowSortButton() {
    if (_currentIndex == 0) {
      return !_canPop;
    } else if (_currentIndex == 1) {
      return !_canPop;
    } else if (_currentIndex == 2) {
      return _canPop && (
        _currentSubTitle == '歌曲' ||
        _currentSubTitle == '專輯' ||
        _currentSubTitle == '播放清單' ||
        _currentSubTitle == '已離線'
      );
    }
    return false;
  }

  void _updateCanPop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final navigator = _navigatorKeys[_currentIndex].currentState;
        final canPop = navigator?.canPop() ?? false;
        String title = '';
        if (canPop && navigator != null) {
          navigator.popUntil((route) {
            if (route.settings.name != null && route.settings.name!.isNotEmpty) {
              title = route.settings.name!;
            }
            return true;
          });
        }
        if (_canPop != canPop || _currentSubTitle != title) {
          setState(() {
            _canPop = canPop;
            _currentSubTitle = title;
          });
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _observers = List.generate(3, (index) => _TabObserver(_updateCanPop));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(syncProvider.notifier).startSync();
    });
  }

  @override
  void dispose() {
    _popoverController.dispose();
    _sortPopoverController.dispose();
    super.dispose();
  }

  Widget _buildTabNavigator(int index, Widget child) {
    return Navigator(
      key: _navigatorKeys[index],
      observers: [_observers[index]],
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => child,
          settings: settings,
        );
      },
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, ShadColorScheme colorScheme) {
    final isSelected = _currentIndex == index;
    
    return Expanded(
      child: _NavItemButton(
        isSelected: isSelected,
        icon: icon,
        label: label,
        colorScheme: colorScheme,
        onTap: () {
          if (_currentIndex == index) {
            _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
          } else {
            setState(() => _currentIndex = index);
            _updateCanPop();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;
    final syncState = ref.watch(syncProvider);
    final networkState = ref.watch(networkProvider);

    ref.listen<NavigationRequest?>(navigationRequestProvider, (previous, next) {
      if (next != null) {
        final navigator = _navigatorKeys[_currentIndex].currentState;
        if (navigator != null) {
          if (next.type == 'album') {
            navigator.push(MaterialPageRoute(
              settings: RouteSettings(name: next.name),
              builder: (_) => AlbumDetailScreen(albumId: next.id),
            ));
          } else if (next.type == 'artist') {
            navigator.push(MaterialPageRoute(
              settings: RouteSettings(name: next.name),
              builder: (_) => ArtistDetailScreen(artistId: next.id, artistName: next.name),
            ));
          }
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
                child: _canPop
                    ? Row(
                        key: ValueKey('back_btn_$_currentSubTitle'),
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Transform.translate(
                            offset: const Offset(-8.0, 0.0),
                            child: IconButton(
                              icon: Icon(LucideIcons.arrowLeft, color: colorScheme.foreground),
                              onPressed: () {
                                _navigatorKeys[_currentIndex].currentState?.maybePop();
                              },
                            ),
                          ),
                          if (_currentSubTitle.isNotEmpty)
                            Flexible(
                              child: Text(
                                _currentSubTitle,
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
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Zenify.', style: TextStyle(fontWeight: FontWeight.w900, color: colorScheme.foreground)),
                            if (networkState.isOffline) ...[
                              const SizedBox(width: 8),
                              Text('已離線。', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: colorScheme.destructive)),
                            ],
                          ],
                        ),
                      ),
              ),
              actions: [
                if (_shouldShowSortButton())
                  ShadPopover(
                    controller: _sortPopoverController,
                    popover: (context) => SortPopoverContent(
                      currentIndex: _currentIndex,
                      subTitle: _currentSubTitle,
                      onClose: () => _sortPopoverController.hide(),
                    ),
                    child: IconButton(
                      icon: Icon(LucideIcons.arrowUpDown, color: colorScheme.foreground, size: 20),
                      onPressed: () {
                        _sortPopoverController.toggle();
                      },
                    ),
                  ),
                IconButton(
                  icon: Icon(LucideIcons.search, color: networkState.isOffline ? colorScheme.mutedForeground.withOpacity(0.5) : colorScheme.foreground, size: 20),
                  onPressed: networkState.isOffline ? null : () {
                    _navigatorKeys[_currentIndex].currentState?.push(
                      MaterialPageRoute(
                        settings: const RouteSettings(name: '搜尋'),
                        builder: (context) => const SearchScreen(),
                      ),
                    );
                  },
                ),
                ShadPopover(
                  controller: _popoverController,
                  popover: (context) => const SyncPopoverContent(),
                  child: IconButton(
                    icon: Icon(LucideIcons.refreshCw, color: networkState.isOffline ? colorScheme.mutedForeground.withOpacity(0.5) : (syncState.isSyncing ? colorScheme.primary : colorScheme.mutedForeground), size: 20),
                    onPressed: networkState.isOffline ? null : () {
                      _popoverController.toggle();
                    },
                  ),
                ),
                if (kDebugMode)
                  IconButton(
                    icon: Icon(LucideIcons.bug, color: Colors.red.withOpacity(0.5), size: 20),
                    tooltip: 'Dispose AudioPlayer (for Shift+R)',
                    onPressed: () {
                      ref.read(audioProvider.notifier).disposePlayer();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('AudioPlayer disposed! Safe to Shift+R now.')),
                      );
                    },
                  ),
                IconButton(
                  icon: Icon(LucideIcons.settings, color: colorScheme.mutedForeground, size: 20),
                  onPressed: () {
                    _navigatorKeys[_currentIndex].currentState?.push(
                      MaterialPageRoute(
                        settings: const RouteSettings(name: '設定'),
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
      body: PopScope(
        canPop: false,
        onPopInvoked: (didPop) async {
          if (didPop) return;
          
          final navigator = _navigatorKeys[_currentIndex].currentState;
          bool handled = false;
          if (navigator != null) {
            handled = await navigator.maybePop();
          }
          
          if (!handled) {
            if (_currentIndex != 0) {
              setState(() {
                _currentIndex = 0;
              });
            } else {
              SystemNavigator.pop();
            }
          }
        },
        child: IndexedStack(
          index: _currentIndex,
          children: _views.asMap().entries.map((entry) {
            return _buildTabNavigator(entry.key, entry.value);
          }).toList(),
        ),
      ),
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
                      color: Colors.black.withOpacity(0.18),
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
                        color: colorScheme.background.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.foreground.withOpacity(0.12),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildNavItem(0, LucideIcons.disc, '專輯', colorScheme),
                          _buildNavItem(1, LucideIcons.users, '藝術家', colorScheme),
                          _buildNavItem(2, LucideIcons.heart, '最愛', colorScheme),
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
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const FullPlayerScreen(),
                  );
                },
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
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
                          color: colorScheme.background.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colorScheme.foreground.withOpacity(0.12),
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
          Text('本地資料統計', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.popoverForeground)),
          const SizedBox(height: 16),
          
          statsAsync.when(
            data: (stats) {
              return Column(
                children: [
                  _buildStatRow('專輯數量', '${stats['albums']}', colorScheme),
                  const SizedBox(height: 8),
                  _buildStatRow('藝術家數量', '${stats['artists']}', colorScheme),
                  const SizedBox(height: 8),
                  _buildStatRow('已下載封面', '${stats['covers']}', colorScheme),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Text('讀取失敗', style: TextStyle(color: colorScheme.destructive)),
          ),

          const SizedBox(height: 16),
          Divider(color: colorScheme.border),
          const SizedBox(height: 16),

          if (syncState.isSyncing) ...[
            Text('同步中...', style: TextStyle(color: colorScheme.popoverForeground, fontWeight: FontWeight.w500)),
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
                    ref.read(syncProvider.notifier).startSync();
                  },
              child: const Text('立即同步'),
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
  final VoidCallback onClose;

  const SortPopoverContent({
    super.key, 
    required this.currentIndex, 
    required this.subTitle, 
    required this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;

    if (currentIndex == 0 || (currentIndex == 2 && subTitle == '專輯')) {
      final currentSort = ref.watch(albumSortProvider);
      return _buildMenu<AlbumSortOption>(
        context, ref, colorScheme, currentSort,
        [
          (AlbumSortOption.defaultOrder, '預設排序'),
          (AlbumSortOption.nameAsc, '名稱 (A-Z)'),
          (AlbumSortOption.nameDesc, '名稱 (Z-A)'),
          (AlbumSortOption.yearDesc, '年份 (新到舊)'),
          (AlbumSortOption.yearAsc, '年份 (舊到新)'),
          (AlbumSortOption.random, '隨機排列'),
        ]
      );
    } else if (currentIndex == 1) {
      final currentSort = ref.watch(artistSortProvider);
      return _buildMenu<ArtistSortOption>(
        context, ref, colorScheme, currentSort,
        [
          (ArtistSortOption.defaultOrder, '預設排序'),
          (ArtistSortOption.nameAsc, '名稱 (A-Z)'),
          (ArtistSortOption.nameDesc, '名稱 (Z-A)'),
          (ArtistSortOption.albumCountDesc, '專輯數量 (多到少)'),
          (ArtistSortOption.random, '隨機排列'),
        ]
      );
    } else if (currentIndex == 2) {
      final currentSort = ref.watch(albumSortProvider);
      return _buildMenu<AlbumSortOption>(
        context, ref, colorScheme, currentSort,
        [
          (AlbumSortOption.defaultOrder, '預設排序'),
          (AlbumSortOption.nameAsc, '名稱 (A-Z)'),
          (AlbumSortOption.nameDesc, '名稱 (Z-A)'),
          (AlbumSortOption.random, '隨機排列'),
        ]
      );
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
          children: options.map((option) => _SortOptionItem<T>(
            label: option.$2,
            value: option.$1,
            currentValue: currentValue,
            colorScheme: colorScheme,
            onTap: () {
              if (option.$1 is AlbumSortOption) {
                ref.read(albumSortProvider.notifier).setSort(option.$1 as AlbumSortOption);
              } else if (option.$1 is ArtistSortOption) {
                ref.read(artistSortProvider.notifier).setSort(option.$1 as ArtistSortOption);
              }
              onClose();
            },
          )).toList(),
        ),
      ),
    );
  }
}

class _SortOptionItem<T> extends StatefulWidget {
  final String label;
  final T value;
  final T currentValue;
  final ShadColorScheme colorScheme;
  final VoidCallback onTap;

  const _SortOptionItem({
    required this.label,
    required this.value,
    required this.currentValue,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  State<_SortOptionItem<T>> createState() => _SortOptionItemState<T>();
}

class _SortOptionItemState<T> extends State<_SortOptionItem<T>> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.value == widget.currentValue;

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
                ? widget.colorScheme.foreground.withOpacity(0.06)
                : (isSelected ? widget.colorScheme.muted.withOpacity(0.3) : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                child: isSelected
                    ? Icon(
                        LucideIcons.check,
                        size: 14,
                        color: widget.colorScheme.foreground,
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  color: isSelected ? widget.colorScheme.foreground : widget.colorScheme.mutedForeground,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ],
          ),
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
                        id: currentSong['coverArt'],
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
                    color: (audioState.isPlaying ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withOpacity(0.4),
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

  const _NavItemButton({
    required this.isSelected,
    required this.icon,
    required this.label,
    required this.colorScheme,
    required this.onTap,
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
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
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
    );
  }
}
