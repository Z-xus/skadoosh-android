import 'package:flutter/material.dart';

ThemeData lightMode = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: ColorScheme.light(
    surface: Colors.grey.shade300,
    primary: Colors.grey.shade200,
    secondary: Colors.grey.shade400,
    inversePrimary: Colors.grey.shade800,
    outline: Colors.grey.shade500,
    onSurface: Colors.grey.shade900,
    onSurfaceVariant: Colors.grey.shade700,
  ),
  inputDecorationTheme: InputDecorationTheme(
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.grey.shade500),
      borderRadius: BorderRadius.circular(12),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.grey.shade800, width: 1.5),
      borderRadius: BorderRadius.circular(12),
    ),
  ),
);

ThemeData darkMode = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.dark(
    surface: const Color(0xFF181818),
    primary: const Color(0xFF222222),
    secondary: const Color(0xFF313131),
    inversePrimary: Colors.grey.shade300,
    outline: const Color(0xFF444444),
    onSurface: Colors.white,
    onSurfaceVariant: Colors.grey,
  ),
  inputDecorationTheme: const InputDecorationTheme(),
);
