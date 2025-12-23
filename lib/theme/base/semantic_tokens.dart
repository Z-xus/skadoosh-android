import 'package:flutter/material.dart';

/// Mixin providing semantic color tokens used across all theme families.
/// This enables consistent functional mapping regardless of the underlying theme.
///
/// All themes must implement these semantic tokens to ensure UI consistency.
mixin SemanticTokens {
  /// Theme identification
  String get name;
  Brightness get brightness;

  // === Base Background Tokens ===
  /// Primary background color for the main surface
  Color get bgBase;

  /// Secondary background color for elevated surfaces (cards, dialogs)
  Color get bgSecondary;

  /// Tertiary background color for further elevated surfaces
  Color get bgTertiary;

  /// Background color for overlays, modals, and temporary surfaces
  Color get bgOverlay;

  // === Text Tokens ===
  /// Primary text color for main content
  Color get textPrimary;

  /// Secondary text color for subtitles and less important text
  Color get textSecondary;

  /// Tertiary text color for placeholders, disabled text, and hints
  Color get textTertiary;

  /// Text color for use on colored/accent backgrounds
  Color get textInverse;

  // === Interactive/Accent Tokens ===
  /// Primary accent color for main CTAs, primary buttons, active states
  Color get accentPrimary;

  /// Secondary accent color for secondary actions and less prominent buttons
  Color get accentSecondary;

  /// Tertiary accent color for subtle accents and decorative elements
  Color get accentTertiary;

  // === Semantic State Tokens ===
  /// Color for success states, confirmations, and positive feedback
  Color get stateSuccess;

  /// Color for warning states, cautions, and non-critical alerts
  Color get stateWarning;

  /// Color for error states, failures, and destructive actions
  Color get stateError;

  /// Color for informational states, tips, and neutral messages
  Color get stateInfo;

  // === Interactive State Tokens ===
  /// Color for hover states on interactive elements
  Color get interactiveHover;

  /// Color for pressed/active states on interactive elements
  Color get interactivePressed;

  /// Color for focus indicators and accessibility highlights
  Color get interactiveFocus;

  /// Color for disabled interactive elements
  Color get interactiveDisabled;

  // === Border/Outline Tokens ===
  /// Primary border color for main dividers and container outlines
  Color get borderPrimary;

  /// Secondary border color for subtle dividers and inactive states
  Color get borderSecondary;

  /// Border color for focused elements and active selections
  Color get borderFocus;

  /// Border color for error states and validation failures
  Color get borderError;

  // === Surface Variant Tokens ===
  /// Surface color for input fields and form elements
  Color get surfaceInput;

  /// Surface color for selected/highlighted items
  Color get surfaceSelected;

  /// Surface color for navigation elements (nav bars, tabs)
  Color get surfaceNavigation;

  /// Convert semantic tokens to Flutter ColorScheme
  ColorScheme toColorScheme() {
    return ColorScheme(
      brightness: brightness,

      // Primary colors
      primary: accentPrimary,
      onPrimary: textInverse,
      primaryContainer: bgTertiary,
      onPrimaryContainer: textPrimary,

      // Secondary colors
      secondary: accentSecondary,
      onSecondary: textInverse,
      secondaryContainer: bgSecondary,
      onSecondaryContainer: textPrimary,

      // Tertiary colors
      tertiary: accentTertiary,
      onTertiary: textInverse,
      tertiaryContainer: surfaceSelected,
      onTertiaryContainer: textPrimary,

      // Error colors
      error: stateError,
      onError: textInverse,
      errorContainer: stateError.withValues(alpha: 0.1),
      onErrorContainer: stateError,

      // Surface colors
      surface: bgBase,
      onSurface: textPrimary,
      surfaceContainerHighest: bgTertiary,
      surfaceContainerHigh: bgSecondary,
      surfaceContainer: surfaceInput,
      surfaceContainerLow: bgBase,
      surfaceContainerLowest: bgBase,
      onSurfaceVariant: textSecondary,

      // Outline colors
      outline: borderPrimary,
      outlineVariant: borderSecondary,

      // Other colors
      shadow: Colors.black.withValues(alpha: 0.1),
      scrim: Colors.black.withValues(alpha: 0.5),
      inverseSurface: brightness == Brightness.light ? bgTertiary : bgBase,
      onInverseSurface: brightness == Brightness.light
          ? textPrimary
          : textInverse,
      inversePrimary: brightness == Brightness.light
          ? textPrimary
          : accentPrimary,
    );
  }
}

/// Extension to provide semantic color access for widgets
extension SemanticTokensExtension on SemanticTokens {
  /// Quick access to common color combinations

  /// Success color combination
  ({Color foreground, Color background}) get successColors => (
    foreground: stateSuccess,
    background: stateSuccess.withValues(alpha: 0.1),
  );

  /// Warning color combination
  ({Color foreground, Color background}) get warningColors => (
    foreground: stateWarning,
    background: stateWarning.withValues(alpha: 0.1),
  );

  /// Error color combination
  ({Color foreground, Color background}) get errorColors =>
      (foreground: stateError, background: stateError.withValues(alpha: 0.1));

  /// Info color combination
  ({Color foreground, Color background}) get infoColors =>
      (foreground: stateInfo, background: stateInfo.withValues(alpha: 0.1));
}
