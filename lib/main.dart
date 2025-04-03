import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import Provider
import 'dart:math';

// Importe tes nouvelles classes et thèmes
import 'themes.dart';
import 'theme_provider.dart';

// Importe tes pages et le drawer
import 'ux_unit/custom_drawer.dart';
import 'about.dart'; // Assure-toi que le chemin est correct
import 'settings.dart'; // Assure-toi que le chemin est correct
import 'map.dart'; // Assure-toi que le chemin est correct

void main() {
  runApp(
    // 1. Enveloppe ton app avec ChangeNotifierProvider
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 2. Écoute le provider pour récupérer le mode de thème actuel
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GreenWatch',
      // 3. Utilise les thèmes et le mode définis
      themeMode: themeProvider.themeMode, // Défini par le provider
      theme: lightTheme,                 // Ton thème clair
      darkTheme: darkTheme,               // Ton thème sombre
      // theme: ThemeData(primarySwatch: Colors.green), // Supprime l'ancien thème
      home: const HomePage(),
      // Optionnel mais recommandé : définir des routes nommées
      routes: {
        '/home': (context) => const HomePage(),
        '/map': (context) => const MapPage(),
        '/about': (context) => const AboutPage(),
        '/settings': (context) => const SettingsPage(),
      },
    );
  }
}

// --- HomePage reste presque identique, on va juste adapter la carte ---
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Weather logic (pas touché ici)
  // ...

  final List<String> _quotes = [
    "🌍 \"The Earth does not belong to us, we borrow it from our children.\" – Antoine de Saint-Exupéry",
    "🌱 \"Nature always wears the colors of the spirit.\" – Ralph Waldo Emerson",
    "🌿 \"Look deep into nature, and then you will understand everything better.\" – Albert Einstein",
    "🍃 \"The greatest threat to our planet is the belief that someone else will save it.\" – Robert Swan",
    "🌎 \"What we save, saves us.\" – Wendell Berry",
    "🌳 \"The best time to plant a tree was 20 years ago. The second best time is now.\" – Chinese Proverb",
    "🌻 \"He that plants trees loves others besides himself.\" – Thomas Fuller",
    "🐝 \"We won’t have a society if we destroy the environment.\" – Margaret Mead",
    "☀️ \"Keep close to Nature’s heart.\" – John Muir",
    "🌊 \"Water and air, the two essential fluids on which all life depends, have become global garbage cans.\" – Jacques-Yves Cousteau",
  ];

  late String _randomQuote;

  @override
  void initState() {
    super.initState();
    _randomQuote = _quotes[Random().nextInt(_quotes.length)];
  }

  @override
  Widget build(BuildContext context) {
    // Accéder au thème actuel pour adapter les couleurs si besoin explicitement
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("GreenWatch 🌍"),
        // Les actions de l'AppBar utilisent automatiquement foregroundColor défini dans AppBarTheme
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // showAboutDialog s'adapte généralement bien aux thèmes
              showAboutDialog(
                context: context,
                applicationName: "GreenWatch",
                applicationVersion: "1.0.0",
                applicationLegalese: "© 2025 GreenWatch",
              );
            },
          ),
        ],
      ),
      drawer: const CustomDrawer(), // Le drawer utilisera DrawerThemeData
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // L'image reste la même
            Image.asset("assets/nature.jpg", height: 200, width: double.infinity, fit: BoxFit.cover),
            const SizedBox(height: 30), // Un peu plus d'espace peut-être
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              // Utilisation de Card avec les styles du thème (CardTheme)
              child: Card(
                // color: colorScheme.surfaceVariant, // Essayons une couleur sémantique
                // elevation: theme.cardTheme.elevation ?? 2.0, // Utilise l'élévation du thème
                // shape: theme.cardTheme.shape, // Utilise la forme du thème
                // OU laisser vide pour utiliser directement CardTheme
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _randomQuote,
                    textAlign: TextAlign.center,
                    // Utilise le style de texte du thème pour une adaptation automatique
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontStyle: FontStyle.italic,
                      // La couleur sera gérée par le thème (onSurface ou onSurfaceVariant)
                      // color: colorScheme.onSurfaceVariant, // Forcer si besoin
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Tu peux ajouter d'autres widgets ici, ils suivront le thème
          ],
        ),
      ),
    );
  }
}