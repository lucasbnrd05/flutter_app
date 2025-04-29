// lib/ux_unit/custom_drawer.dart
import 'package:flutter/material.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Helper pour la navigation, évite de pousser si déjà sur la page
    void navigateIfNeeded(String routeName) {
      Navigator.pop(context); // Ferme le drawer d'abord
      final currentRoute = ModalRoute.of(context)?.settings.name;
      if (currentRoute != routeName) {
        // Si on va à l'accueil, on retire toutes les autres routes
        if (routeName == '/home') {
          Navigator.pushNamedAndRemoveUntil(context, routeName, (route) => false);
        } else {
          Navigator.pushNamed(context, routeName);
        }
      }
    }

    Widget buildDrawerHeader() {
      return DrawerHeader(
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer, // Utilise le schéma de couleurs
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 35,
              backgroundColor: colorScheme.surface, // Fond clair/sombre basé sur le thème
              child: Icon(Icons.eco_rounded, color: colorScheme.primary, size: 40), // Icône plus visible
            ),
            const SizedBox(height: 10),
            Text(
              "GreenWatch",
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.onPrimaryContainer, // Texte lisible sur le container
                fontWeight: FontWeight.bold,
              ),
            ),
            // Optionnel: email ou slogan
            // Text( "Your Environmental Companion", style: theme.textTheme.bodyMedium?.copyWith( color: colorScheme.onPrimaryContainer?.withOpacity(0.8), ), ),
          ],
        ),
      );
    }

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          buildDrawerHeader(),
          ListTile(
            leading: const Icon(Icons.home_outlined), // Icône outline
            title: const Text("Home"),
            onTap: () => navigateIfNeeded('/home'),
          ),
          ListTile(
            leading: const Icon(Icons.map_outlined), // Icône outline
            title: const Text("Map"),
            onTap: () => navigateIfNeeded('/map'),
          ),
          ListTile(
            leading: const Icon(Icons.add_chart_outlined), // Icône outline
            title: const Text("Report Data"), // Nom clair
            onTap: () => navigateIfNeeded('/data'),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline), // Icône outline
            title: const Text("About"),
            onTap: () => navigateIfNeeded('/about'),
          ),
          const Divider(), // Séparateur visuel
          ListTile(
            leading: const Icon(Icons.settings_outlined), // Icône outline
            title: const Text("Settings"),
            onTap: () => navigateIfNeeded('/settings'),
          ),
        ],
      ),
    );
  }
}