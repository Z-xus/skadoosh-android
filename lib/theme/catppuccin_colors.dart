import 'package:flutter/material.dart';

/// Catppuccin color palettes for all 4 flavors
/// Based on the official Catppuccin color specification
class CatppuccinColors {
  // Latte (Light theme)
  static const CatppuccinPalette latte = CatppuccinPalette(
    name: 'Latte',
    brightness: Brightness.light,

    // Base colors
    base: Color(0xFFEFF1F5), // Light background
    mantle: Color(0xFFE6E9EF), // Slightly darker background
    crust: Color(0xFFDCE0E8), // Even darker background
    // Surface colors
    surface0: Color(0xFFCCD0DA), // Disabled elements
    surface1: Color(0xFFBCC0CC), // Hover surface
    surface2: Color(0xFFACB0BE), // Active surface
    // Overlay colors
    overlay0: Color(0xFF9CA0B0), // Borders, separators
    overlay1: Color(0xFF8C8FA1), // Borders, separators
    overlay2: Color(0xFF7C7F93), // Borders, separators
    // Text colors
    subtext0: Color(0xFF6C6F85), // Subtitles, placeholders
    subtext1: Color(0xFF5C5F77), // Subtitles, placeholders
    text: Color(0xFF4C4F69), // Default text
    // Accent colors
    rosewater: Color(0xFFDC8A78), // Warm accent
    flamingo: Color(0xFFDD7878), // Error/destructive
    pink: Color(0xFFEA76CB), // Love, like
    mauve: Color(0xFF8839EF), // Primary accent
    red: Color(0xFFD20F39), // Error, danger
    maroon: Color(0xFFE64553), // Error variant
    peach: Color(0xFFFE640B), // Warning
    yellow: Color(0xFFDF8E1D), // Warning variant
    green: Color(0xFF40A02B), // Success
    teal: Color(0xFF179299), // Success variant
    sky: Color(0xFF04A5E5), // Info
    sapphire: Color(0xFF209FB5), // Info variant
    blue: Color(0xFF1E66F5), // Links, info
    lavender: Color(0xFF7287FD), // Accent variant
  );

  // Frappé (Cool light theme)
  static const CatppuccinPalette frappe = CatppuccinPalette(
    name: 'Frappé',
    brightness: Brightness.dark,

    // Base colors
    base: Color(0xFF303446), // Dark background
    mantle: Color(0xFF292C3C), // Slightly darker background
    crust: Color(0xFF232634), // Even darker background
    // Surface colors
    surface0: Color(0xFF414559), // Disabled elements
    surface1: Color(0xFF51576D), // Hover surface
    surface2: Color(0xFF626880), // Active surface
    // Overlay colors
    overlay0: Color(0xFF737994), // Borders, separators
    overlay1: Color(0xFF838BA7), // Borders, separators
    overlay2: Color(0xFF949CBB), // Borders, separators
    // Text colors
    subtext0: Color(0xFFA5ADCE), // Subtitles, placeholders
    subtext1: Color(0xFFB5BDE2), // Subtitles, placeholders
    text: Color(0xFFC6D0F5), // Default text
    // Accent colors
    rosewater: Color(0xFFF2D5CF), // Warm accent
    flamingo: Color(0xFFEEBEBE), // Error/destructive
    pink: Color(0xFFF4B8E4), // Love, like
    mauve: Color(0xFFCA9EE6), // Primary accent
    red: Color(0xFFE78284), // Error, danger
    maroon: Color(0xFFEA999C), // Error variant
    peach: Color(0xFFEF9F76), // Warning
    yellow: Color(0xFFE5C890), // Warning variant
    green: Color(0xFFA6D189), // Success
    teal: Color(0xFF81C8BE), // Success variant
    sky: Color(0xFF99D1DB), // Info
    sapphire: Color(0xFF85C1DC), // Info variant
    blue: Color(0xFF8CAAEE), // Links, info
    lavender: Color(0xFFBAABDA), // Accent variant
  );

