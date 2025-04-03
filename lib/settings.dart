import 'package:flutter/material.dart';
import 'package:flutter_app/ux_unit/custom_drawer.dart';
import 'about.dart';
import 'main.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      drawer: const CustomDrawer(),
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
