import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:zenify/providers/theme_provider.dart';
import 'package:zenify/services/image_service.dart';
import 'package:zenify/router/app_router.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:media_kit/media_kit.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:zenify/services/background_sync_service.dart';
import 'package:zenify/services/audio_cache_proxy.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:zenify/l10n/app_localizations.dart';
import 'package:zenify/providers/locale_provider.dart';
import 'package:zenify/components/zenify_scrollbar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  MediaKit.ensureInitialized();
  JustAudioMediaKit.ensureInitialized();
  
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );
  
  // 限制全域圖片快取最大為 50 MB 與 100 張圖片，防止記憶體暴增
  PaintingBinding.instance.imageCache.maximumSizeBytes = 50 * 1024 * 1024;
  PaintingBinding.instance.imageCache.maximumSize = 100;
  
  final prefs = await SharedPreferences.getInstance();
  await ImageService().init();

  // Initialize window_manager for desktop platforms
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(1024, 768),
      minimumSize: Size(400, 500),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
      title: 'Zenify',
    );
    
    await windowManager.setPreventClose(true);
    
    await trayManager.setIcon(
      Platform.isWindows ? 'assets/icon/app_icon.ico' : 'assets/icon/app_icon.png',
    );
    await trayManager.setToolTip('Zenify');
    Menu menu = Menu(
      items: [
        MenuItem(
          key: 'show_window',
          label: '顯示主介面',
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'exit_app',
          label: '退出程式',
        ),
      ],
    );
    await trayManager.setContextMenu(menu);

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      try {
        final double? x = prefs.getDouble('window_x');
        final double? y = prefs.getDouble('window_y');
        final double? width = prefs.getDouble('window_width');
        final double? height = prefs.getDouble('window_height');
        final bool? isMaximized = prefs.getBool('window_maximized');

        if (x != null && y != null && width != null && height != null) {
          Rect bounds = Rect.fromLTWH(x, y, width, height);
          
          
          bool isVisible = false;
          try {
            final displays = await screenRetriever.getAllDisplays();
            for (final display in displays) {
              final pos = display.visiblePosition ?? const Offset(0, 0);
              final size = display.visibleSize ?? const Size(0, 0);
              final displayRect = pos & size;
              final intersect = displayRect.intersect(bounds);
              if (intersect.width > 50 && intersect.height > 50) {
                isVisible = true;
                break;
              }
            }
          } catch (e) {
            
            isVisible = true; // Fallback
          }

          if (isVisible) {
            
            await windowManager.setBounds(bounds);
          } else {
            
            await windowManager.setSize(Size(width, height));
            await windowManager.center();
          }

          if (isMaximized == true) {
            
            await windowManager.maximize();
          }
        } else {
          
          await windowManager.setSize(const Size(1024, 768));
          await windowManager.center();
        }

        await windowManager.show();
        await windowManager.focus();
      } catch (e) {
        debugPrint('Window manager setup failed: $e');
      }
    });
  }

  await AudioCacheProxy().start();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const ZenifyApp(),
    ),
  );
}

class ZenifyApp extends ConsumerStatefulWidget {
  const ZenifyApp({super.key});

  @override
  ConsumerState<ZenifyApp> createState() => _ZenifyAppState();
}

class _ZenifyAppState extends ConsumerState<ZenifyApp> with WindowListener, TrayListener {
  Timer? _saveBoundsTimer;
  bool _isReadyToSave = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    trayManager.addListener(this);
    
