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
            // Custom Drawer Header to center everything
            Container(
              color: Colors.green.shade100, // Optional background color for header
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, // Center the content vertically
                crossAxisAlignment: CrossAxisAlignment.center, // Center the content horizontally
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.eco, color: Colors.green, size: 40),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "GreenWatch",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "contact@greenwatch.com",
                    style: TextStyle(fontSize: 16),
                  ),
                ],
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
