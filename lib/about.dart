import 'package:flutter/material.dart';
import 'main.dart'; // Ajoutez cette ligne pour pouvoir naviguer vers la page About
import 'settings.dart'; // Ajoutez cette ligne pour pouvoir naviguer vers la page About

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("About GreenWatch"),
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
                );              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text("About"),
              onTap: () {
                Navigator.pop(context); // Fermer le drawer
                // Naviguer vers la page About (cela pourrait être redondant ici)
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("Settings"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
            ),
          ],
        ),
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            "GreenWatch is an app that provides environmental awareness. It gives live weather updates and inspiring quotes to help you stay connected with nature.\n\n"
                "Our goal is to raise awareness and promote sustainability.\n\n"
                "Created by the GreenWatch Team.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}
