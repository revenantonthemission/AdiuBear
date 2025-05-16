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
    secondary: Colors.grey.shade500,
    tertiary: Colors.grey.shade800,
    inversePrimary: Colors.grey.shade300,
  ),
);

final geminiModelList = [
  'gemini-1.5-flash',
  'gemini-1.5-pro',
  'gemini-2.0-flash',
  'gemini-2.0-flash-lite',
  'gemini-2.5-flash-preview-04-17',
  'gemini-2.5-pro-preview-05-06'
];
late String _geminiModel = 'gemini-2.0-flash';

class ThemeProvider extends ChangeNotifier {
  ThemeData _themeData = lightMode;

  ThemeData get themeData => _themeData;

  bool get isDarkMode => _themeData == darkMode;

  String get geminiModel => _geminiModel;

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

  set geminiModel(String? value) {
    if (value != null) {
      _geminiModel = value;
    }
  }
}
