import 'package:flutter/gestures.dart'; // Importer pour RichText recognizer
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'package:url_launcher/url_launcher.dart'; // Pour ouvrir les liens
import 'package:intl/intl.dart'; // <--- AJOUTER L'IMPORT POUR LE FORMATAGE

// Importe les fichiers locaux du projet
import 'themes.dart';
import 'theme_provider.dart';
import 'ux_unit/custom_drawer.dart';
import 'about.dart';
import 'settings.dart';
import 'map.dart';
import 'models/article.dart';        // Modèle pour les articles
import 'services/nyt_service.dart';  // Service pour l'API NYT
import 'services/settings_service.dart'; // Service pour gérer les clés API

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      // ... (reste de MaterialApp inchangé) ...
      debugShowCheckedModeBanner: false,
      title: 'GreenWatch',
      themeMode: themeProvider.themeMode,
      theme: lightTheme,
      darkTheme: darkTheme,
      home: const HomePage(),
      routes: {
        '/home': (context) => const HomePage(),
        '/map': (context) => const MapPage(),
        '/about': (context) => const AboutPage(),
        '/settings': (context) => const SettingsPage(),
      },
    );
  }
}

// --- HomePage (Widget principal avec état) ---
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // ... (vos variables existantes : _quotes, _ecoTips, _nytService, etc. restent ici) ...
  final List<String> _quotes = [ /* ... citations ... */
    "🌍 \"The Earth does not belong to us, we borrow it from our children.\" – Antoine de Saint-Exupéry",
    "🌱 \"Nature always wears the colors of the spirit.\" – Ralph Waldo Emerson",
    "🌿 \"Look deep into nature, and then you will understand everything better.\" – Albert Einstein",
    "🍃 \"The greatest threat to our planet is the belief that someone else will save it.\" – Robert Swan",
    "🌎 \"What we save, saves us.\" – Wendell Berry",
    "🌳 \"The best time to plant a tree was 20 years ago. The second best time is now.\" – Chinese Proverb",
    "🌻 \"He that plants trees loves others besides himself.\" – Thomas Fuller",
    "🐝 \"We won’t have a society if we destroy the environment.\" – Margaret Mead",
    "☀️ \"Keep close to Nature’s heart.\" – John Muir",
    "🌊 \"Water and air, the two essential fluids on which all life depends, have become global garbage cans.\" – Jacques-Yves Cousteau",
  ];
  late String _randomQuote; // Pour stocker la citation affichée

  final List<String> _ecoTips = [ /* ... conseils ... */
    "💡 Reduce single-use plastics. Bring your own bags, bottles, and cups.",
    "💡 Save water: take shorter showers, fix leaks.",
    "💡 Sort your waste and recycle properly.",
    "💡 Opt for public transport, cycling, or walking.",
    "💡 Reduce meat consumption; try vegetarian meals.",
    "💡 Turn off lights and unplug unused devices.",
    "💡 Plant trees or support reforestation initiatives.",
    "💡 Buy local and seasonal food to reduce food miles.",
    "💡 Compost your organic waste.",
    "💡 Use eco-friendly cleaning products.",
  ];
  late String _randomEcoTip; // Pour stocker le conseil affiché

  // Service API NYT et état pour les articles
  final NytApiService _nytService = NytApiService();
  Future<List<Article>>? _articlesFuture;
  bool _apiKeyMissing = false;
  String? _apiError;


  @override
  void initState() {
    super.initState();
    _randomQuote = _quotes[Random().nextInt(_quotes.length)];
    _randomEcoTip = _ecoTips[Random().nextInt(_ecoTips.length)];
    _checkApiKeyAndFetch();

    // --- AJOUT : Afficher le popup après la première frame ---
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showWelcomeDialog(context);
    });
    // --------------------------------------------------------
  }

  // --- NOUVELLE FONCTION : Pour afficher le popup ---
  void _showWelcomeDialog(BuildContext context) {
    // Obtenir la date actuelle
    DateTime now = DateTime.now();
    // Formater la date en anglais (ex: "Friday, March 15, 2024")
    // Vous pouvez changer le format si vous préférez (ex: DateFormat.yMMMd('en_US'))
    String formattedDate = DateFormat.yMMMMEEEEd('en_US').format(now);

    showDialog(
      context: context,
      barrierDismissible: false, // L'utilisateur doit appuyer sur OK
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Welcome to GreenWatch! 👋'),
          content: Text(
            'Today is $formattedDate.\nLet\'s check the latest on our planet!',
            style: Theme.of(dialogContext).textTheme.bodyMedium,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Ferme le dialogue
              },
            ),
          ],
        );
      },
    );
  }
  // --------------------------------------------------

  // ... (le reste de vos fonctions : _refreshQuote, _refreshEcoTip, _checkApiKeyAndFetch, _refreshData, _launchUrl restent ici) ...

  void _refreshQuote() {
    setState(() {
      _randomQuote = _quotes[Random().nextInt(_quotes.length)];
    });
  }

  void _refreshEcoTip() {
    setState(() {
      _randomEcoTip = _ecoTips[Random().nextInt(_ecoTips.length)];
    });
  }

  Future<void> _checkApiKeyAndFetch() async {
    final apiKey = await SettingsService.getNytApiKey();
    if (!mounted) return;

    if (apiKey == null || apiKey.isEmpty) {
      setState(() {
        _apiKeyMissing = true;
        _articlesFuture = null;
        _apiError = null;
      });
    } else {
      setState(() {
        _apiKeyMissing = false;
        _apiError = null;
        _articlesFuture = _nytService.fetchClimateArticles().catchError((e) {
          if (!mounted) return <Article>[];
          print("Error caught by _articlesFuture: $e");
          setState(() => _apiError = e is Exception ? e.toString().replaceFirst('Exception: ', '') : e.toString());
          return <Article>[];
        });
      });
    }
  }

  Future<void> _refreshData() async {
    await _checkApiKeyAndFetch();
    _refreshQuote();
    _refreshEcoTip();
  }

  Future<void> _launchUrl(String urlString) async {
    // ... (code _launchUrl inchangé) ...
    final Uri url = Uri.parse(urlString);
    if (urlString.isEmpty) {
      print('Attempting to open an empty URL.');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Article link not available.')),
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
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open link: $urlString')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // --- Le reste de votre méthode build reste INCHANGÉ ---
    // Elle contient le Scaffold, AppBar, Drawer, RefreshIndicator, SingleChildScrollView,
    // Image, cartes Citation/Conseil, boutons d'action, et l'appel à _buildArticleContent.
    return Scaffold(
      appBar: AppBar(
        title: const Text("GreenWatch 🌍"),
        actions: [ /* ... actions ... */
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'About GreenWatch',
            onPressed: () { /* ... showAboutDialog ... */
              showAboutDialog(
                context: context,
                applicationName: "GreenWatch",
                applicationVersion: "1.0.0",
                applicationLegalese: "© 2024 GreenWatch",
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.only(top: 15),
                    child: Text('An application to follow climate news and explore environmental data.'),
                  )
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh articles',
            onPressed: _refreshData,
          ),
        ],
      ),
      drawer: const CustomDrawer(),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Bannière Image ---
              Image.asset("assets/nature.jpg", height: 200, width: double.infinity, fit: BoxFit.cover),
              const SizedBox(height: 25),

              // --- Carte Citation ---
              Padding( /* ... carte citation ... */
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Card(
                  elevation: 4.0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(child: Text(_randomQuote, textAlign: TextAlign.center, style: theme.textTheme.titleMedium?.copyWith(fontStyle: FontStyle.italic))),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(Icons.sync, color: theme.colorScheme.secondary), tooltip: 'New quote', onPressed: _refreshQuote,
                          iconSize: 20.0, visualDensity: VisualDensity.compact, padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // --- Carte Conseil Écolo ---
              Padding( /* ... carte conseil ... */
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Card(
                  elevation: 2.0, color: theme.colorScheme.secondaryContainer.withOpacity(0.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Expanded(child: Text(_randomEcoTip, textAlign: TextAlign.start, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSecondaryContainer))),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(Icons.sync, color: theme.colorScheme.primary), tooltip: 'New tip', onPressed: _refreshEcoTip,
                          iconSize: 18.0, visualDensity: VisualDensity.compact, padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // --- Actions Rapides ---
              Padding( /* ... boutons d'action ... */
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Wrap(
                  spacing: 12.0, runSpacing: 8.0, alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.map_outlined), label: const Text("View Map"),
                      onPressed: () => Navigator.pushNamed(context, '/map'),
                      style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.volunteer_activism_outlined), label: const Text("How to Help?"),
                      onPressed: () => _launchUrl('https://wwf.org/'),
                      style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), backgroundColor: theme.colorScheme.tertiaryContainer, foregroundColor: theme.colorScheme.onTertiaryContainer),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),


              // --- Titre Section Articles ---
              Padding( /* ... titre articles ... */
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text("Latest Climate News (NYT)", style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
              ),
              const SizedBox(height: 15),

              // --- Contenu Section Articles ---
              _buildArticleContent(context),

            ],
          ),
        ),
      ),
    );
  }

  // --- _buildArticleContent reste INCHANGÉ ---
  Widget _buildArticleContent(BuildContext context) {
    // ... (tout le code de _buildArticleContent reste le même)
    final theme = Theme.of(context);

    // Cas 1: La clé API NYT est manquante
    if (_apiKeyMissing) {
      return Padding( /* ... Message Clé manquante ... */
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
        child: Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.key_off, size: 40, color: theme.colorScheme.secondary),
                  const SizedBox(height: 15),
                  RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                          style: theme.textTheme.bodyLarge?.copyWith(color: theme.textTheme.bodyLarge?.color),
                          children: [
                            const TextSpan(text: 'To load news, please add your NYT API key in the '),
                            TextSpan( // Lien vers Settings
                              text: 'Settings',
                              style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                              recognizer: TapGestureRecognizer()..onTap = () { Navigator.pushNamed(context, '/settings'); },
                            ),
                            const TextSpan(text: '.\n\nYou can get one for free at the '),
                            TextSpan( // Lien vers le portail NYT
                              text: 'NYT Developer Portal',
                              style: TextStyle(color: theme.colorScheme.primary, decoration: TextDecoration.underline),
                              recognizer: TapGestureRecognizer()..onTap = () { _launchUrl('https://developer.nytimes.com/'); },
                            ),
                            const TextSpan(text: '.'),
                          ]
                      )
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.settings), label: const Text('Go to Settings'),
                    onPressed: () => Navigator.pushNamed(context, '/settings'),
                    style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primaryContainer, foregroundColor: theme.colorScheme.onPrimaryContainer),
                  )
                ]
            )
        ),
      );
    }
    // Cas 2: Erreur API
    else if (_apiError != null) {
      return Padding( /* ... Message Erreur API ... */
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: theme.colorScheme.error, size: 40),
              const SizedBox(height: 10),
              Text("Could not load articles.", textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
              const SizedBox(height: 5),
              Text(_apiError!, textAlign: TextAlign.center, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
              const SizedBox(height: 15),
              if (_apiError!.toLowerCase().contains('key'))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: ElevatedButton.icon(icon: const Icon(Icons.settings), label: const Text('Check API Key'), onPressed: () => Navigator.pushNamed(context, '/settings')),
                ),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh), label: const Text("Retry"), onPressed: _refreshData,
                style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.errorContainer, foregroundColor: theme.colorScheme.onErrorContainer),
              )
            ],
          ),
        ),
      );
    }
    // Cas 3: FutureBuilder pour les articles
    else if (_articlesFuture != null) {
      return FutureBuilder<List<Article>>( /* ... FutureBuilder ... */
        future: _articlesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: Padding(padding: EdgeInsets.all(30.0), child: CircularProgressIndicator()));
          }
          else if (snapshot.hasError) {
            print("FutureBuilder Error (fallback): ${snapshot.error}");
            return Center(child: Padding(padding: const EdgeInsets.all(20), child: Text('An unexpected error occurred: ${snapshot.error}')));
          }
          else if (snapshot.hasData) {
            final articles = snapshot.data!;
            if (articles.isEmpty && _apiError != null) { return const SizedBox.shrink(); }
            if (articles.isEmpty) { return const Center(child: Padding(padding: EdgeInsets.all(30.0), child: Text("No recent climate articles found."))); }
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(children: articles.map((article) => ArticleCard(article: article, onTap: () => _launchUrl(article.webUrl))).toList()),
            );
          }
          else { return const Center(child: Padding(padding: EdgeInsets.all(30.0), child: Text("Loading..."))); }
        },
      );
    }
    // Cas 4: Chargement initial
    else {
      return const Center(child: Padding(padding: EdgeInsets.all(30.0), child: CircularProgressIndicator()));
    }
  }
}

