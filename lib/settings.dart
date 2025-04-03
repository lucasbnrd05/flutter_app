import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import Provider
import 'theme_provider.dart'; // Import ton ThemeProvider
import 'ux_unit/custom_drawer.dart'; // Import le drawer

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Accède au provider pour lire l'état actuel et pour appeler les méthodes
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        // Title in English
        title: const Text("Settings"),
      ),
      drawer: const CustomDrawer(), // Le drawer s'adaptera au thème
      body: ListView( // Utilise ListView pour organiser les options
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              // Section title in English
              'Application Theme',
              // Utilise un style de texte du thème
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary, // Met en évidence avec la couleur primaire
              ),
            ),
          ),
          RadioListTile<ThemeMode>(
            // Option in English
            title: const Text('Light'),
            // L'icône peut être thématique aussi
            secondary: Icon(Icons.wb_sunny, color: Theme.of(context).colorScheme.primary),
            value: ThemeMode.light,
            groupValue: themeProvider.themeMode, // Valeur actuelle
            onChanged: (value) {
              if (value != null) {
                themeProvider.setThemeMode(value); // Change le thème via le provider
              }
            },
          ),
          RadioListTile<ThemeMode>(
            // Option in English
            title: const Text('Dark'),
            secondary: Icon(Icons.nightlight_round, color: Theme.of(context).colorScheme.primary),
            value: ThemeMode.dark,
            groupValue: themeProvider.themeMode,
            onChanged: (value) {
              if (value != null) {
                themeProvider.setThemeMode(value);
              }
            },
          ),
          RadioListTile<ThemeMode>(
            // Option in English
            title: const Text('System'),
            // Subtitle in English
            subtitle: const Text('Follows phone settings'), // Petit texte explicatif
            secondary: Icon(Icons.settings_brightness, color: Theme.of(context).colorScheme.primary),
            value: ThemeMode.system,
            groupValue: themeProvider.themeMode,
            onChanged: (value) {
              if (value != null) {
                themeProvider.setThemeMode(value);
              }
            },
          ),
          const Divider(indent: 16, endIndent: 16), // Séparateur visuel
          // Add other settings here if needed
          // ListTile(
          //   leading: Icon(Icons.notifications),
          //   title: Text('Notifications'),
          //   onTap: () { /* Navigate to notification settings */ },
          // ),
        ],
      ),
    );
  }
}