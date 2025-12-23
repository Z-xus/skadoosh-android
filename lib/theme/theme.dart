import 'package:flutter/material.dart';
import 'base/semantic_tokens.dart';
import 'base/theme_family.dart';
import 'theme_registry.dart';

/// Enhanced theme system using semantic tokens and supporting multiple theme families.
///
/// This system provides:
/// - Multiple theme families (Catppuccin, Dracula, Nord)
/// - Semantic token mapping for consistent UI
/// - System sync (auto) mode
/// - Silent migration from legacy themes
/// - Hierarchical theme selection (Mode → Family → Variant)
class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  /// Get theme data for a specific theme configuration
  static ThemeData getTheme(ThemeConfig config) {
    final registry = ThemeRegistry();
    final tokens = registry.getTokens(config);
    return _buildThemeData(tokens);
  }

  /// Get theme data by family and variant IDs
  static ThemeData getThemeByIds(String familyId, String variantId) {
    final registry = ThemeRegistry();

    // Find the family
    final family = ThemeFamily.values.firstWhere(
      (f) => f.id == familyId,
      orElse: () => ThemeFamily.catppuccin,
    );

    // Find the configuration
    final config = registry.findConfiguration(family, variantId);
    if (config != null) {
      return getTheme(config);
    }

    // Fallback to default
    return defaultTheme;
  }

  /// Build ThemeData from semantic tokens
  static ThemeData _buildThemeData(SemanticTokens tokens) {
    final colorScheme = tokens.toColorScheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: tokens.brightness,
      scaffoldBackgroundColor: tokens.bgBase,

      // Typography with semantic tokens
      textTheme: _buildTextTheme(tokens),

      // Enhanced component themes using semantic tokens
      appBarTheme: _buildAppBarTheme(tokens),
      cardTheme: _buildCardTheme(tokens),
      elevatedButtonTheme: _buildElevatedButtonTheme(tokens),
      filledButtonTheme: _buildFilledButtonTheme(tokens),
      outlinedButtonTheme: _buildOutlinedButtonTheme(tokens),
      floatingActionButtonTheme: _buildFABTheme(tokens),
      bottomNavigationBarTheme: _buildBottomNavTheme(tokens),
      navigationBarTheme: _buildNavigationBarTheme(tokens),
      listTileTheme: _buildListTileTheme(tokens),
      inputDecorationTheme: _buildInputTheme(tokens),
      dividerTheme: _buildDividerTheme(tokens),

      // Page transitions
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  // === Theme Building Methods ===

  static TextTheme _buildTextTheme(SemanticTokens tokens) {
    return TextTheme(
      // Display styles - for large, dramatic text
      displayLarge: TextStyle(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        color: tokens.textPrimary,
      ),
      displayMedium: TextStyle(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        color: tokens.textPrimary,
      ),
      displaySmall: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        color: tokens.textPrimary,
      ),

      // Headline styles - for page titles and section headers
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: tokens.textPrimary,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: tokens.textPrimary,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: tokens.textPrimary,
      ),

      // Title styles - for card titles and list items
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        color: tokens.textPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: tokens.textPrimary,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: tokens.textPrimary,
      ),

      // Body styles - for main content text
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: tokens.textPrimary,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: tokens.textSecondary,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: tokens.textTertiary,
      ),

      // Label styles - for buttons and small text
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: tokens.textPrimary,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: tokens.textSecondary,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: tokens.textTertiary,
      ),
    );
  }

  static AppBarTheme _buildAppBarTheme(SemanticTokens tokens) {
    return AppBarTheme(
      elevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      foregroundColor: tokens.textPrimary,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: tokens.textPrimary,
      ),
      iconTheme: IconThemeData(color: tokens.textPrimary, size: 24),
    );
  }

  static CardThemeData _buildCardTheme(SemanticTokens tokens) {
    return CardThemeData(
      elevation: 1,
      color: tokens.bgSecondary,
      shadowColor: tokens.bgBase.withValues(alpha: 0.1),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  static ElevatedButtonThemeData _buildElevatedButtonTheme(
    SemanticTokens tokens,
  ) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 1,
        backgroundColor: tokens.bgSecondary,
        foregroundColor: tokens.textPrimary,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        minimumSize: const Size(44, 44),
      ),
    );
  }

  static FilledButtonThemeData _buildFilledButtonTheme(SemanticTokens tokens) {
    return FilledButtonThemeData(
      style: FilledButton.styleFrom(
        elevation: 0,
        backgroundColor: tokens.accentPrimary,
        foregroundColor: tokens.textInverse,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        minimumSize: const Size(44, 44),
      ),
    );
  }

  static OutlinedButtonThemeData _buildOutlinedButtonTheme(
    SemanticTokens tokens,
  ) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: tokens.accentPrimary,
        side: BorderSide(color: tokens.borderPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        minimumSize: const Size(44, 44),
      ),
    );
  }

  static FloatingActionButtonThemeData _buildFABTheme(SemanticTokens tokens) {
    return FloatingActionButtonThemeData(
      elevation: 4,
      backgroundColor: tokens.accentPrimary,
      foregroundColor: tokens.textInverse,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  static BottomNavigationBarThemeData _buildBottomNavTheme(
    SemanticTokens tokens,
  ) {
    return BottomNavigationBarThemeData(
      backgroundColor: tokens.surfaceNavigation,
      selectedItemColor: tokens.accentPrimary,
      unselectedItemColor: tokens.textSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 2,
    );
  }

  static NavigationBarThemeData _buildNavigationBarTheme(
    SemanticTokens tokens,
  ) {
    return NavigationBarThemeData(
      backgroundColor: tokens.surfaceNavigation,
      indicatorColor: tokens.surfaceSelected,
      surfaceTintColor: Colors.transparent,
      elevation: 2,
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: tokens.textSecondary,
        ),
      ),
      iconTheme: WidgetStatePropertyAll(
        IconThemeData(color: tokens.textSecondary, size: 24),
      ),
    );
  }

  static ListTileThemeData _buildListTileTheme(SemanticTokens tokens) {
    return ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      minVerticalPadding: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      tileColor: Colors.transparent,
      selectedTileColor: tokens.surfaceSelected,
      textColor: tokens.textPrimary,
      iconColor: tokens.textSecondary,
    );
  }

  static InputDecorationTheme _buildInputTheme(SemanticTokens tokens) {
    return InputDecorationTheme(
      filled: true,
      fillColor: tokens.surfaceInput,
      contentPadding: const EdgeInsets.all(16),

      // Border styles
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: tokens.borderPrimary),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: tokens.borderPrimary),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: tokens.borderFocus, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: tokens.borderError),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: tokens.borderError, width: 2),
      ),

      // Label and hint styling
      labelStyle: TextStyle(
        color: tokens.textSecondary,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      floatingLabelStyle: TextStyle(
        color: tokens.accentPrimary,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      hintStyle: TextStyle(color: tokens.textTertiary, fontSize: 16),
      helperStyle: TextStyle(color: tokens.textSecondary, fontSize: 12),
      errorStyle: TextStyle(color: tokens.stateError, fontSize: 12),
    );
  }

  static DividerThemeData _buildDividerTheme(SemanticTokens tokens) {
    return DividerThemeData(
      thickness: 1,
      space: 1,
      color: tokens.borderSecondary,
    );
  }

  // === Public API ===

  /// Get all available theme families
  static List<ThemeFamily> get availableFamilies => ThemeFamily.values;

  /// Get all available theme configurations
  static List<ThemeConfig> get availableConfigurations {
    final registry = ThemeRegistry();
    return registry.allConfigurations;
  }

  /// Default theme (Catppuccin Mocha for app identity preservation)
  static ThemeData get defaultTheme => getTheme(QuickAccess.catppuccinMocha);

  /// Quick access themes
  static ThemeData get catppuccinMocha => getTheme(QuickAccess.catppuccinMocha);
  static ThemeData get catppuccinLatte => getTheme(QuickAccess.catppuccinLatte);
  static ThemeData get draculaStandard => getTheme(QuickAccess.draculaStandard);
  static ThemeData get nordPolarNight => getTheme(QuickAccess.nordPolarNight);
  static ThemeData get nordSnowStorm => getTheme(QuickAccess.nordSnowStorm);
}

/// Legacy compatibility - keeping for existing code that expects these names
/// These will map to Catppuccin themes to preserve app identity
ThemeData get lightMode => AppTheme.catppuccinLatte;
ThemeData get darkMode => AppTheme.catppuccinMocha;
