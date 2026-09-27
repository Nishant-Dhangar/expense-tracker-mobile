import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeManager extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();

    final isDark = prefs.getBool('isDarkMode') ?? false;

    _themeMode = isDark
        ? ThemeMode.dark
        : ThemeMode.light;

    notifyListeners();
  }

  Future<void> setDarkMode(bool enabled) async {
    _themeMode =
        enabled ? ThemeMode.dark : ThemeMode.light;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(
      'isDarkMode',
      enabled,
    );

    notifyListeners();
  }
}