import 'package:flutter/material.dart';

/// Official Dracula theme colors
/// Based on the official Dracula color specification: https://draculatheme.com/
class DraculaColors {
  // === STANDARD (Dark Theme) ===
  static const Map<String, Color> standard = {
    // Background colors
    'background': Color(0xFF282A36), // Main background
    'currentLine': Color(0xFF44475A), // Current line/selection
    'selection': Color(0xFF44475A), // Selection highlight
    'foreground': Color(0xFFF8F8F2), // Main text
    'comment': Color(0xFF6272A4), // Comments and secondary text
    // Dracula color palette
    'cyan': Color(0xFF8BE9FD), // Bright cyan
    'green': Color(0xFF50FA7B), // Bright green
    'orange': Color(0xFFFFB86C), // Bright orange
    'pink': Color(0xFFFF79C6), // Bright pink
    'purple': Color(0xFFBD93F9), // Bright purple
    'red': Color(0xFFFF5555), // Bright red
    'yellow': Color(0xFFF1FA8C), // Bright yellow
    // Additional useful colors
    'white': Color(0xFFF8F8F2), // Pure white equivalent
    'gray': Color(0xFF6272A4), // Gray for subtler text
    'darkGray': Color(0xFF21222C), // Even darker background
  };

  /// Get color palette by variant name
  static Map<String, Color> getPalette(String variantName) {
    switch (variantName.toLowerCase()) {
      case 'standard':
      default:
        return standard;
    }
  }

  /// Get all available variants
  static List<String> get variants => ['standard'];
}