    // 延遲 2 秒，等待視窗初始化完成後再允許儲存
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _isReadyToSave = true;
      }
    });
    
    // Start background sync
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(backgroundSyncServiceProvider).start();
    });
  }

  @override
  void dispose() {
    _saveBoundsTimer?.cancel();
    ref.read(backgroundSyncServiceProvider).stop();
    trayManager.removeListener(this);
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowClose() async {
    if (_isReadyToSave) {
      await _saveWindowBounds();
    }
    bool isPreventClose = await windowManager.isPreventClose();
    if (isPreventClose) {
      await windowManager.hide();
    }
  }

  @override
  void onTrayIconMouseDown() {
    windowManager.show();
    windowManager.focus();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (menuItem.key == 'show_window') {
      windowManager.show();
      windowManager.focus();
    } else if (menuItem.key == 'exit_app') {
      windowManager.destroy();
    }
  }

  Future<void> _saveWindowBounds() async {
    final bool isMaximized = await windowManager.isMaximized();
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('window_maximized', isMaximized);

    if (!isMaximized) {
      final bounds = await windowManager.getBounds();
      
      await prefs.setDouble('window_x', bounds.left);
      await prefs.setDouble('window_y', bounds.top);
      await prefs.setDouble('window_width', bounds.width);
      await prefs.setDouble('window_height', bounds.height);
    } else {
      
    }
  }

  void _debouncedSave() {
    if (!_isReadyToSave) return;
    
    _saveBoundsTimer?.cancel();
    _saveBoundsTimer = Timer(const Duration(milliseconds: 500), () {
      _saveWindowBounds();
    });
  }

  @override
  void onWindowMoved() {
    _debouncedSave();
  }

  @override
  void onWindowResized() {
    _debouncedSave();
  }

  @override
  void onWindowMaximize() {
    _debouncedSave();
  }

  @override
  void onWindowUnmaximize() {
    _debouncedSave();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final goRouter = ref.watch(routerProvider);

    ShadTextTheme buildCustomTextTheme() {
      final base = ShadTextTheme(family: 'Nunito');
      const fallbacks = ['NotoSansTC', 'NotoSansSC'];
      
      TextStyle withFallback(TextStyle style) {
        return style.copyWith(fontFamilyFallback: fallbacks);
      }

      return ShadTextTheme.custom(
        h1Large: withFallback(base.h1Large),
        h1: withFallback(base.h1),
        h2: withFallback(base.h2),
        h3: withFallback(base.h3),
        h4: withFallback(base.h4),
        p: withFallback(base.p),
        blockquote: withFallback(base.blockquote),
        table: withFallback(base.table),
        list: withFallback(base.list),
        lead: withFallback(base.lead),
        large: withFallback(base.large),
        small: withFallback(base.small),
        muted: withFallback(base.muted),
        family: 'Nunito',
      );
    }

    return ShadApp.router(
      title: 'Zenify',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ShadThemeData(
        brightness: Brightness.light,
        colorScheme: const ShadZincColorScheme.light(),
        textTheme: buildCustomTextTheme(),
        popoverTheme: ShadPopoverTheme(
          decoration: ShadDecoration(
            border: ShadBorder.all(
              radius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      darkTheme: ShadThemeData(
        brightness: Brightness.dark,
        colorScheme: const ShadZincColorScheme.dark(
          background: Color(0xFF0A0A0A), // 更深邃的背景
          card: Color(0xFF141414), // 略微提亮的卡片
          border: Color(0xFF262626), // 柔和的邊框
          muted: Color(0xFF1E1E1E), // 適合用於次要元素的背景
        ),
        textTheme: buildCustomTextTheme(),
        popoverTheme: ShadPopoverTheme(
          decoration: ShadDecoration(
            border: ShadBorder.all(
              radius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: goRouter,
      builder: (context, child) {
        return ScrollConfiguration(
          behavior: const ZenifyScrollBehavior(),
          child: Theme(
            data: Theme.of(context).copyWith(
              scrollbarTheme: const ScrollbarThemeData(
                crossAxisMargin: 3.0,
              ),
            ),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: DefaultTextStyle(
                style: const TextStyle(
                  fontFamily: 'NotoSansTC',
                  fontFamilyFallback: ['Nunito', 'NotoSansSC', 'Microsoft JhengHei UI', 'Microsoft YaHei UI', 'Segoe UI', 'sans-serif'],
                ),
                child: child!,
              ),
            ),
          ),
        );
      },
    );
  }
}