// --- ArticleCard reste INCHANGÉ ---
class ArticleCard extends StatelessWidget {
  // ... (tout le code d'ArticleCard reste le même) ...
  final Article article;
  final VoidCallback onTap;

  const ArticleCard({
    super.key,
    required this.article,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      elevation: 3.0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImage(context),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(article.headline, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Text(article.snippet, style: theme.textTheme.bodyMedium, maxLines: 3, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    const double imageHeight = 160.0;
    final placeholderColor = Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.3);
    final errorIconColor = Theme.of(context).colorScheme.onSecondaryContainer;

    if (article.imageUrl != null && article.imageUrl!.isNotEmpty) {
      String imageUrl = article.imageUrl!;
      if (!imageUrl.startsWith('http://') && !imageUrl.startsWith('https://')) {
        if(imageUrl.startsWith('images.')) { imageUrl = 'https://static01.nyt.com/$imageUrl'; }
        else if (imageUrl.startsWith('www.')){ imageUrl = 'https://$imageUrl'; }
        else { imageUrl = 'https://$imageUrl'; print("Applying generic https:// prefix to image URL: $imageUrl"); }
      }

      return Image.network(imageUrl, height: imageHeight, width: double.infinity, fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(height: imageHeight, color: placeholderColor, child: Center(child: CircularProgressIndicator(value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null, strokeWidth: 2.0)));
        },
        errorBuilder: (context, error, stackTrace) {
          print("Error loading image: ${article.imageUrl} (processed as $imageUrl) -> $error");
          return Container(height: imageHeight, color: placeholderColor, child: Center(child: Icon(Icons.broken_image, color: errorIconColor, size: 40)));
        },
      );
    } else {
      return Container(height: imageHeight / 1.5, color: placeholderColor, child: Center(child: Icon(Icons.image_not_supported, color: errorIconColor, size: 40)));
    }
  }
}