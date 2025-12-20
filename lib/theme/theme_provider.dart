import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeData _currentTheme = lightMode;
  static const String _themeKey = 'theme_mode';

  ThemeData get currentTheme => _currentTheme;

  bool get isDarkMode => _currentTheme.brightness == Brightness.dark;

  set themeData(ThemeData theme) {
    _currentTheme = theme;
    notifyListeners();
  }

  // Initialize theme from saved preferences
  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_themeKey) ?? false;
    _currentTheme = isDark ? darkMode : lightMode;
    notifyListeners();
  }

  // Save theme preference and toggle
  Future<void> toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();

    if (_currentTheme.brightness == Brightness.light) {
      _currentTheme = darkMode;
      await prefs.setBool(_themeKey, true);
    } else {
      _currentTheme = lightMode;
      await prefs.setBool(_themeKey, false);
    }
    notifyListeners();
  }
}
