import 'package:flutter/material.dart';
import '../../base/semantic_tokens.dart';
import '../../base/theme_family.dart';
import 'catppuccin_colors.dart';

/// Catppuccin implementation of semantic tokens
class CatppuccinTokens with SemanticTokens {
  const CatppuccinTokens._({
    required this.flavorName,
    required this.colors,
    required this.brightness,
  });

  final String flavorName;
  final Map<String, Color> colors;

  @override
  final Brightness brightness;

  @override
  String get name => 'Catppuccin $flavorName';

  // === Factory constructors for each official Catppuccin flavor ===

  /// Latte - Light and creamy
  factory CatppuccinTokens.latte() => CatppuccinTokens._(
    flavorName: 'Latte',
    colors: CatppuccinColors.latte,
    brightness: Brightness.light,
  );

  /// Frappé - Soft morning vibes
  factory CatppuccinTokens.frappe() => CatppuccinTokens._(
    flavorName: 'Frappé',
    colors: CatppuccinColors.frappe,
    brightness: Brightness.dark,
  );

  /// Macchiato - Cozy evening mood
  factory CatppuccinTokens.macchiato() => CatppuccinTokens._(
    flavorName: 'Macchiato',
    colors: CatppuccinColors.macchiato,
    brightness: Brightness.dark,
  );

  /// Mocha - Deep and rich
  factory CatppuccinTokens.mocha() => CatppuccinTokens._(
    flavorName: 'Mocha',
    colors: CatppuccinColors.mocha,
    brightness: Brightness.dark,
  );

  /// Create from variant ID
  factory CatppuccinTokens.fromVariant(String variantId) {
    switch (variantId.toLowerCase()) {
      case 'latte':
        return CatppuccinTokens.latte();
      case 'frappe':
      case 'frappé':
        return CatppuccinTokens.frappe();
      case 'macchiato':
        return CatppuccinTokens.macchiato();
      case 'mocha':
      default:
        return CatppuccinTokens.mocha();
    }
  }

  // === Helper method to get colors safely ===
  Color _getColor(String key) {
    return colors[key] ?? colors['text']!;
  }

  // === Background Tokens ===
  @override
  Color get bgBase => _getColor('base');

  @override
  Color get bgSecondary => _getColor('surface0');

  @override
  Color get bgTertiary => _getColor('surface1');

  @override
  Color get bgOverlay => _getColor('overlay0');

  // === Text Tokens ===
  @override
  Color get textPrimary => _getColor('text');

  @override
  Color get textSecondary => _getColor('subtext1');

  @override
  Color get textTertiary => _getColor('subtext0');

  @override
  Color get textInverse =>
      brightness == Brightness.light ? _getColor('base') : _getColor('crust');

  // === Interactive/Accent Tokens ===
  @override
  Color get accentPrimary => _getColor('mauve');

  @override
  Color get accentSecondary => _getColor('lavender');

  @override
  Color get accentTertiary => _getColor('rosewater');

  // === Semantic State Tokens ===
  @override
  Color get stateSuccess => _getColor('green');

  @override
  Color get stateWarning => _getColor('yellow');

  @override
  Color get stateError => _getColor('red');

  @override
  Color get stateInfo => _getColor('blue');

  // === Interactive State Tokens ===
  @override
  Color get interactiveHover => _getColor('surface1');

  @override
  Color get interactivePressed => _getColor('surface2');

  @override
  Color get interactiveFocus => _getColor('mauve');

  @override
  Color get interactiveDisabled => _getColor('overlay0');

  // === Border/Outline Tokens ===
  @override
  Color get borderPrimary => _getColor('overlay0');

  @override
  Color get borderSecondary => _getColor('surface2');

  @override
  Color get borderFocus => _getColor('mauve');

  @override
  Color get borderError => _getColor('red');

  // === Surface Variant Tokens ===
  @override
  Color get surfaceInput => _getColor('surface0');

  @override
  Color get surfaceSelected => _getColor('surface1');

  @override
  Color get surfaceNavigation => _getColor('mantle');

  /// Get all available Catppuccin variants
  static List<ThemeVariant> get variants => [
    const ThemeVariant(
      id: 'latte',
      displayName: 'Latte',
      brightness: Brightness.light,
      description: 'Light & creamy',
    ),
    const ThemeVariant(
      id: 'frappe',
      displayName: 'Frappé',
      brightness: Brightness.dark,
      description: 'Soft morning vibes',
    ),
    const ThemeVariant(
      id: 'macchiato',
      displayName: 'Macchiato',
      brightness: Brightness.dark,
      description: 'Cozy evening mood',
    ),
    const ThemeVariant(
      id: 'mocha',
      displayName: 'Mocha',
      brightness: Brightness.dark,
      description: 'Deep & rich',
    ),
  ];

  /// Legacy access to raw Catppuccin colors for backward compatibility
  ///
  /// This allows existing code that directly uses Catppuccin colors to continue working
  /// while migrating to semantic tokens.
  Map<String, Color> get rawColors => colors;

  /// Quick access to popular Catppuccin colors for legacy support
  Color get mauve => _getColor('mauve');
  Color get pink => _getColor('pink');
  Color get flamingo => _getColor('flamingo');
  Color get peach => _getColor('peach');
  Color get sapphire => _getColor('sapphire');
  Color get sky => _getColor('sky');
  Color get teal => _getColor('teal');
  Color get maroon => _getColor('maroon');
}
