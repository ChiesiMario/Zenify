import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:device_info_plus/device_info_plus.dart';

class CustomTitleBar extends StatefulWidget {
  final bool isDark;
  const CustomTitleBar({super.key, this.isDark = false});

  @override
  State<CustomTitleBar> createState() => _CustomTitleBarState();
}

class _CustomTitleBarState extends State<CustomTitleBar> {
  bool _isWindows10 = false;

  @override
  void initState() {
    super.initState();
    _checkWindowsVersion();
  }

  Future<void> _checkWindowsVersion() async {
    if (Platform.isWindows) {
      try {
        final deviceInfo = DeviceInfoPlugin();
        final windowsInfo = await deviceInfo.windowsInfo;
        // Windows 11 build number starts at 22000.
        // Build numbers below 22000 are Windows 10 (or older, but practically Win10 here).
        if (windowsInfo.buildNumber < 22000) {
          if (mounted) {
            setState(() {
              _isWindows10 = true;
            });
          }
        }
      } catch (e) {
        debugPrint('Failed to get Windows info: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Avoid using Theme.of(context) here because ShadApp might not provide a Material Theme
    // at this high level in the widget tree.
    final isDark = widget.isDark;
    Widget caption = WindowCaption(
      brightness: isDark ? Brightness.dark : Brightness.light,
      backgroundColor: Colors.transparent,
      title: const SizedBox.shrink(),
    );

    if (_isWindows10) {
      caption = Stack(
        children: [
          caption,
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 0.8,
            child: Container(
              color: isDark ? const Color(0xFF09090B) : const Color(0xFF7D7D7D),
            ),
          ),
        ],
      );
    }

    // Wrap with DragToResizeArea to ensure the top edge can trigger window resizing.
    // Without this, the DragToMoveArea inside WindowCaption intercepts all pointer events
    // at the very top edge, preventing vertical/diagonal resizing.
    return DragToResizeArea(
      resizeEdgeSize: 4.0,
      enableResizeEdges: const [
        ResizeEdge.top,
        ResizeEdge.topLeft,
        ResizeEdge.topRight,
      ],
      child: caption,
    );
  }
}
