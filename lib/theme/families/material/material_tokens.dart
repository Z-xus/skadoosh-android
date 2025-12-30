import 'package:flutter/material.dart';
import '../../base/semantic_tokens.dart';
import '../../base/theme_family.dart';
import 'material_colors.dart';

/// Material Design tokens that adapt to system accent colors
/// Supports light, dark gray, and pure AMOLED black variants
class MaterialTokens with SemanticTokens {
  MaterialTokens._({
    required this.variantId,
    required this.variantName,
    required this.brightness,
    this.systemColorScheme,
  });

  final String variantId;
  final String variantName;

  @override
  final Brightness brightness;

  /// System ColorScheme from dynamic_color (if available)
  final ColorScheme? systemColorScheme;

  @override
  String get name => 'Material $variantName';

  /// Get accent color from system or fallback
  Color get _accentColor {
    if (systemColorScheme != null) {
      return systemColorScheme!.primary;
    }
    // Fallback to Material Blue
    return brightness == Brightness.light
        ? const Color(0xFF1976D2)
        : const Color(0xFF42A5F5);
  }

  /// Get secondary accent from system or fallback
  Color get _secondaryAccent {
    if (systemColorScheme != null) {
      return systemColorScheme!.secondary;
    }
    final hsl = HSLColor.fromColor(_accentColor);
    return hsl.withLightness((hsl.lightness + 0.1).clamp(0.0, 1.0)).toColor();
  }

  /// Get tertiary accent from system or fallback
  Color get _tertiaryAccent {
    if (systemColorScheme != null) {
      return systemColorScheme!.tertiary;
    }
    final hsl = HSLColor.fromColor(_accentColor);
    return hsl.withLightness((hsl.lightness + 0.2).clamp(0.0, 1.0)).toColor();
  }

  // === Light Theme ===
  factory MaterialTokens.light({ColorScheme? systemColorScheme}) {
    return MaterialTokens._(
      variantId: 'light',
      variantName: 'Light',
      brightness: Brightness.light,
      systemColorScheme: systemColorScheme,
    );
  }

  // === Dark Theme (Material gray) ===
  factory MaterialTokens.dark({ColorScheme? systemColorScheme}) {
    return MaterialTokens._(
      variantId: 'dark',
      variantName: 'Dark',
      brightness: Brightness.dark,
      systemColorScheme: systemColorScheme,
    );
  }

  // === AMOLED Black Theme (Pure Black) ===
  factory MaterialTokens.amoled({ColorScheme? systemColorScheme}) {
    return MaterialTokens._(
      variantId: 'amoled',
      variantName: 'AMOLED Black',
      brightness: Brightness.dark,
      systemColorScheme: systemColorScheme,
    );
  }

  // === Background Tokens ===
  @override
  Color get bgBase {
    if (variantId == 'amoled') return MaterialColors.pureBlack;
    return brightness == Brightness.light
        ? MaterialColors.pureWhite
        : MaterialColors.gray900;
  }

  @override
  Color get bgSecondary {
    if (variantId == 'amoled') {
      // For AMOLED, use very dark gray (#0D0D0D) for slight elevation
      return const Color(0xFF0D0D0D);
    }
    return brightness == Brightness.light
        ? MaterialColors.gray50
        : MaterialColors.gray850;
  }

  @override
  Color get bgTertiary {
    if (variantId == 'amoled') {
      // For AMOLED, use darker gray (#1A1A1A) for more elevation
      return const Color(0xFF1A1A1A);
    }
    return brightness == Brightness.light
        ? MaterialColors.gray100
        : MaterialColors.gray800;
  }

  @override
  Color get bgOverlay {
    if (variantId == 'amoled') {
      return MaterialColors.pureBlack.withValues(alpha: 0.95);
    }
    return brightness == Brightness.light
        ? MaterialColors.pureBlack.withValues(alpha: 0.5)
        : MaterialColors.pureBlack.withValues(alpha: 0.7);
  }

  // === Text Tokens ===
  @override
  Color get textPrimary => brightness == Brightness.light
      ? MaterialColors.gray900
      : MaterialColors.pureWhite;

  @override
  Color get textSecondary {
    if (variantId == 'amoled') {
      // For AMOLED, use lighter gray for better contrast on black
      return MaterialColors.gray400;
    }
    return brightness == Brightness.light
        ? MaterialColors.gray700
        : MaterialColors.gray300;
  }

