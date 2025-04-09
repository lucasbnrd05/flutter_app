// lib/settings.dart

import 'package:flutter/gestures.dart'; // Pour TapGestureRecognizer
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart'; // Pour ouvrir les liens
import 'dart:async'; // Pour Future

// Imports locaux
import 'theme_provider.dart';
import 'ux_unit/custom_drawer.dart';
import 'services/settings_service.dart'; // Service pour la clé API

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _apiKeyController = TextEditingController();
  bool _isLoadingKey = true;
  String? _currentApiKey;

  @override
  void initState() {
    super.initState();
    print('[DEBUG SettingsPage] initState: Calling _loadApiKey...');
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    print('[DEBUG SettingsPage] _loadApiKey: Starting...');
    if (mounted) {
      setState(() => _isLoadingKey = true);
    }
    try {
      _currentApiKey = await SettingsService.getNytApiKey();
      print('[DEBUG SettingsPage] _loadApiKey: Key loaded from service: ${_currentApiKey ?? "null"}');
      if (mounted) {
        _apiKeyController.text = _currentApiKey ?? '';
        setState(() => _isLoadingKey = false);
        print('[DEBUG SettingsPage] _loadApiKey: State updated, isLoadingKey=false');
      } else {
        print('[DEBUG SettingsPage] _loadApiKey: Widget unmounted after loading key.');
      }
    } catch (e) {
      print('[DEBUG SettingsPage] _loadApiKey: Error loading key: $e');
      if(mounted) {
        setState(() => _isLoadingKey = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading API Key: $e')),
        );
      }
    }
  }

  // ******************************************************
  // ****** LA MODIFICATION EST DANS CETTE FONCTION ******
  // ******************************************************
  Future<void> _saveApiKey() async {
    final keyToSave = _apiKeyController.text.trim();
    // --- DEBUG LOG ---
    print('[DEBUG SettingsPage] _saveApiKey: Attempting to save key: "$keyToSave"');

    // --- NOUVEAU DEBUG LOG IMPORTANT ---
    // Ce log montre PRÉCISÉMENT ce qui est envoyé à la fonction de sauvegarde.
    // Si cette valeur n'est pas votre clé API, le problème vient de comment
    // keyToSave est obtenu (ici, via _apiKeyController.text.trim()).
    print('>>>>> [CRITICAL DEBUG SettingsPage] _saveApiKey: EXACT VALUE being passed to SettingsService.saveNytApiKey IS ---> "$keyToSave"');
    // --- FIN NOUVEAU DEBUG LOG ---

    try {
      // Appel à la fonction de sauvegarde dans le service
      await SettingsService.saveNytApiKey(keyToSave);

      // --- DEBUG LOG ---
      print('[DEBUG SettingsPage] _saveApiKey: Key save reported successful by SettingsService.');
      // --- FIN DEBUG LOG ---

      if (mounted) {
        setState(() {
          _currentApiKey = keyToSave.isNotEmpty ? keyToSave : null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(keyToSave.isNotEmpty ? 'NYT API Key saved successfully!' : 'NYT API Key cleared.'),
            backgroundColor: keyToSave.isNotEmpty ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
        FocusScope.of(context).unfocus();
      } else {
        print('[DEBUG SettingsPage] _saveApiKey: Widget unmounted after saving.');
      }
    } catch (e) {
      // --- DEBUG LOG ---
      print('[DEBUG SettingsPage] _saveApiKey: Error reported during saving key: $e');
      // --- FIN DEBUG LOG ---
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving API Key: $e')),
        );
      }
    }
  }
  // ******************************************************
  // ****** FIN DE LA SECTION MODIFIÉE                ******
  // ******************************************************


  Future<void> _clearApiKey() async {
    print('[DEBUG SettingsPage] _clearApiKey: Attempting to clear key...');
    if (_apiKeyController.text.isEmpty && _currentApiKey == null) {
      print('[DEBUG SettingsPage] _clearApiKey: Key already empty, unfocusing.');
      FocusScope.of(context).unfocus();
      return;
    }

    try {
      await SettingsService.clearNytApiKey();
      print('[DEBUG SettingsPage] _clearApiKey: Key clear reported successful by SettingsService.');
      if (mounted) {
        _apiKeyController.clear();
        setState(() {
          _currentApiKey = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('NYT API Key cleared.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
        FocusScope.of(context).unfocus();
      } else {
        print('[DEBUG SettingsPage] _clearApiKey: Widget unmounted after clearing.');
      }
    } catch (e) {
      print('[DEBUG SettingsPage] _clearApiKey: Error clearing key: $e');
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error clearing API Key: $e')),
        );
      }
    }
  }

  Future<void> _launchUrl(String urlString) async {
    print('[DEBUG SettingsPage] _launchUrl: Attempting to launch: $urlString');
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        print('[DEBUG SettingsPage] _launchUrl: launchUrl returned false for $urlString');
        throw 'Could not launch $urlString';
      }
    } catch (e) {
      print('[DEBUG SettingsPage] _launchUrl: Error launching $urlString: $e');
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open link: $urlString')),
        );
      }
    }
  }

  @override
  void dispose() {
    print('[DEBUG SettingsPage] dispose: Disposing controller.');
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);

    // print('[DEBUG SettingsPage] build: Rebuilding UI. isLoadingKey: $_isLoadingKey, currentApiKey: ${_currentApiKey ?? "null"}, controllerText: "${_apiKeyController.text}"');

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      drawer: const CustomDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- Section Thème ---
          Text(
            'Application Theme',
            style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Light'),
            secondary: Icon(Icons.wb_sunny, color: theme.colorScheme.primary),
            value: ThemeMode.light,
            groupValue: themeProvider.themeMode,
            onChanged: (value) {
              if (value != null) {
                print('[DEBUG SettingsPage] Theme changed to Light');
                themeProvider.setThemeMode(value);
              }
            },
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Dark'),
            secondary: Icon(Icons.nightlight_round, color: theme.colorScheme.primary),
            value: ThemeMode.dark,
            groupValue: themeProvider.themeMode,
            onChanged: (value) {
              if (value != null) {
                print('[DEBUG SettingsPage] Theme changed to Dark');
                themeProvider.setThemeMode(value);
              }
            },
          ),
          RadioListTile<ThemeMode>(
            title: const Text('System'),
            subtitle: const Text('Follows phone settings'),
            secondary: Icon(Icons.settings_brightness, color: theme.colorScheme.primary),
            value: ThemeMode.system,
            groupValue: themeProvider.themeMode,
            onChanged: (value) {
              if (value != null) {
                print('[DEBUG SettingsPage] Theme changed to System');
                themeProvider.setThemeMode(value);
              }
            },
          ),
          const Divider(height: 32),

          // --- Section Clé API NYT ---
          Text(
            'API Keys & Integrations',
            style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 16),
          RichText(
            text: TextSpan(
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodyMedium?.color),
                children: [
                  const TextSpan(text: 'To view news from The New York Times, you need an API key. Get yours for free at the '),
                  TextSpan(
                    text: 'NYT Developer Portal',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        print('[DEBUG SettingsPage] Tapped NYT Developer Portal link.');
                        _launchUrl('https://developer.nytimes.com/');
                      },
                  ),
                  const TextSpan(text: '.'),
                ]
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _apiKeyController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'NYT API Key',
              hintText: 'Paste your API key here',
              border: const OutlineInputBorder(),
              prefixIcon: _isLoadingKey
                  ? const Padding(padding: EdgeInsets.all(12.0), child: SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 2)))
                  : const Icon(Icons.key),
              suffixIcon: !_isLoadingKey && _apiKeyController.text.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear),
                tooltip: 'Clear Key',
                onPressed: _clearApiKey,
              )
                  : null,
            ),
            onChanged: (_) => setState(() {}), // Pour màj l'icône clear
            onSubmitted: (_) => _saveApiKey(), // Appelle la fonction modifiée
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _isLoadingKey ? null : _clearApiKey,
                child: const Text('Reset'),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Save Key'),
                onPressed: _isLoadingKey ? null : _saveApiKey, // Appelle la fonction modifiée
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}