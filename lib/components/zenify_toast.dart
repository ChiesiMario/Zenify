import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class ZenifyToast {
  static OverlayEntry? _currentEntry;

  /// 顯示共用的玻璃質感 Toast
  static void show({
    required BuildContext context,
    required String message,
    bool isError = false,
  }) {
    final colorScheme = ShadTheme.of(context).colorScheme;
    final overlayState = Overlay.of(context, rootOverlay: true);
    
    // 如果畫面上已經有 Toast，立即將它移除
    if (_currentEntry?.mounted ?? false) {
      _currentEntry?.remove();
    }
    _currentEntry = null;

    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) {
        return _ZenifyToastWidget(
          message: message,
          isError: isError,
          colorScheme: colorScheme,
          onDismiss: () {
            if (_currentEntry == overlayEntry) {
              if (overlayEntry.mounted) {
                overlayEntry.remove();
              }
              _currentEntry = null;
            }
          },
        );
      },
    );

    _currentEntry = overlayEntry;
    overlayState.insert(overlayEntry);
  }

  /// 顯示錯誤（Destructive）樣式的 Toast
  static void showError(BuildContext context, String message) {
    show(context: context, message: message, isError: true);
  }

  /// 顯示成功（Primary）樣式的 Toast
  static void showSuccess(BuildContext context, String message) {
    show(context: context, message: message, isError: false);
  }
}

class _ZenifyToastWidget extends StatefulWidget {
  final String message;
  final bool isError;
  final ShadColorScheme colorScheme;
  final VoidCallback onDismiss;

  const _ZenifyToastWidget({
    required this.message,
    required this.isError,
    required this.colorScheme,
    required this.onDismiss,
  });

  @override
  State<_ZenifyToastWidget> createState() => _ZenifyToastWidgetState();
}

class _ZenifyToastWidgetState extends State<_ZenifyToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _offset = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    
    _controller.forward();
    
    _timer = Timer(const Duration(seconds: 3), _dismiss);
  }

  void _dismiss() {
    if (mounted) {
      _controller.reverse().then((_) {
        widget.onDismiss();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = widget.colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    Color bgColor;
    if (widget.isError) {
      bgColor = colorScheme.foreground;
    } else {
      bgColor = isDarkMode ? const Color(0xFF141414) : colorScheme.primary;
    }

    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 60.0, left: 24.0, right: 24.0), // 避免被底層的按鈕或狀態列遮擋，並加入左右邊距
          child: Material(
            color: Colors.transparent,
            child: SlideTransition(
              position: _offset,
              child: FadeTransition(
                opacity: _opacity,
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.foreground.withValues(alpha: 0.12),
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      widget.message, 
                      style: TextStyle(
                        color: widget.isError ? colorScheme.background : Colors.white, 
                        fontWeight: FontWeight.w500
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
