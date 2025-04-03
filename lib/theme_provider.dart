// lib/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart'; // Pour platformBrightness

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system; // Défaut: suit le système

  ThemeMode get themeMode => _themeMode;

  // Pour savoir si on est actuellement en sombre (utile pour la logique conditionnelle)
  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      // Récupère la luminosité actuelle de la plateforme (téléphone)
      final Brightness platformBrightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
      return platformBrightness == Brightness.dark;
    } else {
      return _themeMode == ThemeMode.dark;
    }
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      notifyListeners(); // Notifie les écouteurs du changement
    }
  }
}