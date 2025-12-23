import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'base/theme_family.dart';
import 'base/semantic_tokens.dart';
import 'theme_registry.dart' as registry;

/// Enhanced theme provider with support for multiple theme families and system sync
class ThemeProvider extends ChangeNotifier {
  static const String _themeConfigKey = 'theme_config_v2';
  static const String _themeModeKey = 'theme_mode_v2';

  // Legacy keys for migration
  static const String _legacyFlavorKey = 'catppuccin_flavor';
  static const String _legacyBoolKey = 'theme_mode';

  late final registry.ThemeRegistry _registry;
  late registry.AppThemeMode _mode;
  late ThemeConfig _selectedConfig;
  bool _initialized = false;

  ThemeProvider() {
    _registry = registry.ThemeRegistry();
    _mode = registry.AppThemeMode.system; // Default to system sync
    _selectedConfig = _registry.defaultConfiguration; // Fallback
  }

  // === Public Getters ===

  /// Current theme mode (system, light, dark)
  registry.AppThemeMode get mode => _mode;

  /// Currently selected theme configuration
  ThemeConfig get selectedConfig => _selectedConfig;

  /// Get the current theme data based on mode and selection
  ThemeData get currentTheme {
    final config = _getEffectiveConfig();
    final tokens = _registry.getTokens(config);
    return _buildThemeData(tokens);
  }

  /// Get current semantic tokens
  SemanticTokens get currentTokens {
    final config = _getEffectiveConfig();
    return _registry.getTokens(config);
  }

  /// Check if theme is initialized
  bool get isInitialized => _initialized;

  /// Get all available theme families
  List<ThemeFamily> get availableFamilies => _registry.allFamilies;

  /// Get variants for the currently selected family
  List<ThemeVariant> get availableVariants =>
      _registry.getVariantsForFamily(_selectedConfig.family);

  /// Get all variants for a specific family
  List<ThemeVariant> getVariantsForFamily(ThemeFamily family) =>
      _registry.getVariantsForFamily(family);

  // === Theme Mode Management ===

  /// Set theme mode (system, light, dark)
  Future<void> setMode(registry.AppThemeMode mode) async {
    if (_mode == mode) return;

    _mode = mode;
    await _savePreferences();
    notifyListeners();
  }

  /// Set theme family (preserves variant if possible, otherwise uses default)
  Future<void> setFamily(ThemeFamily family) async {
    if (_selectedConfig.family == family) return;

    final variants = _registry.getVariantsForFamily(family);

    // Try to preserve similar brightness, otherwise use first variant
    ThemeVariant newVariant = variants.first;
    try {
      newVariant = variants.firstWhere(
        (v) => v.brightness == _selectedConfig.brightness,
      );
    } catch (e) {
      // If no matching brightness found, stick with first variant
    }

    _selectedConfig = ThemeConfig(family: family, variant: newVariant);
    await _savePreferences();
    notifyListeners();
  }

  /// Set specific variant within current family
  Future<void> setVariant(ThemeVariant variant) async {
    if (_selectedConfig.variant == variant) return;

    _selectedConfig = ThemeConfig(
      family: _selectedConfig.family,
      variant: variant,
    );
    await _savePreferences();
    notifyListeners();
  }

  /// Set complete theme configuration
  Future<void> setConfiguration(ThemeConfig config) async {
    if (_selectedConfig == config) return;

    _selectedConfig = config;
    await _savePreferences();
    notifyListeners();
  }

  // === Convenience Methods ===

  /// Quick switch to light mode with best available light variant
  Future<void> setLightMode() async {
    await setMode(registry.AppThemeMode.light);
  }

  /// Quick switch to dark mode with best available dark variant
  Future<void> setDarkMode() async {
    await setMode(registry.AppThemeMode.dark);
  }

  /// Toggle between light and dark modes
  Future<void> toggleLightDark() async {
    switch (_mode) {
      case registry.AppThemeMode.light:
        await setMode(registry.AppThemeMode.dark);
        break;
      case registry.AppThemeMode.dark:
        await setMode(registry.AppThemeMode.light);
        break;
      case registry.AppThemeMode.system:
        // When in system mode, toggle to explicit mode opposite of current system
        final brightness =
            WidgetsBinding.instance.platformDispatcher.platformBrightness;
        await setMode(
          brightness == Brightness.light
              ? registry.AppThemeMode.dark
              : registry.AppThemeMode.light,
        );
        break;
    }
  }

