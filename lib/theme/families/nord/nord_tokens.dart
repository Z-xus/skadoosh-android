import 'package:flutter/material.dart';
import '../../base/semantic_tokens.dart';
import '../../base/theme_family.dart';
import 'nord_colors.dart';

/// Nord implementation of semantic tokens
class NordTokens with SemanticTokens {
  const NordTokens._({
    required this.variantName,
    required this.colors,
    required this.brightness,
  });

  final String variantName;
  final Map<String, Color> colors;

  @override
  final Brightness brightness;

  @override
  String get name => 'Nord $variantName';

  // === Factory constructors for official Nord variants ===

  /// Polar Night - The dark variant inspired by the arctic night sky
  factory NordTokens.polarNight() => const NordTokens._(
    variantName: 'Polar Night',
    colors: NordColors.polarNight,
    brightness: Brightness.dark,
  );

  /// Snow Storm - The light variant inspired by snow and ice
  factory NordTokens.snowStorm() => const NordTokens._(
    variantName: 'Snow Storm',
    colors: NordColors.snowStorm,
    brightness: Brightness.light,
  );

  /// Create from variant ID
  factory NordTokens.fromVariant(String variantId) {
    switch (variantId.toLowerCase()) {
      case 'polar_night':
      case 'polarnight':
      case 'dark':
        return NordTokens.polarNight();
      case 'snow_storm':
      case 'snowstorm':
      case 'light':
      default:
        return NordTokens.snowStorm();
    }
  }

  // === Helper method to get colors safely ===
  Color _getColor(String key) {
    return colors[key] ?? colors['nord5']!;
  }

  // === Background Tokens ===
  @override
  Color get bgBase => _getColor('nord0');

  @override
  Color get bgSecondary => _getColor('nord1');

  @override
  Color get bgTertiary => _getColor('nord2');

  @override
  Color get bgOverlay => _getColor('nord3');

  // === Text Tokens ===
  @override
  Color get textPrimary => _getColor('nord5');

  @override
  Color get textSecondary => _getColor('nord4');

  @override
  Color get textTertiary => _getColor('nord3');

  @override
  Color get textInverse =>
      brightness == Brightness.light ? _getColor('nord0') : _getColor('nord6');

  // === Interactive/Accent Tokens ===
  @override
  Color get accentPrimary => _getColor('nord10'); // Primary blue

  @override
  Color get accentSecondary => _getColor('nord8'); // Cyan

  @override
  Color get accentTertiary => _getColor('nord15'); // Purple (mapped from missing colors)

  // === Semantic State Tokens ===
  @override
  Color get stateSuccess => _getColor('nord14'); // Green

  @override
  Color get stateWarning => _getColor('nord13'); // Yellow

  @override
  Color get stateError => _getColor('nord11'); // Red

  @override
  Color get stateInfo => _getColor('nord9'); // Blue

  // === Interactive State Tokens ===
  @override
  Color get interactiveHover => _getColor('nord2');

  @override
  Color get interactivePressed => _getColor('nord3');

  @override
  Color get interactiveFocus => _getColor('nord10');

  @override
  Color get interactiveDisabled => _getColor('nord3');

  // === Border/Outline Tokens ===
  @override
  Color get borderPrimary => _getColor('nord3');

  @override
  Color get borderSecondary => _getColor('nord2');

  @override
  Color get borderFocus => _getColor('nord10');

  @override
  Color get borderError => _getColor('nord11');

  // === Surface Variant Tokens ===
  @override
  Color get surfaceInput => _getColor('nord1');

  @override
  Color get surfaceSelected => _getColor('nord2');

  @override
  Color get surfaceNavigation => _getColor('nord1');

  /// Get all available Nord variants
  static List<ThemeVariant> get variants => [
    const ThemeVariant(
      id: 'polar_night',
      displayName: 'Polar Night',
      brightness: Brightness.dark,
      description: 'Dark theme inspired by arctic night',
    ),
    const ThemeVariant(
      id: 'snow_storm',
      displayName: 'Snow Storm',
      brightness: Brightness.light,
      description: 'Light theme inspired by snow and ice',
    ),
  ];

  /// Legacy access to raw Nord colors for backward compatibility
  Map<String, Color> get rawColors => colors;

  /// Quick access to popular Nord colors using semantic naming
  Color get frost1 => _getColor('nord7'); // Muted cyan
  Color get frost2 => _getColor('nord8'); // Bright cyan
  Color get frost3 => _getColor('nord9'); // Blue
  Color get frost4 => _getColor('nord10'); // Dark blue
  Color get aurora1 => _getColor('nord11'); // Red
  Color get aurora2 => _getColor('nord12'); // Orange
  Color get aurora3 => _getColor('nord13'); // Yellow
  Color get aurora4 => _getColor('nord14'); // Green
  Color get aurora5 => _getColor('nord15'); // Purple
}
