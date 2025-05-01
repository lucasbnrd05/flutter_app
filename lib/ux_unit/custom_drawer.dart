// lib/ux_unit/custom_drawer.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final User? user = Provider.of<User?>(context);
    final bool isLoggedIn = user != null;
    // isTrulyLoggedIn n'est pas utilisé dans cette version, mais on pourrait l'ajouter si besoin
    // final bool isTrulyLoggedIn = user != null && !user.isAnonymous;

    void navigateIfNeeded(String routeName) {
      Navigator.pop(context); // Ferme drawer
      final currentRoute = ModalRoute.of(context)?.settings.name;
      if (currentRoute != routeName ||
          (routeName == '/home' && currentRoute == null)) {
        if (routeName == '/home') {
          Navigator.pushNamedAndRemoveUntil(
              context, routeName, (route) => false);
        } else {
          Navigator.pushNamed(context, routeName);
        }
      }
    }

    Future<void> _handleSignOut() async {
      final navigator = Navigator.of(context);
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      navigator.pop(); // Ferme le drawer immédiatement

      try {
        await AuthService().signOut(); // Déconnecte l'utilisateur
        print("[CustomDrawer] User signed out.");

        // Redirection vers HomePage après déconnexion
        navigator.pushNamedAndRemoveUntil('/home', (route) => false);
        print("[CustomDrawer] Navigated to /home after sign out.");
      } catch (e) {
        print("[CustomDrawer] Error during sign out navigation: $e");
        // Utilise le scaffoldMessenger capturé
        if (scaffoldMessenger.mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('Error signing out. Please try again.')),
          );
        }
      }
    }

    Widget buildDrawerHeader() {
      // Ton style de header préféré
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
              backgroundColor: colorScheme.surface,
              child: Icon(
                  isLoggedIn ? Icons.person_outline : Icons.eco_rounded, // Icone basée sur isLoggedIn
                  color: colorScheme.primary,
                  size: 40),
            ),
            const SizedBox(height: 10),
            Text(
              "GreenWatch",
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
            // Affichage optionnel du nom/email
            if (isLoggedIn)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  user?.displayName ?? user?.email ?? (user?.isAnonymous == true ? "Guest User" : "Connected"),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onPrimaryContainer?.withOpacity(0.8),
                    fontStyle: user?.isAnonymous == true ? FontStyle.italic : FontStyle.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
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
          buildDrawerHeader(), // Utilise ton header
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text("Home"),
            onTap: () => navigateIfNeeded('/home'),
          ),
          ListTile(
            leading: const Icon(Icons.map_outlined),
            title: const Text("Map"),
            onTap: () => navigateIfNeeded('/map'),
          ),
          ListTile(
            leading: const Icon(Icons.add_chart_outlined),
            title: const Text("Report Data"),
            onTap: () => navigateIfNeeded('/data'), // La page cible gère le blocage
            enabled: true, // Reste actif visuellement
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text("About"),
            onTap: () => navigateIfNeeded('/about'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text("Settings"),
            onTap: () => navigateIfNeeded('/settings'), // La page cible gère le blocage
            enabled: true, // Reste actif visuellement
          ),
          const Divider(),
          // Section Login/Logout
          if (!isLoggedIn)
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text("Login / Sign Up"),
              onTap: () => navigateIfNeeded('/auth'),
            )
          else
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red[400]),
              title: Text("Logout", style: TextStyle(color: Colors.red[400])),
              onTap: _handleSignOut,
            ),
        ],
      ),
    );
  }
}