  /// Enable system sync mode
  Future<void> enableSystemSync() async {
    await setMode(registry.AppThemeMode.system);
  }

  // === Initialization and Persistence ===

  /// Initialize theme from saved preferences
  Future<void> initialize() async {
    if (_initialized) return;

    final prefs = await SharedPreferences.getInstance();

    // Load mode
    final savedMode = prefs.getString(_themeModeKey);
    if (savedMode != null) {
      _mode = registry.AppThemeMode.values.firstWhere(
        (mode) => mode.name == savedMode,
        orElse: () => registry.AppThemeMode.system,
      );
    }

    // Load configuration
    final savedConfig = prefs.getString(_themeConfigKey);
    if (savedConfig != null) {
      _selectedConfig =
          _parseConfigFromString(savedConfig) ?? _registry.defaultConfiguration;
    } else {
      // Check for migration from legacy preferences
      await _performMigration(prefs);
    }

    _initialized = true;
    notifyListeners();
  }

  /// Save current preferences
  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, _mode.name);
    await prefs.setString(_themeConfigKey, _selectedConfig.id);
  }

  /// Parse theme configuration from stored string
  ThemeConfig? _parseConfigFromString(String configString) {
    try {
      return _registry.findByThemeId(configString);
    } catch (e) {
      return null;
    }
  }

  /// Perform silent migration from legacy preferences
  Future<void> _performMigration(SharedPreferences prefs) async {
    // Check for old Catppuccin flavor preference
    final oldFlavor = prefs.getString(_legacyFlavorKey);
    if (oldFlavor != null) {
      final migratedConfig = _registry.migrateFromLegacyFlavor(oldFlavor);
      if (migratedConfig != null) {
        _selectedConfig = migratedConfig;
        await prefs.remove(_legacyFlavorKey); // Clean up old preference
      }
    }

    // Check for old boolean theme preference
    final oldIsDark = prefs.getBool(_legacyBoolKey);
    if (oldIsDark != null) {
      _selectedConfig = _registry.getDefaultForBrightness(
        oldIsDark ? Brightness.dark : Brightness.light,
      );
      await prefs.remove(_legacyBoolKey); // Clean up old preference
    }

    // Save migrated preferences
    await _savePreferences();
  }

  /// Get effective configuration considering current mode
  ThemeConfig _getEffectiveConfig() {
    switch (_mode) {
      case registry.AppThemeMode.system:
        // Follow system brightness, use selected family
        final systemBrightness =
            WidgetsBinding.instance.platformDispatcher.platformBrightness;
        return _getConfigForBrightness(systemBrightness);

      case registry.AppThemeMode.light:
        // Force light variant of selected family
        return _getConfigForBrightness(Brightness.light);

      case registry.AppThemeMode.dark:
        // Force dark variant of selected family
        return _getConfigForBrightness(Brightness.dark);
    }
  }

  /// Get configuration for specific brightness, preserving family selection
  ThemeConfig _getConfigForBrightness(Brightness brightness) {
    final familyVariants = _registry.getVariantsForFamily(
      _selectedConfig.family,
    );

    // Try to find a variant with matching brightness
    try {
      final matchingVariant = familyVariants.firstWhere(
        (variant) => variant.brightness == brightness,
      );
      return ThemeConfig(
        family: _selectedConfig.family,
        variant: matchingVariant,
      );
    } catch (e) {
      // If family doesn't have variants for this brightness, fall back to defaults
      return _registry.getDefaultForBrightness(brightness);
    }
  }

  /// Build ThemeData from semantic tokens
  ThemeData _buildThemeData(SemanticTokens tokens) {
    final colorScheme = tokens.toColorScheme();

    // Set system UI overlay style
    _setSystemUIOverlayStyle(tokens);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: tokens.brightness,
      scaffoldBackgroundColor: tokens.bgBase,

      // Use existing theme building logic with semantic tokens
      textTheme: _buildTextTheme(tokens),
      appBarTheme: _buildAppBarTheme(tokens),
      cardTheme: _buildCardTheme(tokens),
      elevatedButtonTheme: _buildElevatedButtonTheme(tokens),
      filledButtonTheme: _buildFilledButtonTheme(tokens),
      outlinedButtonTheme: _buildOutlinedButtonTheme(tokens),
      floatingActionButtonTheme: _buildFABTheme(tokens),
      inputDecorationTheme: _buildInputTheme(tokens),
      listTileTheme: _buildListTileTheme(tokens),
      dividerTheme: _buildDividerTheme(tokens),

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  /// Set system UI overlay style
  void _setSystemUIOverlayStyle(SemanticTokens tokens) {
    final overlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: tokens.brightness == Brightness.dark
          ? Brightness.light
          : Brightness.dark,
      statusBarBrightness: tokens.brightness,
      systemNavigationBarColor: tokens.bgBase,
      systemNavigationBarIconBrightness: tokens.brightness == Brightness.dark
          ? Brightness.light
          : Brightness.dark,
    );

    SystemChrome.setSystemUIOverlayStyle(overlayStyle);
  }

  // === Theme Building Methods (using semantic tokens) ===

  TextTheme _buildTextTheme(SemanticTokens tokens) {
    return TextTheme(
      headlineLarge: TextStyle(
        color: tokens.textPrimary,
        fontSize: 32,
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: TextStyle(
        color: tokens.textPrimary,
        fontSize: 28,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: TextStyle(
        color: tokens.textPrimary,
        fontSize: 24,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(
        color: tokens.textPrimary,
        fontSize: 22,
        fontWeight: FontWeight.w500,
      ),
      titleMedium: TextStyle(
        color: tokens.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      titleSmall: TextStyle(
        color: tokens.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: TextStyle(
        color: tokens.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: TextStyle(
        color: tokens.textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      bodySmall: TextStyle(
        color: tokens.textTertiary,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
      labelLarge: TextStyle(
        color: tokens.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      labelMedium: TextStyle(
        color: tokens.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: TextStyle(
        color: tokens.textTertiary,
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  AppBarTheme _buildAppBarTheme(SemanticTokens tokens) {
    return AppBarTheme(
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

  CardThemeData _buildCardTheme(SemanticTokens tokens) {
    return CardThemeData(
      color: tokens.bgSecondary,
      shadowColor: tokens.bgBase.withValues(alpha: 0.1),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  ElevatedButtonThemeData _buildElevatedButtonTheme(SemanticTokens tokens) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: tokens.bgSecondary,
        foregroundColor: tokens.textPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  FilledButtonThemeData _buildFilledButtonTheme(SemanticTokens tokens) {
    return FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: tokens.accentPrimary,
        foregroundColor: tokens.textInverse,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  OutlinedButtonThemeData _buildOutlinedButtonTheme(SemanticTokens tokens) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: tokens.accentPrimary,
        side: BorderSide(color: tokens.borderPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  FloatingActionButtonThemeData _buildFABTheme(SemanticTokens tokens) {
    return FloatingActionButtonThemeData(
      backgroundColor: tokens.accentPrimary,
      foregroundColor: tokens.textInverse,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  InputDecorationTheme _buildInputTheme(SemanticTokens tokens) {
    return InputDecorationTheme(
      filled: true,
      fillColor: tokens.surfaceInput,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: tokens.borderPrimary),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: tokens.borderFocus, width: 2),
      ),
      labelStyle: TextStyle(color: tokens.textSecondary),
      hintStyle: TextStyle(color: tokens.textTertiary),
    );
  }

  ListTileThemeData _buildListTileTheme(SemanticTokens tokens) {
    return ListTileThemeData(
      textColor: tokens.textPrimary,
      iconColor: tokens.textSecondary,
      selectedTileColor: tokens.surfaceSelected,
    );
  }

  DividerThemeData _buildDividerTheme(SemanticTokens tokens) {
    return DividerThemeData(color: tokens.borderSecondary, thickness: 1);
  }

  // === Legacy Compatibility ===

  /// Legacy getter for backward compatibility
  bool get isDarkMode => _getEffectiveConfig().brightness == Brightness.dark;

  /// Legacy getter for backward compatibility
  bool get isLightMode => _getEffectiveConfig().brightness == Brightness.light;

  /// Legacy method for backward compatibility
  String get currentFlavor => _selectedConfig.variant.id;

  /// Legacy method for backward compatibility
  List<String> get availableFlavors =>
      availableVariants.map((v) => v.id).toList();
}
