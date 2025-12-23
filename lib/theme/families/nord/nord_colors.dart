import 'package:flutter/material.dart';

/// Official Nord theme colors
/// Based on the official Nord color specification: https://nordtheme.com/
class NordColors {
  // === POLAR NIGHT (Dark Theme) ===
  static const Map<String, Color> polarNight = {
    // Polar Night - darkest to lightest
    'nord0': Color(0xFF2E3440), // Darkest background
    'nord1': Color(0xFF3B4252), // Dark background variant
    'nord2': Color(0xFF434C5E), // Elevated background
    'nord3': Color(0xFF4C566A), // Comments, borders
    // Snow Storm - darkest to lightest (text colors for dark theme)
    'nord4': Color(0xFFD8DEE9), // Secondary text
    'nord5': Color(0xFFE5E9F0), // Primary text
    'nord6': Color(0xFFECEFF4), // Brightest text
    // Frost - accent blues and cyan
    'nord7': Color(0xFF8FBCBB), // Muted cyan
    'nord8': Color(0xFF88C0D0), // Bright cyan
    'nord9': Color(0xFF81A1C1), // Blue
    'nord10': Color(0xFF5E81AC), // Dark blue
    // Aurora - red, orange, yellow, green, purple
    'nord11': Color(0xFFBF616A), // Red
    'nord12': Color(0xFFD08770), // Orange
    'nord13': Color(0xFFEBCB8B), // Yellow
    'nord14': Color(0xFFA3BE8C), // Green
    'nord15': Color(0xFFB48EAD), // Purple
  };

  // === SNOW STORM (Light Theme) ===
  static const Map<String, Color> snowStorm = {
    // Snow Storm - lightest to darkest (backgrounds for light theme)
    'nord0': Color(0xFFECEFF4), // Lightest background
    'nord1': Color(0xFFE5E9F0), // Light background variant
    'nord2': Color(0xFFD8DEE9), // Elevated background
    'nord3': Color(0xFF4C566A), // Borders, dividers
    // Polar Night - lightest to darkest (text colors for light theme)
    'nord4': Color(0xFF4C566A), // Secondary text
    'nord5': Color(0xFF434C5E), // Primary text
    'nord6': Color(0xFF2E3440), // Darkest text
    // Frost - same as dark theme
    'nord7': Color(0xFF8FBCBB), // Muted cyan
    'nord8': Color(0xFF88C0D0), // Bright cyan
    'nord9': Color(0xFF81A1C1), // Blue
    'nord10': Color(0xFF5E81AC), // Dark blue
    // Aurora - same as dark theme
    'nord11': Color(0xFFBF616A), // Red
    'nord12': Color(0xFFD08770), // Orange
    'nord13': Color(0xFFEBCB8B), // Yellow
    'nord14': Color(0xFFA3BE8C), // Green
    'nord15': Color(0xFFB48EAD), // Purple
  };

  /// Get color palette by variant name
  static Map<String, Color> getPalette(String variantName) {
    switch (variantName.toLowerCase()) {
      case 'polarnight':
      case 'polar_night':
      case 'dark':
        return polarNight;
      case 'snowstorm':
      case 'snow_storm':
      case 'light':
      default:
        return snowStorm;
    }
  }

  /// Get all available variants
  static List<String> get variants => ['polar_night', 'snow_storm'];
}
