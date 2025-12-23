import 'package:flutter/material.dart';
import '../../base/semantic_tokens.dart';
import '../../base/theme_family.dart';
import 'dracula_colors.dart';

/// Dracula implementation of semantic tokens
class DraculaTokens with SemanticTokens {
  const DraculaTokens._({
    required this.variantName,
    required this.colors,
    required this.brightness,
  });

  final String variantName;
  final Map<String, Color> colors;

  @override
  final Brightness brightness;

  @override
  String get name => 'Dracula $variantName';

  // === Factory constructors for official Dracula variants ===

  /// Standard - The classic Dracula dark theme
  factory DraculaTokens.standard() => const DraculaTokens._(
    variantName: 'Standard',
    colors: DraculaColors.standard,
    brightness: Brightness.dark,
  );

  /// Create from variant ID
  factory DraculaTokens.fromVariant(String variantId) {
    switch (variantId.toLowerCase()) {
      case 'standard':
      default:
        return DraculaTokens.standard();
    }
  }

  // === Helper method to get colors safely ===
  Color _getColor(String key) {
    return colors[key] ?? colors['foreground']!;
  }

  // === Background Tokens ===
  @override
  Color get bgBase => _getColor('background');

  @override
  Color get bgSecondary => _getColor('currentLine');

  @override
  Color get bgTertiary => _getColor('selection');

  @override
  Color get bgOverlay => _getColor('darkGray');

  // === Text Tokens ===
  @override
  Color get textPrimary => _getColor('foreground');

  @override
  Color get textSecondary => _getColor('comment');

  @override
  Color get textTertiary => _getColor('comment').withValues(alpha: 0.7);

  @override
  Color get textInverse => _getColor('background');

  // === Interactive/Accent Tokens ===
  @override
  Color get accentPrimary => _getColor('purple');

  @override
  Color get accentSecondary => _getColor('pink');

  @override
  Color get accentTertiary => _getColor('cyan');

  // === Semantic State Tokens ===
  @override
  Color get stateSuccess => _getColor('green');

  @override
  Color get stateWarning => _getColor('yellow');

  @override
  Color get stateError => _getColor('red');

  @override
  Color get stateInfo => _getColor('cyan');

  // === Interactive State Tokens ===
  @override
  Color get interactiveHover => _getColor('currentLine');

  @override
  Color get interactivePressed => _getColor('selection');

  @override
  Color get interactiveFocus => _getColor('purple');

  @override
  Color get interactiveDisabled => _getColor('comment');

  // === Border/Outline Tokens ===
  @override
  Color get borderPrimary => _getColor('comment');

  @override
  Color get borderSecondary => _getColor('currentLine');

  @override
  Color get borderFocus => _getColor('purple');

  @override
  Color get borderError => _getColor('red');

  // === Surface Variant Tokens ===
  @override
  Color get surfaceInput => _getColor('currentLine');

  @override
  Color get surfaceSelected => _getColor('selection');

  @override
  Color get surfaceNavigation => _getColor('darkGray');

  /// Get all available Dracula variants
  static List<ThemeVariant> get variants => [
    const ThemeVariant(
      id: 'standard',
      displayName: 'Standard',
      brightness: Brightness.dark,
      description: 'The classic Dracula theme',
    ),
  ];

  /// Legacy access to raw Dracula colors for backward compatibility
  Map<String, Color> get rawColors => colors;

  /// Quick access to popular Dracula colors
  Color get purple => _getColor('purple');
  Color get pink => _getColor('pink');
  Color get cyan => _getColor('cyan');
  Color get green => _getColor('green');
  Color get orange => _getColor('orange');
  Color get red => _getColor('red');
  Color get yellow => _getColor('yellow');
}
