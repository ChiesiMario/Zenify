import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:zenify/providers/theme_provider.dart';
import 'package:zenify/screens/home_screen.dart';
import 'package:zenify/components/custom_title_bar.dart';
import 'package:zenify/services/image_service.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:media_kit/media_kit.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:zenify/services/background_sync_service.dart';

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
    Menu menu = Menu(
      items: [
        MenuItem(
          key: 'show_window',
          label: '顯示主畫面',
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

        if (x != null && y != null && width != null && height != null) {
          await windowManager.setBounds(Rect.fromLTWH(x, y, width, height));
        } else {
          await windowManager.setSize(const Size(1024, 768));
          await windowManager.center();
        }

        await windowManager.show();
        await windowManager.focus();
      } catch (e) {
        print('Window manager setup failed: $e');
      }
    });
  }

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
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    trayManager.addListener(this);
    
    // Start background sync
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(backgroundSyncServiceProvider).start();
    });
  }

  @override
  void dispose() {
    ref.read(backgroundSyncServiceProvider).stop();
    trayManager.removeListener(this);
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowClose() async {
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
    final bounds = await windowManager.getBounds();
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setDouble('window_x', bounds.left);
    await prefs.setDouble('window_y', bounds.top);
    await prefs.setDouble('window_width', bounds.width);
    await prefs.setDouble('window_height', bounds.height);
  }

  @override
  void onWindowMoved() {
    _saveWindowBounds();
  }

  @override
  void onWindowResized() {
    _saveWindowBounds();
    if (kDebugMode) {
      windowManager.getBounds().then((bounds) {
        print('Window resized -> Width: ${bounds.width}, Height: ${bounds.height}');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return ShadApp(
      title: 'Zenify',
      themeMode: themeMode,
      materialThemeBuilder: (context, theme) => theme.copyWith(
        textTheme: theme.textTheme.apply(
          fontFamily: 'NotoSansTC',
          fontFamilyFallback: const ['Nunito', 'NotoSansSC', 'Microsoft JhengHei UI', 'Microsoft YaHei UI', 'Segoe UI', 'sans-serif'],
        ),
      ),
      theme: ShadThemeData(
        brightness: Brightness.light,
        colorScheme: const ShadZincColorScheme.light(),
        textTheme: ShadTextTheme(
          family: 'NotoSansTC',
        ),
      ),
      darkTheme: ShadThemeData(
        brightness: Brightness.dark,
        colorScheme: const ShadZincColorScheme.dark(),
        textTheme: ShadTextTheme(
          family: 'NotoSansTC',
        ),
      ),
      builder: (context, child) {
        final isDark = themeMode == ThemeMode.dark ||
            (themeMode == ThemeMode.system &&
                View.of(context).platformDispatcher.platformBrightness == Brightness.dark);
        
        return Directionality(
          textDirection: TextDirection.ltr,
          child: DefaultTextStyle(
            style: const TextStyle(
              fontFamily: 'NotoSansTC',
              fontFamilyFallback: ['Nunito', 'NotoSansSC', 'Microsoft JhengHei UI', 'Microsoft YaHei UI', 'Segoe UI', 'sans-serif'],
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 32.0),
                  child: child!,
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
        ),
      );
    },
      home: const HomeScreen(),
    );
  }
}
