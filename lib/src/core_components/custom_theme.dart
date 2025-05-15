import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

ThemeData lightMode = ThemeData(
  colorScheme: ColorScheme.light(
    onSurface: Colors.grey.shade700,
    primary: Colors.grey.shade500,
    secondary: Colors.grey.shade200,
    tertiary: Colors.white,
    inversePrimary: Colors.grey.shade900,
  ),
);

ThemeData darkMode = ThemeData(
  colorScheme: ColorScheme.dark(
    onSurface: Colors.grey.shade900,
    primary: Colors.grey.shade600,
    secondary: Colors.grey.shade700,
    tertiary: Colors.grey.shade800,
    inversePrimary: Colors.grey.shade300,
  ),
);

class ThemeProvider extends ChangeNotifier {
  ThemeData _themeData = lightMode;

  ThemeData get themeData => _themeData;

  bool get isDarkMode => _themeData == darkMode;

  set themeData(ThemeData themeData) {
    _themeData = themeData;
    notifyListeners();
  }

  void toggleTheme() {
    if (isDarkMode) {
      themeData = lightMode;
    } else {
      themeData = darkMode;
    }
  }
}
