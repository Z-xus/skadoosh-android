import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';

/// Enhanced theme provider supporting all 4 beautiful Catppuccin flavors
class ThemeProvider extends ChangeNotifier {
  String _currentFlavor = 'Mocha'; // Default to dark Mocha
  static const String _flavorKey = 'catppuccin_flavor';

  /// Get current Catppuccin flavor name
  String get currentFlavor => _currentFlavor;

  /// Get current theme data based on selected flavor
  ThemeData get currentTheme => AppTheme.getTheme(_currentFlavor);

  /// Check if current theme is dark
  bool get isDarkMode =>
      _currentFlavor == 'Mocha' || _currentFlavor == 'Macchiato';

  /// Check if current theme is light
  bool get isLightMode =>
      _currentFlavor == 'Latte' || _currentFlavor == 'Frappé';

  /// Get all available Catppuccin flavors
  List<String> get availableFlavors => AppTheme.availableFlavors;

  /// Get flavor display information
  Map<String, dynamic> getFlavorInfo(String flavor) {
    final info = {
      'Latte': {
        'name': 'Latte ☀️',
        'description': 'Light & creamy',
        'brightness': 'Light',
        'isDark': false,
      },
      'Frappé': {
        'name': 'Frappé 🌅',
        'description': 'Soft morning vibes',
        'brightness': 'Light',
        'isDark': false,
      },
      'Macchiato': {
        'name': 'Macchiato 🌙',
        'description': 'Cozy evening mood',
        'brightness': 'Dark',
        'isDark': true,
      },
      'Mocha': {
        'name': 'Mocha 🌃',
        'description': 'Deep & rich',
        'brightness': 'Dark',
        'isDark': true,
      },
    };
    return info[flavor] ?? info['Mocha']!;
  }

  /// Initialize theme from saved preferences
  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedFlavor = prefs.getString(_flavorKey);

    // Validate saved flavor or use default
    if (savedFlavor != null &&
        AppTheme.availableFlavors.contains(savedFlavor)) {
      _currentFlavor = savedFlavor;
    } else {
      // Default to Mocha (dark) or migrate from old boolean preference
      final oldIsDark = prefs.getBool('theme_mode');
      _currentFlavor = (oldIsDark == true) ? 'Mocha' : 'Latte';

      // Save the migrated preference
      await prefs.setString(_flavorKey, _currentFlavor);
      // Remove old preference
      await prefs.remove('theme_mode');
    }

    notifyListeners();
  }

  /// Set specific Catppuccin flavor
  Future<void> setFlavor(String flavor) async {
    if (!AppTheme.availableFlavors.contains(flavor)) {
      throw ArgumentError('Invalid Catppuccin flavor: $flavor');
    }

    _currentFlavor = flavor;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_flavorKey, flavor);

    notifyListeners();
  }

  /// Legacy method: Toggle between light (Latte) and dark (Mocha)
  /// Kept for backward compatibility
  Future<void> toggleTheme() async {
    final newFlavor = isDarkMode ? 'Latte' : 'Mocha';
    await setFlavor(newFlavor);
  }

  /// Cycle through all 4 Catppuccin flavors
  Future<void> cycleFlavors() async {
    final currentIndex = AppTheme.availableFlavors.indexOf(_currentFlavor);
    final nextIndex = (currentIndex + 1) % AppTheme.availableFlavors.length;
    await setFlavor(AppTheme.availableFlavors[nextIndex]);
  }

  /// Quick switch to light theme (defaults to Latte)
  Future<void> setLightTheme() async {
    await setFlavor('Latte');
  }

  /// Quick switch to dark theme (defaults to Mocha)
  Future<void> setDarkTheme() async {
    await setFlavor('Mocha');
  }

  /// Legacy compatibility - set theme data directly
  /// Automatically detects closest Catppuccin flavor
  set themeData(ThemeData theme) {
    // Try to map brightness to appropriate flavor
    if (theme.brightness == Brightness.dark) {
      _currentFlavor = 'Mocha';
    } else {
      _currentFlavor = 'Latte';
    }
    notifyListeners();
  }
}
