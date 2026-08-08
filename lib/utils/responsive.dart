import 'package:flutter/widgets.dart';

/// 取得響應式最大寬度，針對 3 欄 / 4 欄專輯排版做吸附
double getResponsiveMaxWidth(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  // 600px 剛好可以塞下 4 欄專輯 (含兩側 16px Padding 與中間各 16px Spacing)
  if (screenWidth >= 600) {
    return 600.0;
  }
  // 454px 剛好可以塞下 3 欄專輯
  else if (screenWidth >= 454) {
    return 454.0;
  }
  // 更小寬度直接填滿全螢幕
  else {
    return screenWidth;
  }
}
