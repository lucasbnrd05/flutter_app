import 'package:flutter/gestures.dart'; // Needed for RichText links
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Needed to open links
import 'package:flutter_app/ux_unit/custom_drawer.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  // --- Helper function to launch URLs ---
  // (Copied/adapted from HomePage for consistency)
  Future<void> _launchUrl(BuildContext context, String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (urlString.isEmpty) {
      print('Attempting to open an empty URL.');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Link not available.')),
        );
      }
      return;
    }
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $urlString';
      }
    } catch (e) {
      print('Could not launch URL: $urlString. Error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open link: $urlString')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Récupère le thème
    const String appVersion = "1.0.0"; // Define app version (can be dynamic later)

    return Scaffold(
      appBar: AppBar(
        title: const Text("About GreenWatch"), // S'adapte via AppBarTheme
      ),
      drawer: const CustomDrawer(), // S'adapte via DrawerTheme
      // Use SingleChildScrollView + Column for better structure and scrolling
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0), // Keep padding
          child: Column( // Use Column to stack widgets vertically
            crossAxisAlignment: CrossAxisAlignment.center, // Center items horizontally
            children: [
              // --- NOUVEAU: App Logo ---
              // Make sure you have an icon/logo asset at this path
              // and declare it in pubspec.yaml
              Image.asset(
                'assets/app_icon.png', // Replace with your actual logo path
                height: 80, // Adjust size as needed
                errorBuilder: (context, error, stackTrace) {
                  // Fallback if image fails to load
                  return const Icon(Icons.eco, size: 80);
                },
              ),
              const SizedBox(height: 16), // Spacing

              // --- App Name (Optional, as it's in AppBar) ---
              // Text(
              //   "GreenWatch",
              //   style: theme.textTheme.headlineMedium,
              // ),
              // const SizedBox(height: 20),

              // --- Original Description Text ---
              Text(
                "GreenWatch is an app dedicated to environmental awareness. "
                    "Follow the latest climate news, discover inspiring quotes, and (soon!) explore environmental data to stay connected with our planet.\n\n"
                    "Our goal is to raise awareness and promote sustainable actions.",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 24), // Spacing

              // --- NOUVEAU: App Version ---
              Text(
                "Version: $appVersion",
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 16), // Spacing

              // --- NOUVEAU: Data Source Acknowledgement ---
              Center( // Center the RichText
                child: RichText(
                  textAlign: TextAlign.center, // Center text within RichText
                  text: TextSpan(
                    style: theme.textTheme.bodySmall, // Base style for this section
                    children: [
                      const TextSpan(text: 'Climate news data provided by\n'), // Line break for clarity
                      TextSpan(
                        text: 'The New York Times Developer Network',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            _launchUrl(context, 'https://developer.nytimes.com/');
                          },
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24), // Spacing

              // --- NOUVEAU: "Made with Flutter" Badge ---
              Row(
                mainAxisAlignment: MainAxisAlignment.center, // Center row content
                children: [
                  Text(
                    'Made with ',
                    style: theme.textTheme.bodySmall,
                  ),
                  const FlutterLogo(size: 18), // Flutter logo
                  Text(
                    ' Flutter',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 16), // Spacing

              // --- Original Creator Text ---
              Text(
                "Created by the GreenWatch Team.",
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall, // Slightly smaller style
              ),

            ],
          ),
        ),
      ),
    );
  }
}