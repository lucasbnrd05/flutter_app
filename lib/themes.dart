// lib/themes.dart
import 'package:flutter/material.dart';

// --- Thème Clair ---
final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.green,
    brightness: Brightness.light,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.green,
    foregroundColor: Colors.white,
    elevation: 4.0,
  ),
  cardTheme: CardTheme(
    elevation: 2.0,
    margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12.0),
    ),
  ),
  drawerTheme: const DrawerThemeData(),
  listTileTheme: const ListTileThemeData(
    iconColor: Colors.green,
  ),
);

// --- Thème Sombre ---
final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.green,
    brightness: Brightness.dark,
    // Note: Pour une meilleure lisibilité en sombre, envisage de surcharger
    // background, surface, onBackground, onSurface, primary, onPrimary etc. ici.
    // Ex: background: Colors.grey[900], surface: Colors.grey[850], etc.
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.grey[900], // AppBar sombre
    foregroundColor: Colors.white,
  ),
  cardTheme: CardTheme(
    elevation: 2.0,
    margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12.0),
    ),
    // color: Colors.grey[800], // Fond de carte plus sombre
  ),
  drawerTheme: const DrawerThemeData(),
  listTileTheme: ListTileThemeData(
    iconColor: Colors.greenAccent[100], // Icônes plus claires
  ),
);