import 'package:flutter/gestures.dart'; // Importer pour RichText recognizer
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'package:url_launcher/url_launcher.dart'; // Pour ouvrir les liens

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
    // Initialise le Provider pour le thème au-dessus de l'application
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
    // Écoute les changements de thème via le Provider
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GreenWatch', // Titre de l'application
      themeMode: themeProvider.themeMode, // Mode de thème géré par le Provider
      theme: lightTheme,                 // Thème clair défini dans themes.dart
      darkTheme: darkTheme,               // Thème sombre défini dans themes.dart
      home: const HomePage(),           // Page d'accueil par défaut
      // Définition des routes nommées pour la navigation
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
  // Liste de citations environnementales
  final List<String> _quotes = [
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

  // Service API NYT et état pour les articles
  final NytApiService _nytService = NytApiService();
  Future<List<Article>>? _articlesFuture; // Le Future qui contient les articles (peut être null)
  bool _apiKeyMissing = false; // Indicateur : la clé API manque-t-elle ?
  String? _apiError;          // Stocke un message d'erreur spécifique de l'API

  @override
  void initState() {
    super.initState();
    // Sélectionne une citation aléatoire au démarrage
    _randomQuote = _quotes[Random().nextInt(_quotes.length)];
    // Vérifie la présence de la clé API et lance le fetch si elle existe
    _checkApiKeyAndFetch();
  }

  // Vérifie la clé API et lance la récupération des articles
  Future<void> _checkApiKeyAndFetch() async {
    final apiKey = await SettingsService.getNytApiKey();
    if (!mounted) return; // Vérifie si le widget est toujours monté

    if (apiKey == null || apiKey.isEmpty) {
      // Si la clé manque, met à jour l'état pour afficher le message approprié
      setState(() {
        _apiKeyMissing = true;
        _articlesFuture = null; // Pas de Future en cours
        _apiError = null;       // Pas d'erreur API spécifique
      });
    } else {
      // Si la clé existe, lance le fetch
      setState(() {
        _apiKeyMissing = false;
        _apiError = null;
        _articlesFuture = _nytService.fetchClimateArticles().catchError((e) {
          // Intercepte les erreurs directement depuis le Future
          if (!mounted) return <Article>[]; // Vérifie avant setState
          print("Error caught by _articlesFuture: $e");
          setState(() => _apiError = e is Exception ? e.toString().replaceFirst('Exception: ', '') : e.toString());
          // Retourne une liste vide pour que FutureBuilder n'affiche pas d'erreur non gérée
          return <Article>[];
        });
      });
    }
  }

  // Méthode appelée par RefreshIndicator ou le bouton Refresh
  Future<void> _refreshData() async {
    await _checkApiKeyAndFetch(); // Re-vérifie la clé et relance le fetch
  }

  // Fonction utilitaire pour ouvrir une URL
  Future<void> _launchUrl(String urlString) async {
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
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      print('Could not launch URL: $urlString');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open link: $urlString')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Accès au thème actuel

    return Scaffold(
      appBar: AppBar(
        title: const Text("GreenWatch 🌍"), // Titre de l'AppBar
        actions: [
          // Bouton Info (About Dialog)
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'About GreenWatch',
            onPressed: () {
              showAboutDialog(
                context: context,
                applicationName: "GreenWatch",
                applicationVersion: "1.0.0",
                applicationLegalese: "© 2025 GreenWatch",
              );
            },
          ),
          // Bouton Refresh (Articles)
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh articles',
            onPressed: _refreshData, // Appelle la méthode pour rafraîchir
          ),
        ],
      ),
      drawer: const CustomDrawer(), // Le menu latéral (Drawer)
      // Utilise RefreshIndicator pour le "tirer pour rafraîchir"
      body: RefreshIndicator(
        onRefresh: _refreshData, // Action à exécuter
        child: SingleChildScrollView(
          // Assure que le scroll est toujours possible pour activer RefreshIndicator
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 20.0), // Espace en bas
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, // Étire les enfants horizontalement
            children: [
              // --- Bannière Image ---
              Image.asset(
                "assets/nature.jpg", // Assure-toi que le chemin est correct
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              const SizedBox(height: 25),

              // --- Carte Citation ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Card(
                  elevation: 4.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _randomQuote,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // --- Titre Section Articles ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  "Latest Climate News (NYT)",
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 15),

              // --- Contenu Section Articles (Dynamique) ---
              _buildArticleContent(context), // Appelle la méthode pour construire cette partie

            ],
          ),
        ),
      ),
    );
  }

  // Construit le contenu de la section articles en fonction de l'état
  Widget _buildArticleContent(BuildContext context) {
    final theme = Theme.of(context);

    // Cas 1: La clé API NYT est manquante
    if (_apiKeyMissing) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
        child: Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.key_off, size: 40, color: theme.colorScheme.secondary),
                  const SizedBox(height: 15),
                  // Texte explicatif avec liens cliquables
                  RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                          style: theme.textTheme.bodyLarge?.copyWith(color: theme.textTheme.bodyLarge?.color), // Assure la couleur du thème
                          children: [
                            const TextSpan(text: 'To load news, please add your NYT API key in the '),
                            TextSpan( // Lien vers Settings
                              text: 'Settings',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.pushNamed(context, '/settings'); // Navigue vers Settings
                                },
                            ),
                            const TextSpan(text: '.\n\nYou can get one for free at the '),
                            TextSpan( // Lien vers le portail NYT
                              text: 'NYT Developer Portal',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  _launchUrl('https://developer.nytimes.com/'); // Ouvre le lien externe
                                },
                            ),
                            const TextSpan(text: '.'),
                          ]
                      )
                  ),
                  const SizedBox(height: 20),
                  // Bouton pour aller directement aux paramètres
                  ElevatedButton.icon(
                    icon: const Icon(Icons.settings),
                    label: const Text('Go to Settings'),
                    onPressed: () => Navigator.pushNamed(context, '/settings'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      foregroundColor: theme.colorScheme.onPrimaryContainer,
                    ),
                  )
                ]
            )
        ),
      );
    }
    // Cas 2: Une erreur API spécifique a été détectée avant ou pendant le fetch
    else if (_apiError != null) {
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: theme.colorScheme.error, size: 40),
              const SizedBox(height: 10),
              Text(
                "Could not load articles.",
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 5),
              // Affiche le message d'erreur spécifique
              Text(
                _apiError!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
              ),
              const SizedBox(height: 15),
              // Bouton conditionnel vers Settings si l'erreur concerne la clé
              if (_apiError!.toLowerCase().contains('key'))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.settings),
                    label: const Text('Check API Key'),
                    onPressed: () => Navigator.pushNamed(context, '/settings'),
                  ),
                ),
              // Bouton pour réessayer
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text("Retry"),
                onPressed: _refreshData, // Appelle la méthode de refresh
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.errorContainer,
                  foregroundColor: theme.colorScheme.onErrorContainer,
                ),
              )
            ],
          ),
        ),
      );
    }
    // Cas 3: Le Future a été initialisé (la clé existe), utilise FutureBuilder
    else if (_articlesFuture != null) {
      return FutureBuilder<List<Article>>(
        future: _articlesFuture, // Le Future à écouter
        builder: (context, snapshot) {
          // État: Chargement en cours
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: Padding(padding: EdgeInsets.all(30.0), child: CircularProgressIndicator()));
          }
          // État: Erreur non interceptée par .catchError (devrait être rare)
          else if (snapshot.hasError) {
            print("FutureBuilder Error (fallback): ${snapshot.error}");
            return Center(child: Padding(padding: const EdgeInsets.all(20), child: Text('An unexpected error occurred: ${snapshot.error}')));
          }
          // État: Données reçues (peut être une liste vide)
          else if (snapshot.hasData) {
            final articles = snapshot.data!;
            // Gère le cas où .catchError a retourné une liste vide (l'erreur est déjà affichée par la condition _apiError != null)
            if (articles.isEmpty && _apiError != null) {
              return const SizedBox.shrink(); // Ne rien afficher ici, l'erreur est gérée au-dessus
            }
            // Gère le cas où l'API retourne une liste vide sans erreur
            if (articles.isEmpty) {
              return const Center(child: Padding(padding: EdgeInsets.all(30.0), child: Text("No recent climate articles found.")));
            }
            // Affiche la liste des articles
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                children: articles.map((article) => ArticleCard(
                  article: article,
                  onTap: () => _launchUrl(article.webUrl), // Action au clic sur la carte
                )).toList(),
              ),
            );
          }
          // État initial ou inattendu
          else {
            return const Center(child: Padding(padding: EdgeInsets.all(30.0), child: Text("Loading...")));
          }
        },
      );
    }
    // Cas 4: État initial avant la fin de la vérification de la clé
    else {
      return const Center(child: Padding(padding: EdgeInsets.all(30.0), child: CircularProgressIndicator()));
    }
  }
}