  @override
  Color get textTertiary {
    if (variantId == 'amoled') {
      // For AMOLED, use medium gray
      return MaterialColors.gray500;
    }
    return brightness == Brightness.light
        ? MaterialColors.gray500
        : MaterialColors.gray500;
  }

  @override
  Color get textInverse => brightness == Brightness.light
      ? MaterialColors.pureWhite
      : MaterialColors.gray900;

  // === Accent Tokens (use system accent) ===
  @override
  Color get accentPrimary => _accentColor;

  @override
  Color get accentSecondary => _secondaryAccent;

  @override
  Color get accentTertiary => _tertiaryAccent;

  // === State Tokens ===
  @override
  Color get stateSuccess => brightness == Brightness.light
      ? MaterialColors.successLight
      : MaterialColors.successDark;

  @override
  Color get stateWarning => brightness == Brightness.light
      ? MaterialColors.warningLight
      : MaterialColors.warningDark;

  @override
  Color get stateError => brightness == Brightness.light
      ? MaterialColors.errorLight
      : MaterialColors.errorDark;

  @override
  Color get stateInfo => brightness == Brightness.light
      ? MaterialColors.infoLight
      : MaterialColors.infoDark;

  // === Interactive State Tokens ===
  @override
  Color get interactiveHover {
    if (variantId == 'amoled') {
      return const Color(0xFF1F1F1F);
    }
    return brightness == Brightness.light
        ? MaterialColors.gray200
        : MaterialColors.gray800;
  }

  @override
  Color get interactivePressed {
    if (variantId == 'amoled') {
      return const Color(0xFF2A2A2A);
    }
    return brightness == Brightness.light
        ? MaterialColors.gray300
        : MaterialColors.gray700;
  }

  @override
  Color get interactiveFocus => _accentColor.withValues(alpha: 0.2);

  @override
  Color get interactiveDisabled {
    if (variantId == 'amoled') {
      return MaterialColors.gray700;
    }
    return brightness == Brightness.light
        ? MaterialColors.gray400
        : MaterialColors.gray600;
  }

  // === Border Tokens ===
  @override
  Color get borderPrimary {
    if (variantId == 'amoled') {
      // For AMOLED, use very subtle border
      return const Color(0xFF2A2A2A);
    }
    return brightness == Brightness.light
        ? MaterialColors.gray300
        : MaterialColors.gray700;
  }

  @override
  Color get borderSecondary {
    if (variantId == 'amoled') {
      // For AMOLED, use even more subtle border
      return const Color(0xFF1A1A1A);
    }
    return brightness == Brightness.light
        ? MaterialColors.gray200
        : MaterialColors.gray800;
  }

  @override
  Color get borderFocus => _accentColor;

  @override
  Color get borderError => stateError;

  // === Surface Tokens ===
  @override
  Color get surfaceInput {
    if (variantId == 'amoled') {
      // For AMOLED, use very dark surface
      return const Color(0xFF0D0D0D);
    }
    return brightness == Brightness.light
        ? MaterialColors.gray50
        : MaterialColors.gray850;
  }

  @override
  Color get surfaceSelected {
    return _accentColor.withValues(alpha: variantId == 'amoled' ? 0.15 : 0.1);
  }

  @override
  Color get surfaceNavigation {
    if (variantId == 'amoled') return MaterialColors.pureBlack;
    return brightness == Brightness.light
        ? MaterialColors.pureWhite
        : MaterialColors.gray900;
  }

  // === Static Variant Definitions ===
  static final List<ThemeVariant> variants = [
    const ThemeVariant(
      id: 'light',
      displayName: 'Light',
      brightness: Brightness.light,
      description: 'Clean light theme with system accent',
    ),
    const ThemeVariant(
      id: 'dark',
      displayName: 'Dark Gray',
      brightness: Brightness.dark,
      description: 'Material dark theme with gray backgrounds',
    ),
    const ThemeVariant(
      id: 'amoled',
      displayName: 'AMOLED Black',
      brightness: Brightness.dark,
      description: 'Pure black theme for AMOLED displays',
    ),
  ];

  /// Factory method to create tokens from variant ID
  static MaterialTokens fromVariant(
    String variantId, {
    ColorScheme? systemColorScheme,
  }) {
    switch (variantId) {
      case 'light':
        return MaterialTokens.light(systemColorScheme: systemColorScheme);
      case 'dark':
        return MaterialTokens.dark(systemColorScheme: systemColorScheme);
      case 'amoled':
        return MaterialTokens.amoled(systemColorScheme: systemColorScheme);
      default:
        return MaterialTokens.light(systemColorScheme: systemColorScheme);
    }
  }
}
