import 'package:flutter/material.dart';
import 'theme.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeData _currentTheme = lightMode;

  ThemeData get currentTheme => _currentTheme;

  bool get isDarkMode => _currentTheme.brightness == Brightness.dark;

  set themeData(ThemeData theme) {
    _currentTheme = theme;
    notifyListeners();
  }

  void toggleTheme() {
    if (_currentTheme.brightness == Brightness.light) {
      _currentTheme = darkMode;
    } else {
      _currentTheme = lightMode;
    }
    notifyListeners();
  }
}
