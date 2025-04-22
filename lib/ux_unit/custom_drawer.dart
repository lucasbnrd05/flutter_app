import 'package:flutter/material.dart';
// Assuming your routes are set up in main.dart
// Remove direct page imports if using named routes primarily
// import '../about.dart';
// import '../settings.dart';
// import '../map.dart';
// import '../main.dart'; // Avoid importing main.dart

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget buildDrawerHeader() {
      return DrawerHeader(
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 35,
              backgroundColor: colorScheme.onPrimaryContainer,
              child: Icon(Icons.eco, color: colorScheme.primary, size: 35),
            ),
            const SizedBox(height: 10),
            Text(
              "GreenWatch", // Keep as is
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              "contact@greenwatch.com", // Keep as is
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onPrimaryContainer?.withOpacity(0.8),
              ),
            ),
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
            leading: const Icon(Icons.home),
            title: const Text("Home Page"), // Already English
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
            },
          ),
          ListTile(
            leading: const Icon(Icons.map),
            title: const Text("Map"), // Already English
            onTap: () {
              Navigator.pop(context);
              if (ModalRoute.of(context)?.settings.name != '/map') {
                Navigator.pushNamed(context, '/map');
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.dataset),
            title: const Text("Data"), // Already English
            onTap: () {
              Navigator.pop(context);
              if (ModalRoute.of(context)?.settings.name != '/data') {
                Navigator.pushNamed(context, '/data');
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text("About"), // Already English
            onTap: () {
              Navigator.pop(context);
              if (ModalRoute.of(context)?.settings.name != '/about') {
                Navigator.pushNamed(context, '/about');
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text("Settings"), // Already English
            onTap: () {
              Navigator.pop(context);
              if (ModalRoute.of(context)?.settings.name != '/settings') {
                Navigator.pushNamed(context, '/settings');
              }
            },
          ),
        ],
      ),
    );
  }
}