  // Macchiato (Warm dark theme)
  static const CatppuccinPalette macchiato = CatppuccinPalette(
    name: 'Macchiato',
    brightness: Brightness.dark,

    // Base colors
    base: Color(0xFF24273A), // Dark background
    mantle: Color(0xFF1E2030), // Slightly darker background
    crust: Color(0xFF181926), // Even darker background
    // Surface colors
    surface0: Color(0xFF363A4F), // Disabled elements
    surface1: Color(0xFF494D64), // Hover surface
    surface2: Color(0xFF5B6078), // Active surface
    // Overlay colors
    overlay0: Color(0xFF6E738D), // Borders, separators
    overlay1: Color(0xFF8087A2), // Borders, separators
    overlay2: Color(0xFF939AB7), // Borders, separators
    // Text colors
    subtext0: Color(0xFFA5ADCB), // Subtitles, placeholders
    subtext1: Color(0xFFB8C0E0), // Subtitles, placeholders
    text: Color(0xFFCAD3F5), // Default text
    // Accent colors
    rosewater: Color(0xFFF4DBD6), // Warm accent
    flamingo: Color(0xFFF0C6C6), // Error/destructive
    pink: Color(0xFFF5BDE6), // Love, like
    mauve: Color(0xFFC6A0F6), // Primary accent
    red: Color(0xFFED8796), // Error, danger
    maroon: Color(0xFFEE99A0), // Error variant
    peach: Color(0xFFF5A97F), // Warning
    yellow: Color(0xFFEED49F), // Warning variant
    green: Color(0xFFA6DA95), // Success
    teal: Color(0xFF8BD5CA), // Success variant
    sky: Color(0xFF91D7E3), // Info
    sapphire: Color(0xFF7DC4E4), // Info variant
    blue: Color(0xFF8AADF4), // Links, info
    lavender: Color(0xFFB7BDF8), // Accent variant
  );

  // Mocha (Deep dark theme)
  static const CatppuccinPalette mocha = CatppuccinPalette(
    name: 'Mocha',
    brightness: Brightness.dark,

    // Base colors
    base: Color(0xFF1E1E2E), // Dark background
    mantle: Color(0xFF181825), // Slightly darker background
    crust: Color(0xFF11111B), // Even darker background
    // Surface colors
    surface0: Color(0xFF313244), // Disabled elements
    surface1: Color(0xFF45475A), // Hover surface
    surface2: Color(0xFF585B70), // Active surface
    // Overlay colors
    overlay0: Color(0xFF6C7086), // Borders, separators
    overlay1: Color(0xFF7F849C), // Borders, separators
    overlay2: Color(0xFF9399B2), // Borders, separators
    // Text colors
    subtext0: Color(0xFFA6ADC8), // Subtitles, placeholders
    subtext1: Color(0xFFBAC2DE), // Subtitles, placeholders
    text: Color(0xFFCDD6F4), // Default text
    // Accent colors
    rosewater: Color(0xFFF5E0DC), // Warm accent
    flamingo: Color(0xFFF2CDCD), // Error/destructive
    pink: Color(0xFFF5C2E7), // Love, like
    mauve: Color(0xFFCBA6F7), // Primary accent
    red: Color(0xFFF38BA8), // Error, danger
    maroon: Color(0xFFEBA0AC), // Error variant
    peach: Color(0xFFFAB387), // Warning
    yellow: Color(0xFFF9E2AF), // Warning variant
    green: Color(0xFFA6E3A1), // Success
    teal: Color(0xFF94E2D5), // Success variant
    sky: Color(0xFF89DCEB), // Info
    sapphire: Color(0xFF74C7EC), // Info variant
    blue: Color(0xFF89B4FA), // Links, info
    lavender: Color(0xFFB4BEFE), // Accent variant
  );

  /// Get palette by name
  static CatppuccinPalette getPalette(String name) {
    switch (name.toLowerCase()) {
      case 'latte':
        return latte;
      case 'frappé':
      case 'frappe':
        return frappe;
      case 'macchiato':
        return macchiato;
      case 'mocha':
      default:
        return mocha;
    }
  }

