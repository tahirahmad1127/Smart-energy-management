import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeManager with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  get themeMode => _themeMode;

  // Load saved theme when app starts
  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    bool isDark = prefs.getBool('darkMode') ?? false;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  // Toggle theme and save it
  Future<void> toggleTheme(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', isDark);
    notifyListeners(); // This triggers the UI update
  }
}

// Global instance so we can access it anywhere
final themeManager = ThemeManager();