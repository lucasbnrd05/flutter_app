// lib/settings.dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

import 'theme_provider.dart';
import 'ux_unit/custom_drawer.dart';
import 'services/settings_service.dart';
import 'ux_unit/login_required_widget.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _nytApiKeyController = TextEditingController();
  final _openAqApiKeyController = TextEditingController();
  bool _isLoadingNytKey = false; // Commence false, on active si besoin
  String? _currentNytApiKey;
  bool _isLoadingOpenAqKey = false; // Commence false
  String? _currentOpenAqApiKey;

  // Plus besoin de _lastCheckedUserId

  @override
  void initState() {
    super.initState();
    // On appelle _loadApiKeys une première fois ici,
    // mais seulement si l'utilisateur est DÉJÀ connecté au démarrage de la page.
    // didChangeDependencies gérera les changements d'état après le build initial.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Utilise context.read pour une lecture unique sans écouter ici
      final initialUser = Provider.of<User?>(context, listen: false);
      if (initialUser != null && !initialUser.isAnonymous) {
        print("[SettingsPage initState] User already logged in. Loading keys.");
        _loadApiKeys();
      } else {
        print("[SettingsPage initState] No logged in user initially.");
        // Assure que les indicateurs de chargement sont à false
        if (mounted) {
          setState(() {
            _isLoadingNytKey = false;
            _isLoadingOpenAqKey = false;
          });
        }
      }
    });
  }

  // didChangeDependencies écoute maintenant TOUS les changements du User?
  // y compris le passage de null à non-null (connexion) ou non-null à null (déconnexion)
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // On recharge les clés à chaque changement d'état d'authentification
    // fourni par le Provider.
    print(
        "[SettingsPage didChangeDependencies] Auth state might have changed. Reloading keys.");
    _loadApiKeys();
  }

  Future<void> _loadApiKeys() async {
    // Utilise Provider pour obtenir l'utilisateur ACTUEL
    // listen: false car on est dans une méthode appelée suite à un changement d'état ou initState
    final user = Provider.of<User?>(context, listen: false);
    final bool shouldLoad = user != null && !user.isAnonymous;

    // Si pas d'utilisateur valide, nettoie et arrête le chargement
    if (!shouldLoad) {
      print(
          "[SettingsPage _loadApiKeys] No logged-in user, clearing fields and stopping load.");
      if (mounted) {
        setState(() {
          _currentNytApiKey = null;
          _currentOpenAqApiKey = null;
          _nytApiKeyController.text = '';
          _openAqApiKeyController.text = '';
          _isLoadingNytKey = false;
          _isLoadingOpenAqKey = false;
        });
      }
      return;
    }

    // Si utilisateur valide, lance le chargement
    if (!mounted) return;
    print(
        "[SettingsPage _loadApiKeys] User is logged in (${user?.uid}). Loading keys.");
    setState(() {
      _isLoadingNytKey = true;
      _isLoadingOpenAqKey = true;
    });

    try {
      // Appelle les méthodes qui utilisent l'UID actuel via FirebaseAuth.instance
      final results = await Future.wait([
        SettingsService.getNytApiKey(),
        SettingsService.getOpenAqApiKey(),
      ]);

      // Revérifie si widget monté et si l'utilisateur est TOUJOURS le même
      // (ou au moins toujours connecté) après l'attente
      final latestUser = Provider.of<User?>(context, listen: false);
      if (!mounted || latestUser?.uid != user?.uid) {
        print(
            "[SettingsPage _loadApiKeys] User changed during loading or widget unmounted. Aborting state update.");
        return;
      }

      // Met à jour l'état local et les contrôleurs
      _currentNytApiKey = results[0];
      _currentOpenAqApiKey = results[1];
      _nytApiKeyController.text = _currentNytApiKey ?? '';
      _openAqApiKeyController.text = _currentOpenAqApiKey ?? '';
      print(
          "[SettingsPage _loadApiKeys] Keys loaded: NYT=${_currentNytApiKey != null}, OpenAQ=${_currentOpenAqApiKey != null}");
    } catch (e) {
      print('[ERROR SettingsPage] Error loading API keys: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading API Keys: $e')),
        );
      }
    } finally {
      // Arrête le chargement si toujours monté
      if (mounted) {
        setState(() {
          _isLoadingNytKey = false;
          _isLoadingOpenAqKey = false;
        });
      }
    }
  }

  // --- Les méthodes save/clear/launch restent identiques ---
  Future<void> _saveNytApiKey() async {
    final keyToSave = _nytApiKeyController.text.trim();
    try {
      await SettingsService.saveNytApiKey(keyToSave);
      if (mounted) {
        setState(
            () => _currentNytApiKey = keyToSave.isNotEmpty ? keyToSave : null);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(keyToSave.isNotEmpty
                ? 'NYT API Key saved!'
                : 'NYT API Key cleared.'),
            backgroundColor:
                keyToSave.isNotEmpty ? Colors.green : Colors.orange));
        FocusScope.of(context).unfocus();
      }
    } catch (e) {
      print('[ERROR SettingsPage] NYT SAVE failed: $e');
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error saving NYT Key: $e')));
    }
  }

  Future<void> _clearNytApiKey() async {
    _nytApiKeyController.clear();
    await _saveNytApiKey();
  }

  Future<void> _saveOpenAqApiKey() async {
    final keyToSave = _openAqApiKeyController.text.trim();
    try {
      await SettingsService.saveOpenAqApiKey(keyToSave);
      if (mounted) {
        setState(() =>
            _currentOpenAqApiKey = keyToSave.isNotEmpty ? keyToSave : null);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(keyToSave.isNotEmpty
                ? 'OpenAQ API Key saved!'
                : 'OpenAQ API Key cleared.'),
            backgroundColor:
                keyToSave.isNotEmpty ? Colors.green : Colors.orange));
        FocusScope.of(context).unfocus();
      }
    } catch (e) {
      print('[ERROR SettingsPage] OpenAQ SAVE failed: $e');
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving OpenAQ Key: $e')));
    }
  }

  Future<void> _clearOpenAqApiKey() async {
    _openAqApiKeyController.clear();
    await _saveOpenAqApiKey();
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $urlString';
      }
    } catch (e) {
      print('[ERROR SettingsPage] _launchUrl Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open link: $urlString')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nytApiKeyController.dispose();
    _openAqApiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);
    // Lit l'utilisateur depuis le Provider
    final User? user = Provider.of<User?>(context);
    final bool isTrulyLoggedIn = user != null && !user.isAnonymous;

    // Affiche "Login Requis" si pas connecté
    if (!isTrulyLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text("Settings")),
        drawer: const CustomDrawer(),
        body: const LoginRequiredWidget(featureName: "Settings"),
      );
    }

    // Affiche les paramètres si connecté
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      drawer: const CustomDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Section Thème
          Text('Application Theme',
              style: theme.textTheme.titleLarge
                  ?.copyWith(color: theme.colorScheme.primary)),
          RadioListTile<ThemeMode>(
              title: const Text('Light'),
              value: ThemeMode.light,
              groupValue: themeProvider.themeMode,
              onChanged: (v) =>
                  v != null ? themeProvider.setThemeMode(v) : null,
              secondary:
                  Icon(Icons.wb_sunny, color: theme.colorScheme.primary)),
          RadioListTile<ThemeMode>(
              title: const Text('Dark'),
              value: ThemeMode.dark,
              groupValue: themeProvider.themeMode,
              onChanged: (v) =>
                  v != null ? themeProvider.setThemeMode(v) : null,
              secondary: Icon(Icons.nightlight_round,
                  color: theme.colorScheme.primary)),
          RadioListTile<ThemeMode>(
              title: const Text('System'),
              subtitle: const Text('Follows phone settings'),
              value: ThemeMode.system,
              groupValue: themeProvider.themeMode,
              onChanged: (v) =>
                  v != null ? themeProvider.setThemeMode(v) : null,
              secondary: Icon(Icons.settings_brightness,
                  color: theme.colorScheme.primary)),
          const Divider(height: 32),

          // Section API Keys
          Text('API Keys & Integrations',
              style: theme.textTheme.titleLarge
                  ?.copyWith(color: theme.colorScheme.primary)),
          const SizedBox(height: 8),
          Text(
              '(Keys are saved for your account: ${user?.email ?? user?.uid ?? "Unknown"})',
              style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          Text('New York Times (News)', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.textTheme.bodyMedium?.color),
                children: [
                  const TextSpan(text: 'Get your free API key at the '),
                  TextSpan(
                    text: 'NYT Developer Portal',
                    style: TextStyle(
                        color: theme.colorScheme.primary,
                        decoration: TextDecoration.underline),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        _launchUrl('https://developer.nytimes.com/');
                      },
                  ),
                  const TextSpan(text: '.'),
                ]),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _nytApiKeyController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'NYT API Key',
              hintText: 'Paste your NYT key here',
              border: const OutlineInputBorder(),
              prefixIcon: _isLoadingNytKey
                  ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(strokeWidth: 2)))
                  : const Icon(Icons.key),
              suffixIcon:
                  !_isLoadingNytKey && _nytApiKeyController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          tooltip: 'Clear NYT Key',
                          onPressed: _clearNytApiKey)
                      : null,
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _saveNytApiKey(),
          ),
          const SizedBox(height: 5),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            TextButton(
                onPressed: _clearNytApiKey,
                child: const Text('Reset'),
                style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error)),
            const SizedBox(width: 8),
            ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Save NYT Key'),
                onPressed: _saveNytApiKey,
                style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary)),
          ]),
          const SizedBox(height: 24),
          Text('OpenAQ (Air Quality)', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.textTheme.bodyMedium?.color),
                children: [
                  const TextSpan(text: 'Get your free API key at the '),
                  TextSpan(
                    text: 'OpenAQ Platform',
                    style: TextStyle(
                        color: theme.colorScheme.primary,
                        decoration: TextDecoration.underline),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        _launchUrl('https://openaq.org/');
                      },
                  ),
                  const TextSpan(
                      text: '. Required for air quality map markers.'),
                ]),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _openAqApiKeyController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'OpenAQ API Key',
              hintText: 'Paste your OpenAQ key here',
              border: const OutlineInputBorder(),
              prefixIcon: _isLoadingOpenAqKey
                  ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(strokeWidth: 2)))
                  : const Icon(Icons.air),
              suffixIcon: !_isLoadingOpenAqKey &&
                      _openAqApiKeyController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: 'Clear OpenAQ Key',
                      onPressed: _clearOpenAqApiKey)
                  : null,
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _saveOpenAqApiKey(),
          ),
          const SizedBox(height: 5),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            TextButton(
                onPressed: _clearOpenAqApiKey,
                child: const Text('Reset'),
                style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error)),
            const SizedBox(width: 8),
            ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Save OpenAQ Key'),
                onPressed: _saveOpenAqApiKey,
                style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary)),
          ]),
        ],
      ),
    );
  }
}
