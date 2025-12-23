import 'package:flutter/material.dart';

/// Official Catppuccin color definitions for all 4 flavors
/// Based on the official Catppuccin color specification
class CatppuccinColors {
  // === LATTE (Light Theme) ===
  static const Map<String, Color> latte = {
    // Base colors
    'base': Color(0xFFEFF1F5), // Light background
    'mantle': Color(0xFFE6E9EF), // Slightly darker background
    'crust': Color(0xFFDCE0E8), // Even darker background
    // Surface colors
    'surface0': Color(0xFFCCD0DA), // Disabled elements
    'surface1': Color(0xFFBCC0CC), // Hover surface
    'surface2': Color(0xFFACB0BE), // Active surface
    // Overlay colors
    'overlay0': Color(0xFF9CA0B0), // Borders, separators
    'overlay1': Color(0xFF8C8FA1), // Borders, separators
    'overlay2': Color(0xFF7C7F93), // Borders, separators
    // Text colors
    'subtext0': Color(0xFF6C6F85), // Subtitles, placeholders
    'subtext1': Color(0xFF5C5F77), // Subtitles, placeholders
    'text': Color(0xFF4C4F69), // Default text
    // Accent colors
    'rosewater': Color(0xFFDC8A78), // Warm accent
    'flamingo': Color(0xFFDD7878), // Error/destructive
    'pink': Color(0xFFEA76CB), // Love, like
    'mauve': Color(0xFF8839EF), // Primary accent
    'red': Color(0xFFD20F39), // Error, danger
    'maroon': Color(0xFFE64553), // Error variant
    'peach': Color(0xFFFE640B), // Warning
    'yellow': Color(0xFFDF8E1D), // Warning variant
    'green': Color(0xFF40A02B), // Success
    'teal': Color(0xFF179299), // Success variant
    'sky': Color(0xFF04A5E5), // Info
    'sapphire': Color(0xFF209FB5), // Info variant
    'blue': Color(0xFF1E66F5), // Links, info
    'lavender': Color(0xFF7287FD), // Accent variant
  };

  // === FRAPPÉ (Cool Light Theme) ===
  static const Map<String, Color> frappe = {
    // Base colors
    'base': Color(0xFF303446), // Dark background
    'mantle': Color(0xFF292C3C), // Slightly darker background
    'crust': Color(0xFF232634), // Even darker background
    // Surface colors
    'surface0': Color(0xFF414559), // Disabled elements
    'surface1': Color(0xFF51576D), // Hover surface
    'surface2': Color(0xFF626880), // Active surface
    // Overlay colors
    'overlay0': Color(0xFF737994), // Borders, separators
    'overlay1': Color(0xFF838BA7), // Borders, separators
    'overlay2': Color(0xFF949CBB), // Borders, separators
    // Text colors
    'subtext0': Color(0xFFA5ADCE), // Subtitles, placeholders
    'subtext1': Color(0xFFB5BDE2), // Subtitles, placeholders
    'text': Color(0xFFC6D0F5), // Default text
    // Accent colors
    'rosewater': Color(0xFFF2D5CF), // Warm accent
    'flamingo': Color(0xFFEEBEBE), // Error/destructive
    'pink': Color(0xFFF4B8E4), // Love, like
    'mauve': Color(0xFFCA9EE6), // Primary accent
    'red': Color(0xFFE78284), // Error, danger
    'maroon': Color(0xFFEA999C), // Error variant
    'peach': Color(0xFFEF9F76), // Warning
    'yellow': Color(0xFFE5C890), // Warning variant
    'green': Color(0xFFA6D189), // Success
    'teal': Color(0xFF81C8BE), // Success variant
    'sky': Color(0xFF99D1DB), // Info
    'sapphire': Color(0xFF85C1DC), // Info variant
    'blue': Color(0xFF8CAAEE), // Links, info
    'lavender': Color(0xFFBAABDA), // Accent variant
  };

