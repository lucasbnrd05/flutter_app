// lib/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart'; // Pour platformBrightness
import 'package:shared_preferences/shared_preferences.dart'; // <-- Importe SharedPreferences

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode; // Ne pas initialiser ici, le constructeur le fera

  // --- Clé pour SharedPreferences ---
  static const String _themePersistenceKey = 'app_theme_mode';

  // --- Constructeur ---
  // Accepte un thème initial (qui sera chargé depuis SharedPreferences dans main.dart)
  ThemeProvider({ThemeMode initialThemeMode = ThemeMode.system})
      : _themeMode = initialThemeMode;

  // --- Getters ---
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

  // --- Méthode pour changer ET SAUVEGARDER le thème ---
  Future<void> setThemeMode(ThemeMode mode) async {
    // <-- Rendre la méthode async
    if (_themeMode != mode) {
      _themeMode = mode;
      // Notifie les listeners D'ABORD pour une mise à jour rapide de l'UI
      notifyListeners();

      // Ensuite, sauvegarde la préférence de manière asynchrone
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
          default: // Cas par défaut et système
            themeString = 'system';
            break;
        }
        await prefs.setString(_themePersistenceKey, themeString);
        print(
            '[ThemeProvider] Thème sauvegardé: $themeString'); // Log pour débogage
      } catch (e) {
        // Gérer l'erreur si la sauvegarde échoue (optionnel)
        print('[ThemeProvider] Erreur lors de la sauvegarde du thème: $e');
      }
    }
  }

  // --- Méthode pour charger le thème (utilisée dans main.dart) ---
  // On la met static pour pouvoir l'appeler avant d'instancier le Provider
  static Future<ThemeMode> loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? savedTheme = prefs.getString(_themePersistenceKey);
      print(
          '[ThemeProvider] Thème chargé depuis Prefs: ${savedTheme ?? "aucun (défaut système)"}'); // Log

      switch (savedTheme) {
        case 'light':
          return ThemeMode.light;
        case 'dark':
          return ThemeMode.dark;
        case 'system':
        default: // Si null ou autre valeur, on retourne system
          return ThemeMode.system;
      }
    } catch (e) {
      print('[ThemeProvider] Erreur lors du chargement du thème: $e');
      return ThemeMode.system; // Retourne system en cas d'erreur
    }
  }
}
