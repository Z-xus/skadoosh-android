import 'package:flutter/material.dart';

/// Material Design color palette for system accent themes
/// Provides both light and dark variants that use system accent colors
class MaterialColors {
  MaterialColors._();

  // Pure black and white for AMOLED
  static const Color pureBlack = Color(0xFF000000);
  static const Color pureWhite = Color(0xFFFFFFFF);

  // Material grays
  static const Color gray50 = Color(0xFFFAFAFA);
  static const Color gray100 = Color(0xFFF5F5F5);
  static const Color gray200 = Color(0xFFEEEEEE);
  static const Color gray300 = Color(0xFFE0E0E0);
  static const Color gray400 = Color(0xFFBDBDBD);
  static const Color gray500 = Color(0xFF9E9E9E);
  static const Color gray600 = Color(0xFF757575);
  static const Color gray700 = Color(0xFF616161);
  static const Color gray800 = Color(0xFF424242);
  static const Color gray850 = Color(0xFF303030);
  static const Color gray900 = Color(0xFF212121);

  // Success (Green)
  static const Color successLight = Color(0xFF4CAF50);
  static const Color successDark = Color(0xFF81C784);

  // Warning (Orange)
  static const Color warningLight = Color(0xFFFF9800);
  static const Color warningDark = Color(0xFFFFB74D);

  // Error (Red)
  static const Color errorLight = Color(0xFFF44336);
  static const Color errorDark = Color(0xFFEF5350);

  // Info (Blue)
  static const Color infoLight = Color(0xFF2196F3);
  static const Color infoDark = Color(0xFF64B5F6);
}