  /// Get all available palettes
  static List<CatppuccinPalette> get allPalettes => [
    latte,
    frappe,
    macchiato,
    mocha,
  ];
}

/// Represents a complete Catppuccin color palette
class CatppuccinPalette {
  final String name;
  final Brightness brightness;

  // Base colors
  final Color base;
  final Color mantle;
  final Color crust;

  // Surface colors
  final Color surface0;
  final Color surface1;
  final Color surface2;

  // Overlay colors
  final Color overlay0;
  final Color overlay1;
  final Color overlay2;

  // Text colors
  final Color subtext0;
  final Color subtext1;
  final Color text;

  // Accent colors
  final Color rosewater;
  final Color flamingo;
  final Color pink;
  final Color mauve;
  final Color red;
  final Color maroon;
  final Color peach;
  final Color yellow;
  final Color green;
  final Color teal;
  final Color sky;
  final Color sapphire;
  final Color blue;
  final Color lavender;

  const CatppuccinPalette({
    required this.name,
    required this.brightness,
    required this.base,
    required this.mantle,
    required this.crust,
    required this.surface0,
    required this.surface1,
    required this.surface2,
    required this.overlay0,
    required this.overlay1,
    required this.overlay2,
    required this.subtext0,
    required this.subtext1,
    required this.text,
    required this.rosewater,
    required this.flamingo,
    required this.pink,
    required this.mauve,
    required this.red,
    required this.maroon,
    required this.peach,
    required this.yellow,
    required this.green,
    required this.teal,
    required this.sky,
    required this.sapphire,
    required this.blue,
    required this.lavender,
  });

  /// Create a Flutter ColorScheme from this Catppuccin palette
  ColorScheme toColorScheme() {
    return ColorScheme(
      brightness: brightness,

      // Primary colors
      primary: mauve,
      onPrimary: brightness == Brightness.light ? base : crust,
      primaryContainer: brightness == Brightness.light ? surface0 : surface2,
      onPrimaryContainer: text,

      // Secondary colors
      secondary: lavender,
      onSecondary: brightness == Brightness.light ? base : crust,
      secondaryContainer: brightness == Brightness.light ? surface1 : surface1,
      onSecondaryContainer: text,

      // Tertiary colors
      tertiary: pink,
      onTertiary: brightness == Brightness.light ? base : crust,
      tertiaryContainer: brightness == Brightness.light ? surface0 : surface2,
      onTertiaryContainer: text,

      // Error colors
      error: red,
      onError: brightness == Brightness.light ? base : crust,
      errorContainer: brightness == Brightness.light ? rosewater : maroon,
      onErrorContainer: text,

      // Surface colors
      surface: base,
      onSurface: text,
      surfaceContainerHighest: surface2,
      surfaceContainerHigh: surface1,
      surfaceContainer: surface0,
      surfaceContainerLow: mantle,
      surfaceContainerLowest: crust,
      onSurfaceVariant: subtext0,

      // Outline colors
      outline: overlay0,
      outlineVariant: overlay1,

      // Other colors
      shadow: crust,
      scrim: crust,
      inverseSurface: brightness == Brightness.light ? surface2 : base,
      onInverseSurface: brightness == Brightness.light ? base : text,
      inversePrimary: brightness == Brightness.light ? text : mauve,
    );
  }

  /// Get semantic colors for UI elements
  CatppuccinSemanticColors get semantic => CatppuccinSemanticColors(
    success: green,
    warning: yellow,
    info: blue,
    accent: sapphire,
    muted: subtext1,
    disabled: overlay0,
  );
}

/// Semantic colors derived from Catppuccin palette
class CatppuccinSemanticColors {
  final Color success;
  final Color warning;
  final Color info;
  final Color accent;
  final Color muted;
  final Color disabled;

  const CatppuccinSemanticColors({
    required this.success,
    required this.warning,
    required this.info,
    required this.accent,
    required this.muted,
    required this.disabled,
  });
}