// --- ArticleCard (Widget pour afficher une carte d'article) ---
class ArticleCard extends StatelessWidget {
  final Article article;
  final VoidCallback onTap; // Fonction appelée au clic

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
      clipBehavior: Clip.antiAlias, // L'image respecte les coins arrondis
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      child: InkWell( // Rend la carte cliquable
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Affiche l'image (si disponible)
            _buildImage(context),

            // Contenu texte (titre et extrait)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.headline,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis, // Ajoute "..." si trop long
                  ),
                  const SizedBox(height: 8),
                  Text(
                    article.snippet,
                    style: theme.textTheme.bodyMedium,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Construit la partie image de la carte avec gestion du chargement et des erreurs
  Widget _buildImage(BuildContext context) {
    const double imageHeight = 160.0;
    final placeholderColor = Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.3);
    final errorIconColor = Theme.of(context).colorScheme.onSecondaryContainer;

    if (article.imageUrl != null && article.imageUrl!.isNotEmpty) {
      return Image.network(
        article.imageUrl!,
        height: imageHeight,
        width: double.infinity,
        fit: BoxFit.cover,
        // Widget affiché pendant le chargement
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child; // Image chargée
          return Container(
            height: imageHeight,
            color: placeholderColor,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 2.0,
              ),
            ),
          );
        },
        // Widget affiché en cas d'erreur de chargement
        errorBuilder: (context, error, stackTrace) {
          print("Error loading image: ${article.imageUrl} -> $error");
          return Container(
            height: imageHeight,
            color: placeholderColor,
            child: Center(child: Icon(Icons.broken_image, color: errorIconColor, size: 40)),
          );
        },
      );
    } else {
      // Widget affiché si aucune URL d'image n'est fournie
      return Container(
        height: imageHeight / 1.5, // Plus petit si pas d'image
        color: placeholderColor,
        child: Center(child: Icon(Icons.image_not_supported, color: errorIconColor, size: 40)),
      );
    }
  }
}