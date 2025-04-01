import 'package:flutter/material.dart';
import 'about.dart'; // Ajoutez cette ligne pour pouvoir naviguer vers la page About
import 'main.dart'; // Ajoutez cette ligne pour pouvoir naviguer vers la page About

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const UserAccountsDrawerHeader(
              accountName: Text("GreenWatch"),
              accountEmail: Text("contact@greenwatch.com"),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.eco, color: Colors.green),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text("Home Page"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HomePage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text("About"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("Settings"),
              onTap: () {
                Navigator.pop(context); // Fermer le drawer (Redondant ici)
                // Naviguer vers la page Settings (ça pourrait être redondant ici)
              },
            ),
          ],
        ),
      ),
      body: const Center(
        child: Text(
          "Settings page\nHere you can change preferences for the app.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
