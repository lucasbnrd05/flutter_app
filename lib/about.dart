import 'package:flutter/material.dart';
import 'package:flutter_app/ux_unit/custom_drawer.dart';
// Enlève les imports non utilisés si tu utilises les routes nommées
// import 'main.dart';
// import 'settings.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Récupère le thème

    return Scaffold(
      appBar: AppBar(
        title: const Text("About GreenWatch"), // S'adapte via AppBarTheme
      ),
      drawer: const CustomDrawer(), // S'adapte via DrawerTheme
      body: Padding(
        padding: const EdgeInsets.all(24.0), // Un peu plus de padding
        child: Center(
          child: Text(
            "GreenWatch is an app that provides environmental awareness. It gives live weather updates and inspiring quotes to help you stay connected with nature.\n\n"
                "Our goal is to raise awareness and promote sustainability.\n\n"
                "Created by the GreenWatch Team.",
            textAlign: TextAlign.center,
            // Utilise un style de texte du thème
            style: theme.textTheme.bodyLarge, // La couleur s'adaptera
          ),
        ),
      ),
    );
  }
}