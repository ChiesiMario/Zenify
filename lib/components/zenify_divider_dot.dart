import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class ZenifyDividerDot extends StatelessWidget {
  final double? offsetY;

  const ZenifyDividerDot({
    super.key,
    this.offsetY,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;
    
    // 如果沒有明確傳入 offsetY，預設使用 -1.0 往上提（適合 12~13px 文字），
    // 這樣可以保持其他地方的居中感。
    final yOffset = offsetY ?? -1.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3.0),
      child: Transform.translate(
        offset: Offset(0, yOffset), 
        child: Text(
          '•',
          style: TextStyle(
            color: colorScheme.mutedForeground,
            fontSize: 14,
            fontWeight: FontWeight.normal,
            fontFamily: 'NotoSansTC',
            height: 1.1,
          ),
        ),
      ),
    );
  }
}
