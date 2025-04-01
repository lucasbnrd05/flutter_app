import 'package:flutter/material.dart';
import "package:http/http.dart" as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GreenWatch',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _weather = "Chargement...";

  @override
  void initState() {
    super.initState();
    fetchWeather();
  }

  // 🔥 Fonction pour récupérer la météo avec l'API MetaWeather
  Future<void> fetchWeather() async {
    const String cityId = "615702"; // ID pour Paris
    final response = await http.get(Uri.parse(
        "https://www.metaweather.com/api/location/$cityId/?format=json"));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _weather = "🌡 ${data['consolidated_weather'][0]['the_temp']}°C | ${data['consolidated_weather'][0]['weather_state_name']}";
      });
    } else {
      setState(() {
        _weather = "Impossible de récupérer la météo.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("GreenWatch 🌍"),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showAboutDialog(
                context: context,
                applicationName: "GreenWatch",
                applicationVersion: "1.0.0",
                applicationLegalese: "© 2025 GreenWatch",
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 🌿 IMAGE BANNIÈRE
            Image.asset("assets/nature.jpg", height: 200, fit: BoxFit.cover),

            const SizedBox(height: 20),

            // 🌱 CITATION INSPIRANTE
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Card(
                color: Colors.green.shade100,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    "🌍 \"La Terre ne nous appartient pas, nous l’empruntons à nos enfants.\" – Antoine de Saint-Exupéry",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
