import 'package:flutter/material.dart';
import 'package:flutter_app/ux_unit/custom_drawer.dart';
import 'main.dart';
import 'settings.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("About GreenWatch"),
      ),
      drawer: const CustomDrawer(),
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
