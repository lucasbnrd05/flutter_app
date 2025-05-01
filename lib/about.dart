// lib/about.dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'ux_unit/custom_drawer.dart'; // Chemin relatif

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  Future<void> _launchUrl(BuildContext context, String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (urlString.isEmpty) {
      print('[WARN AboutPage] Empty URL');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Link not available.')));
      }
      return;
    }
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $urlString';
      }
    } catch (e) {
      print('[ERROR AboutPage] Could not launch URL: $urlString. Error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not open link: $urlString')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const String appVersion = "1.0.1"; // Met à jour si nécessaire

    return Scaffold(
      appBar: AppBar(
        title: const Text("About GreenWatch"),
      ),
      drawer: const CustomDrawer(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                'assets/app_icon.png', // Assure-toi que ce fichier existe
                height: 80,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.eco_rounded,
                      size: 80, color: theme.colorScheme.primary);
                },
              ),
              const SizedBox(height: 16),
              Text(
                "GreenWatch is an app dedicated to environmental awareness. Follow the latest climate news, discover inspiring quotes, report local environmental events, and explore air quality data to stay connected with our planet.\n\nOur goal is to raise awareness and promote sustainable actions.",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              Text(
                "Version: $appVersion",
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              Center(
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.textTheme.bodyMedium?.color),
                    children: [
                      const TextSpan(text: 'Climate news data provided by '),
                      TextSpan(
                        text: 'The New York Times\n',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            _launchUrl(context, 'https://developer.nytimes.com/');
                          },
                      ),
                      const TextSpan(text: 'Air quality data provided by '),
                      TextSpan(
                        text: 'OpenAQ Platform',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            _launchUrl(context, 'https://openaq.org/');
                          },
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Made with ',
                    style: theme.textTheme.bodySmall,
                  ),
                  const FlutterLogo(size: 18),
                  Text(
                    ' Flutter',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                "Created by Dina Didouche.",
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}