  // === MACCHIATO (Warm Dark Theme) ===
  static const Map<String, Color> macchiato = {
    // Base colors
    'base': Color(0xFF24273A), // Dark background
    'mantle': Color(0xFF1E2030), // Slightly darker background
    'crust': Color(0xFF181926), // Even darker background
    // Surface colors
    'surface0': Color(0xFF363A4F), // Disabled elements
    'surface1': Color(0xFF494D64), // Hover surface
    'surface2': Color(0xFF5B6078), // Active surface
    // Overlay colors
    'overlay0': Color(0xFF6E738D), // Borders, separators
    'overlay1': Color(0xFF8087A2), // Borders, separators
    'overlay2': Color(0xFF939AB7), // Borders, separators
    // Text colors
    'subtext0': Color(0xFFA5ADCB), // Subtitles, placeholders
    'subtext1': Color(0xFFB8C0E0), // Subtitles, placeholders
    'text': Color(0xFFCAD3F5), // Default text
    // Accent colors
    'rosewater': Color(0xFFF4DBD6), // Warm accent
    'flamingo': Color(0xFFF0C6C6), // Error/destructive
    'pink': Color(0xFFF5BDE6), // Love, like
    'mauve': Color(0xFFC6A0F6), // Primary accent
    'red': Color(0xFFED8796), // Error, danger
    'maroon': Color(0xFFEE99A0), // Error variant
    'peach': Color(0xFFF5A97F), // Warning
    'yellow': Color(0xFFEED49F), // Warning variant
    'green': Color(0xFFA6DA95), // Success
    'teal': Color(0xFF8BD5CA), // Success variant
    'sky': Color(0xFF91D7E3), // Info
    'sapphire': Color(0xFF7DC4E4), // Info variant
    'blue': Color(0xFF8AADF4), // Links, info
    'lavender': Color(0xFFB7BDF8), // Accent variant
  };

  // === MOCHA (Deep Dark Theme) ===
  static const Map<String, Color> mocha = {
    // Base colors
    'base': Color(0xFF1E1E2E), // Dark background
    'mantle': Color(0xFF181825), // Slightly darker background
    'crust': Color(0xFF11111B), // Even darker background
    // Surface colors
    'surface0': Color(0xFF313244), // Disabled elements
    'surface1': Color(0xFF45475A), // Hover surface
    'surface2': Color(0xFF585B70), // Active surface
    // Overlay colors
    'overlay0': Color(0xFF6C7086), // Borders, separators
    'overlay1': Color(0xFF7F849C), // Borders, separators
    'overlay2': Color(0xFF9399B2), // Borders, separators
    // Text colors
    'subtext0': Color(0xFFA6ADC8), // Subtitles, placeholders
    'subtext1': Color(0xFFBAC2DE), // Subtitles, placeholders
    'text': Color(0xFFCDD6F4), // Default text
    // Accent colors
    'rosewater': Color(0xFFF5E0DC), // Warm accent
    'flamingo': Color(0xFFF2CDCD), // Error/destructive
    'pink': Color(0xFFF5C2E7), // Love, like
    'mauve': Color(0xFFCBA6F7), // Primary accent
    'red': Color(0xFFF38BA8), // Error, danger
    'maroon': Color(0xFFEBA0AC), // Error variant
    'peach': Color(0xFFFAB387), // Warning
    'yellow': Color(0xFFF9E2AF), // Warning variant
    'green': Color(0xFFA6E3A1), // Success
    'teal': Color(0xFF94E2D5), // Success variant
    'sky': Color(0xFF89DCEB), // Info
    'sapphire': Color(0xFF74C7EC), // Info variant
    'blue': Color(0xFF89B4FA), // Links, info
    'lavender': Color(0xFFB4BEFE), // Accent variant
  };

  /// Get color palette by flavor name
  static Map<String, Color> getPalette(String flavorName) {
    switch (flavorName.toLowerCase()) {
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

  /// Get all available flavors
  static List<String> get flavors => ['latte', 'frappe', 'macchiato', 'mocha'];
}
