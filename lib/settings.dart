// lib/settings.dart
import 'package:flutter/gestures.dart'; // Pour TapGestureRecognizer
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart'; // Pour ouvrir les liens

// Imports locaux
import 'theme_provider.dart';
import 'ux_unit/custom_drawer.dart';
import 'services/settings_service.dart'; // Service pour la clé API

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Contrôleur pour le champ de texte de la clé API
  final _apiKeyController = TextEditingController();
  // Indicateurs d'état
  bool _isLoadingKey = true; // Est-on en train de charger la clé au démarrage ?
  String? _currentApiKey; // La clé API actuellement sauvegardée

  @override
  void initState() {
    super.initState();
    _loadApiKey(); // Charge la clé API sauvegardée au démarrage
  }

  // Charge la clé API depuis SharedPreferences
  Future<void> _loadApiKey() async {
    if (mounted) {
      setState(() => _isLoadingKey = true);
    }
    _currentApiKey = await SettingsService.getNytApiKey();
    if (mounted) { // Re-vérifie si le widget est monté avant de mettre à jour l'UI
      if (_currentApiKey != null) {
        _apiKeyController.text = _currentApiKey!;
      } else {
        _apiKeyController.text = ''; // Champ vide si aucune clé
      }
      setState(() => _isLoadingKey = false);
    }
  }

  // Sauvegarde la clé API entrée dans le TextField
  Future<void> _saveApiKey() async {
    final keyToSave = _apiKeyController.text.trim();
    await SettingsService.saveNytApiKey(keyToSave); // Sauvegarde (même si vide, ce qui l'efface)

    if (mounted) {
      setState(() {
        _currentApiKey = keyToSave.isNotEmpty ? keyToSave : null;
      });
      // Affiche une confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(keyToSave.isNotEmpty ? 'NYT API Key saved successfully!' : 'NYT API Key cleared.'),
          backgroundColor: keyToSave.isNotEmpty ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
      FocusScope.of(context).unfocus(); // Cache le clavier
    }
  }

  // Efface la clé API (appelé par l'icône ET le bouton Reset)
  Future<void> _clearApiKey() async {
    // Vérifie si la clé est déjà vide pour éviter une action inutile
    if (_apiKeyController.text.isEmpty && _currentApiKey == null) {
      FocusScope.of(context).unfocus(); // Cache juste le clavier
      return;
    }

    await SettingsService.clearNytApiKey();
    if (mounted) {
      _apiKeyController.clear(); // Vide le champ de texte
      setState(() {
        _currentApiKey = null; // Met à jour l'état local
      });
      // Affiche une confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('NYT API Key cleared.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      FocusScope.of(context).unfocus(); // Cache le clavier
    }
  }

  // Ouvre une URL externe
  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open link: $urlString')),
        );
      }
    }
  }

  // Libère le contrôleur de texte lorsqu'il n'est plus nécessaire
  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Accès au Provider de thème et au thème actuel
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      drawer: const CustomDrawer(), // Menu latéral
      body: ListView( // Utilisation de ListView pour le scrolling si le contenu dépasse
        padding: const EdgeInsets.all(16.0), // Padding général
        children: [
          // --- Section Thème ---
          Text(
            'Application Theme', // Titre de la section
            style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary),
          ),
          // Option Thème Clair
          RadioListTile<ThemeMode>(
            title: const Text('Light'),
            secondary: Icon(Icons.wb_sunny, color: theme.colorScheme.primary),
            value: ThemeMode.light,
            groupValue: themeProvider.themeMode, // Valeur sélectionnée
            onChanged: (value) { // Action au changement
              if (value != null) {
                themeProvider.setThemeMode(value); // Met à jour le thème via le Provider
              }
            },
          ),
          // Option Thème Sombre
          RadioListTile<ThemeMode>(
            title: const Text('Dark'),
            secondary: Icon(Icons.nightlight_round, color: theme.colorScheme.primary),
            value: ThemeMode.dark,
            groupValue: themeProvider.themeMode,
            onChanged: (value) {
              if (value != null) {
                themeProvider.setThemeMode(value);
              }
            },
          ),
          // Option Thème Système
          RadioListTile<ThemeMode>(
            title: const Text('System'),
            subtitle: const Text('Follows phone settings'), // Texte additionnel
            secondary: Icon(Icons.settings_brightness, color: theme.colorScheme.primary),
            value: ThemeMode.system,
            groupValue: themeProvider.themeMode,
            onChanged: (value) {
              if (value != null) {
                themeProvider.setThemeMode(value);
              }
            },
          ),
          const Divider(height: 32), // Séparateur visuel

          // --- Section Clé API NYT ---
          Text(
            'API Keys & Integrations', // Titre de la section
            style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 16),
          // Texte explicatif avec lien cliquable
          RichText(
            text: TextSpan(
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodyMedium?.color), // Style par défaut
                children: [
                  const TextSpan(text: 'To view news from The New York Times, you need an API key. Get yours for free at the '),
                  TextSpan( // Lien vers le portail NYT
                    text: 'NYT Developer Portal',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer() // Rend le texte cliquable
                      ..onTap = () {
                        _launchUrl('https://developer.nytimes.com/'); // Ouvre le lien
                      },
                  ),
                  const TextSpan(text: '.'),
                ]
            ),
          ),
          const SizedBox(height: 20),
          // Champ de saisie pour la clé API
          TextField(
            controller: _apiKeyController, // Lie le contrôleur au champ
            obscureText: true, // Masque les caractères entrés
            decoration: InputDecoration(
              labelText: 'NYT API Key', // Label flottant
              hintText: 'Paste your API key here', // Texte indicatif
              border: const OutlineInputBorder(), // Bordure
              // Icône de chargement ou icône clé
              prefixIcon: _isLoadingKey
                  ? const Padding(padding: EdgeInsets.all(12.0), child: SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 2)))
                  : const Icon(Icons.key),
              // Icône pour effacer le champ (conditionnelle)
              suffixIcon: !_isLoadingKey && _apiKeyController.text.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear),
                tooltip: 'Clear Key',
                onPressed: _clearApiKey, // Appelle la fonction pour effacer
              )
                  : null, // Pas d'icône si chargement ou champ vide
            ),
            // Reconstruit pour mettre à jour l'état du suffixIcon quand le texte change
            onChanged: (_) => setState(() {}),
            // Sauvegarde la clé quand l'utilisateur valide (ex: touche Entrée)
            onSubmitted: (_) => _saveApiKey(),
          ),
          const SizedBox(height: 12),

          // --- Boutons Reset et Save Key ---
          Row(
            mainAxisAlignment: MainAxisAlignment.end, // Aligne les boutons à droite
            children: [
              // -- AJOUT DU BOUTON RESET --
              TextButton(
                onPressed: _isLoadingKey ? null : _clearApiKey, // Désactivé pendant le chargement
                child: const Text('Reset'),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error, // Couleur rouge pour indiquer la suppression
                ),
              ),
              const SizedBox(width: 8), // Espace entre les boutons

              // Bouton pour sauvegarder la clé
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Save Key'),
                // Désactive le bouton pendant le chargement initial
                onPressed: _isLoadingKey ? null : _saveApiKey,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary, // Couleur de fond
                  foregroundColor: theme.colorScheme.onPrimary, // Couleur du texte/icône
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}