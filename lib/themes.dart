// lib/themes.dart
import 'package:flutter/material.dart';

// --- Thème Clair ---
final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  // Utilise ColorScheme.fromSeed pour une palette harmonieuse basée sur le vert
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.green, // Ta couleur principale
    brightness: Brightness.light,
    // Tu peux affiner des couleurs spécifiques si besoin:
    // primary: Colors.green,
    // secondary: Colors.lightGreen,
    // background: Colors.white,
    // surface: Colors.grey[100], // Pour les Cards, etc.
    // onBackground: Colors.black, // Texte sur le fond principal
    // onSurface: Colors.black87, // Texte sur les surfaces (Cards)
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.green, // AppBar en vert
    foregroundColor: Colors.white, // Titre et icônes en blanc
    elevation: 4.0, // Petite ombre
  ),
  cardTheme: CardTheme(
    elevation: 2.0,
    margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12.0),
    ),
    // color: Colors.green.shade50, // Légère teinte verte pour les cartes ? Optionnel
  ),
  drawerTheme: DrawerThemeData(
    // backgroundColor: Colors.grey[50], // Fond du drawer clair
  ),
  listTileTheme: const ListTileThemeData(
    iconColor: Colors.green, // Icônes dans le drawer
  ),
  // Définis d'autres styles si nécessaire (boutons, etc.)
);

// --- Thème Sombre ---
final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  // Utilise ColorScheme.fromSeed pour le thème sombre aussi
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.green, // Garde la même base pour la cohérence
    brightness: Brightness.dark,
    // Affine si besoin, EXTRÊMEMENT IMPORTANT pour la lisibilité
    // background: Colors.grey[900], // Fond principal très sombre
    // surface: Colors.grey[850], // Fond des cartes un peu moins sombre
    // onBackground: Colors.white, // Texte sur fond principal (essentiel)
    // onSurface: Colors.white, // Texte sur les cartes (essentiel)
    // primary: Colors.greenAccent[100], // Une version plus claire du vert pour le sombre
    // onPrimary: Colors.black, // Texte sur les éléments primaires (boutons verts)
    // primaryContainer: Colors.green[900], // Conteneur associé au primaire
    // onPrimaryContainer: Colors.greenAccent[100], // Texte sur ce conteneur
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.grey[900], // AppBar sombre
    foregroundColor: Colors.white, // Titre et icônes blancs
  ),
  cardTheme: CardTheme(
    elevation: 2.0,
    margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12.0),
    ),
    // color: Colors.grey[800], // Couleur de carte pour le thème sombre
  ),
  drawerTheme: DrawerThemeData(
    // backgroundColor: Colors.grey[850], // Fond du drawer sombre
  ),
  listTileTheme: ListTileThemeData(
    iconColor: Colors.greenAccent[100], // Icônes plus claires dans le drawer sombre
  ),
  // Définis d'autres styles si nécessaire
);