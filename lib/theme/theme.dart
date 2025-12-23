import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'design_tokens.dart';
import 'catppuccin_colors.dart';

/// Enhanced theme system using beautiful Catppuccin color palettes
class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  /// Get theme data for a specific Catppuccin flavor
  static ThemeData getTheme(String flavorName) {
    final palette = CatppuccinColors.getPalette(flavorName);
    final colorScheme = palette.toColorScheme();

    // Set system UI overlay style based on theme
    _setSystemUIOverlayStyle(palette);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: palette.brightness,

      // Typography with proper contrast
      textTheme: _buildTextTheme(palette),

      // Enhanced component themes
      appBarTheme: _buildAppBarTheme(palette),
      cardTheme: _buildCardTheme(palette),
      elevatedButtonTheme: _buildElevatedButtonTheme(palette),
      filledButtonTheme: _buildFilledButtonTheme(palette),
      outlinedButtonTheme: _buildOutlinedButtonTheme(palette),
      floatingActionButtonTheme: _buildFABTheme(palette),
      bottomNavigationBarTheme: _buildBottomNavTheme(palette),
      navigationBarTheme: _buildNavigationBarTheme(palette),
      listTileTheme: _buildListTileTheme(palette),
      inputDecorationTheme: _buildInputTheme(palette),
      dividerTheme: _buildDividerTheme(palette),
      scaffoldBackgroundColor: palette.base,

      // Page transitions
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  /// Set system UI overlay style for proper status bar
  static void _setSystemUIOverlayStyle(CatppuccinPalette palette) {
    final overlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: palette.brightness == Brightness.dark
          ? Brightness.light
          : Brightness.dark,
      statusBarBrightness: palette.brightness,
      systemNavigationBarColor: palette.base,
      systemNavigationBarIconBrightness: palette.brightness == Brightness.dark
          ? Brightness.light
          : Brightness.dark,
    );

    SystemChrome.setSystemUIOverlayStyle(overlayStyle);
  }

  /// Build text theme with proper contrast ratios
  static TextTheme _buildTextTheme(CatppuccinPalette palette) {
    return TextTheme(
      // Display styles - for large, dramatic text
      displayLarge: TextStyle(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        letterSpacing: DesignTokens.letterSpacingTight,
        height: DesignTokens.lineHeightTight,
        color: palette.text,
      ),
      displayMedium: TextStyle(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        letterSpacing: DesignTokens.letterSpacingNormal,
        height: DesignTokens.lineHeightTight,
        color: palette.text,
      ),
      displaySmall: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        letterSpacing: DesignTokens.letterSpacingNormal,
        height: DesignTokens.lineHeightTight,
        color: palette.text,
      ),

      // Headline styles - for page titles and section headers
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        letterSpacing: DesignTokens.letterSpacingNormal,
        height: DesignTokens.lineHeightTight,
        color: palette.text,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: DesignTokens.letterSpacingNormal,
        height: DesignTokens.lineHeightTight,
        color: palette.text,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: DesignTokens.letterSpacingNormal,
        height: DesignTokens.lineHeightNormal,
        color: palette.text,
      ),

      // Title styles - for card titles and list items
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        letterSpacing: DesignTokens.letterSpacingNormal,
        height: DesignTokens.lineHeightNormal,
        color: palette.text,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: DesignTokens.letterSpacingLoose,
        height: DesignTokens.lineHeightNormal,
        color: palette.text,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: DesignTokens.letterSpacingLoose,
        height: DesignTokens.lineHeightNormal,
        color: palette.text,
      ),

      // Label styles - for buttons and small text
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: DesignTokens.letterSpacingLoose,
        height: DesignTokens.lineHeightNormal,
        color: palette.text,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: DesignTokens.letterSpacingWide,
        height: DesignTokens.lineHeightNormal,
        color: palette.subtext0,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: DesignTokens.letterSpacingWide,
        height: DesignTokens.lineHeightNormal,
        color: palette.subtext0,
      ),

      // Body styles - for main content text
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: DesignTokens.letterSpacingLoose,
        height: DesignTokens.lineHeightLoose,
        color: palette.text,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: DesignTokens.letterSpacingLoose,
        height: DesignTokens.lineHeightNormal,
        color: palette.subtext1,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: DesignTokens.letterSpacingNormal,
        height: DesignTokens.lineHeightNormal,
        color: palette.subtext0,
      ),
    );
  }

  /// Build app bar theme
  static AppBarTheme _buildAppBarTheme(CatppuccinPalette palette) {
    return AppBarTheme(
      elevation: DesignTokens.elevationNone,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      foregroundColor: palette.text,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: palette.text,
      ),
      iconTheme: IconThemeData(
        color: palette.text,
        size: DesignTokens.iconSizeL,
      ),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: palette.brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
      ),
    );
  }

  /// Build card theme with proper Catppuccin styling
  static CardThemeData _buildCardTheme(CatppuccinPalette palette) {
    return CardThemeData(
      elevation: DesignTokens.elevationS,
      color: palette.surface0,
      shadowColor: palette.crust.withValues(alpha: 0.1),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
      ),
    );
  }

  /// Build elevated button theme
  static ElevatedButtonThemeData _buildElevatedButtonTheme(
    CatppuccinPalette palette,
  ) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: DesignTokens.elevationS,
        backgroundColor: palette.surface1,
        foregroundColor: palette.text,
        shadowColor: Colors.transparent,
        padding: DesignTokens.spaceM,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusXL),
        ),
        minimumSize: const Size(
          DesignTokens.touchTargetMinSize,
          DesignTokens.touchTargetMinSize,
        ),
      ),
    );
  }

  /// Build filled button theme
  static FilledButtonThemeData _buildFilledButtonTheme(
    CatppuccinPalette palette,
  ) {
    return FilledButtonThemeData(
      style: FilledButton.styleFrom(
        elevation: DesignTokens.elevationNone,
        backgroundColor: palette.mauve,
        foregroundColor: palette.base,
        padding: DesignTokens.spaceM,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusXL),
        ),
        minimumSize: const Size(
          DesignTokens.touchTargetMinSize,
          DesignTokens.touchTargetMinSize,
        ),
      ),
    );
  }

  /// Build outlined button theme
  static OutlinedButtonThemeData _buildOutlinedButtonTheme(
    CatppuccinPalette palette,
  ) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: palette.mauve,
        side: BorderSide(color: palette.overlay0),
        padding: DesignTokens.spaceM,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusXL),
        ),
        minimumSize: const Size(
          DesignTokens.touchTargetMinSize,
          DesignTokens.touchTargetMinSize,
        ),
      ),
    );
  }

  /// Build floating action button theme
  static FloatingActionButtonThemeData _buildFABTheme(
    CatppuccinPalette palette,
  ) {
    return FloatingActionButtonThemeData(
      elevation: DesignTokens.elevationL,
      backgroundColor: palette.mauve,
      foregroundColor: palette.base,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusXL),
      ),
    );
  }

  /// Build bottom navigation theme
  static BottomNavigationBarThemeData _buildBottomNavTheme(
    CatppuccinPalette palette,
  ) {
    return BottomNavigationBarThemeData(
      backgroundColor: palette.mantle,
      selectedItemColor: palette.mauve,
      unselectedItemColor: palette.subtext0,
      type: BottomNavigationBarType.fixed,
      elevation: DesignTokens.elevationM,
    );
  }

  /// Build navigation bar theme (Material 3)
  static NavigationBarThemeData _buildNavigationBarTheme(
    CatppuccinPalette palette,
  ) {
    return NavigationBarThemeData(
      backgroundColor: palette.mantle,
      indicatorColor: palette.surface2,
      surfaceTintColor: Colors.transparent,
      elevation: DesignTokens.elevationM,
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: palette.subtext0,
        ),
      ),
      iconTheme: WidgetStatePropertyAll(
        IconThemeData(color: palette.subtext0, size: DesignTokens.iconSizeL),
      ),
    );
  }

  /// Build list tile theme
  static ListTileThemeData _buildListTileTheme(CatppuccinPalette palette) {
    return ListTileThemeData(
      contentPadding: DesignTokens.spaceHorizontalM,
      minVerticalPadding: DesignTokens.spaceS.top,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
      ),
      tileColor: Colors.transparent,
      selectedTileColor: palette.surface0,
      textColor: palette.text,
      iconColor: palette.subtext0,
    );
  }

  /// Build input decoration theme
  static InputDecorationTheme _buildInputTheme(CatppuccinPalette palette) {
    return InputDecorationTheme(
      filled: true,
      fillColor: palette.surface0,
      contentPadding: DesignTokens.cardPadding,

      // Border styles
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        borderSide: BorderSide(color: palette.overlay0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        borderSide: BorderSide(color: palette.overlay0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        borderSide: BorderSide(color: palette.mauve, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        borderSide: BorderSide(color: palette.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        borderSide: BorderSide(color: palette.red, width: 2),
      ),

      // Label and hint styling
      labelStyle: TextStyle(
        color: palette.subtext0,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      floatingLabelStyle: TextStyle(
        color: palette.mauve,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      hintStyle: TextStyle(
        color: palette.subtext0.withValues(alpha: 0.7),
        fontSize: 16,
      ),
      helperStyle: TextStyle(color: palette.subtext0, fontSize: 12),
      errorStyle: TextStyle(color: palette.red, fontSize: 12),
    );
  }

  /// Build divider theme
  static DividerThemeData _buildDividerTheme(CatppuccinPalette palette) {
    return DividerThemeData(thickness: 1, space: 1, color: palette.overlay0);
  }

  /// Get all available theme flavors
  static List<String> get availableFlavors => [
    'Latte',
    'Frappé',
    'Macchiato',
    'Mocha',
  ];

  /// Default theme (Mocha)
  static ThemeData get defaultTheme => getTheme('Mocha');
}

/// Legacy compatibility - keeping for existing code that expects these names
ThemeData get lightMode => AppTheme.getTheme('Latte');
ThemeData get darkMode => AppTheme.getTheme('Mocha');
