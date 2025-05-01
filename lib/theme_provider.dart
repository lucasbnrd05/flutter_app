// lib/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode;

  static const String _themePersistenceKey = 'app_theme_mode';

  ThemeProvider({ThemeMode initialThemeMode = ThemeMode.system})
      : _themeMode = initialThemeMode;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      final Brightness platformBrightness =
          SchedulerBinding.instance.platformDispatcher.platformBrightness;
      return platformBrightness == Brightness.dark;
    } else {
      return _themeMode == ThemeMode.dark;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode != mode) {
      _themeMode = mode;
      notifyListeners();

      try {
        final prefs = await SharedPreferences.getInstance();
        String themeString;
        switch (mode) {
          case ThemeMode.light:
            themeString = 'light';
            break;
          case ThemeMode.dark:
            themeString = 'dark';
            break;
          case ThemeMode.system:
          default:
            themeString = 'system';
            break;
        }
        await prefs.setString(_themePersistenceKey, themeString);
        print(
            '[ThemeProvider] Thème sauvegardé: $themeString');
      } catch (e) {
        print('[ThemeProvider] Erreur lors de la sauvegarde du thème: $e');
      }
    }
  }

  static Future<ThemeMode> loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? savedTheme = prefs.getString(_themePersistenceKey);
      print(
          '[ThemeProvider] Thème chargé depuis Prefs: ${savedTheme ?? "aucun (défaut système)"}');

      switch (savedTheme) {
        case 'light':
          return ThemeMode.light;
        case 'dark':
          return ThemeMode.dark;
        case 'system':
        default:
          return ThemeMode.system;
      }
    } catch (e) {
      print('[ThemeProvider] Erreur lors du chargement du thème: $e');
      return ThemeMode.system;
    }
  }
}