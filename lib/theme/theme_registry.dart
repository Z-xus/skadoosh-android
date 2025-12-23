import 'package:flutter/material.dart';
import 'base/semantic_tokens.dart';
import 'base/theme_family.dart';
import 'families/catppuccin/catppuccin_tokens.dart';
import 'families/dracula/dracula_tokens.dart';
import 'families/nord/nord_tokens.dart';

/// Central registry for all theme families and their variants.
/// This provides a unified interface for accessing all available themes.
class ThemeRegistry {
  static final ThemeRegistry _instance = ThemeRegistry._internal();
  factory ThemeRegistry() => _instance;
  ThemeRegistry._internal();

  /// Get a semantic tokens instance for the given theme configuration
  SemanticTokens getTokens(ThemeConfig config) {
    switch (config.family) {
      case ThemeFamily.catppuccin:
        return CatppuccinTokens.fromVariant(config.variant.id);
      case ThemeFamily.dracula:
        return DraculaTokens.fromVariant(config.variant.id);
      case ThemeFamily.nord:
        return NordTokens.fromVariant(config.variant.id);
    }
  }

  /// Get all variants for a specific theme family
  List<ThemeVariant> getVariantsForFamily(ThemeFamily family) {
    switch (family) {
      case ThemeFamily.catppuccin:
        return CatppuccinTokens.variants;
      case ThemeFamily.dracula:
        return DraculaTokens.variants;
      case ThemeFamily.nord:
        return NordTokens.variants;
    }
  }

  /// Get all available theme families
  List<ThemeFamily> get allFamilies => ThemeFamily.values;

  /// Get all theme configurations across all families
  List<ThemeConfig> get allConfigurations {
    final List<ThemeConfig> configs = [];
    for (final family in allFamilies) {
      final variants = getVariantsForFamily(family);
      for (final variant in variants) {
        configs.add(ThemeConfig(family: family, variant: variant));
      }
    }
    return configs;
  }

  /// Get light theme configurations only
  List<ThemeConfig> get lightConfigurations {
    return allConfigurations
        .where((config) => config.brightness == Brightness.light)
        .toList();
  }

  /// Get dark theme configurations only
  List<ThemeConfig> get darkConfigurations {
    return allConfigurations
        .where((config) => config.brightness == Brightness.dark)
        .toList();
  }

  /// Find a configuration by family and variant ID
  ThemeConfig? findConfiguration(ThemeFamily family, String variantId) {
    try {
      final variants = getVariantsForFamily(family);
      final variant = variants.firstWhere((v) => v.id == variantId);
      return ThemeConfig(family: family, variant: variant);
    } catch (e) {
      return null;
    }
  }

  /// Find a configuration by unique theme ID
  ThemeConfig? findByThemeId(String themeId) {
    try {
      return allConfigurations.firstWhere((config) => config.id == themeId);
    } catch (e) {
      return null;
    }
  }

  /// Get default configuration for light mode (Nord Snow Storm)
  ThemeConfig getDefaultForBrightness(Brightness brightness) {
    switch (brightness) {
      case Brightness.light:
        // Default to Nord Snow Storm for light mode
        return QuickAccess.nordSnowStorm;
      case Brightness.dark:
        // Default to Catppuccin Mocha for dark mode
        return ThemeConfig(
          family: ThemeFamily.catppuccin,
          variant: CatppuccinTokens.variants.firstWhere((v) => v.id == 'mocha'),
        );
    }
  }

  /// Get the default theme configuration (Nord Snow Storm - light theme)
  ThemeConfig get defaultConfiguration =>
      getDefaultForBrightness(Brightness.light);

  /// Migration helper: Map old Catppuccin flavor names to new configurations
  ThemeConfig? migrateFromLegacyFlavor(String flavorName) {
    final migrationMap = {
      'latte': ThemeConfig(
        family: ThemeFamily.catppuccin,
        variant: CatppuccinTokens.variants.firstWhere((v) => v.id == 'latte'),
      ),
      'frappé': ThemeConfig(
        family: ThemeFamily.catppuccin,
        variant: CatppuccinTokens.variants.firstWhere((v) => v.id == 'frappe'),
      ),
      'frappe': ThemeConfig(
        family: ThemeFamily.catppuccin,
        variant: CatppuccinTokens.variants.firstWhere((v) => v.id == 'frappe'),
      ),
      'macchiato': ThemeConfig(
        family: ThemeFamily.catppuccin,
        variant: CatppuccinTokens.variants.firstWhere(
          (v) => v.id == 'macchiato',
        ),
      ),
      'mocha': ThemeConfig(
        family: ThemeFamily.catppuccin,
        variant: CatppuccinTokens.variants.firstWhere((v) => v.id == 'mocha'),
      ),
    };

    return migrationMap[flavorName.toLowerCase()];
  }

  /// Get theme configurations grouped by family for UI display
  Map<ThemeFamily, List<ThemeVariant>> get familyVariantMap {
    final Map<ThemeFamily, List<ThemeVariant>> map = {};
    for (final family in allFamilies) {
      map[family] = getVariantsForFamily(family);
    }
    return map;
  }
}

/// Quick access to popular theme configurations
class QuickAccess {
  static ThemeConfig get catppuccinMocha => ThemeConfig(
    family: ThemeFamily.catppuccin,
    variant: CatppuccinTokens.variants.firstWhere((v) => v.id == 'mocha'),
  );

  static ThemeConfig get catppuccinLatte => ThemeConfig(
    family: ThemeFamily.catppuccin,
    variant: CatppuccinTokens.variants.firstWhere((v) => v.id == 'latte'),
  );

  static ThemeConfig get draculaStandard => ThemeConfig(
    family: ThemeFamily.dracula,
    variant: DraculaTokens.variants.firstWhere((v) => v.id == 'standard'),
  );

  static ThemeConfig get nordPolarNight => ThemeConfig(
    family: ThemeFamily.nord,
    variant: NordTokens.variants.firstWhere((v) => v.id == 'polar_night'),
  );

  static ThemeConfig get nordSnowStorm => ThemeConfig(
    family: ThemeFamily.nord,
    variant: NordTokens.variants.firstWhere((v) => v.id == 'snow_storm'),
  );
}

/// Theme mode enumeration for manual theme selection
enum AppThemeMode {
  /// Always use light theme variants
  light,

  /// Always use dark theme variants
  dark;

  /// Get human-readable display name
  String get displayName {
    switch (this) {
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
    }
  }

  /// Get description for UI
  String get description {
    switch (this) {
      case AppThemeMode.light:
        return 'Always use light themes';
      case AppThemeMode.dark:
        return 'Always use dark themes';
    }
  }
}
