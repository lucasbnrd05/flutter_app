import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'package:url_launcher/url_launcher.dart'; // To open links

// Import local files
import 'themes.dart';
import 'theme_provider.dart';
import 'ux_unit/custom_drawer.dart'; // Make sure this path is correct
import 'about.dart';                  // Make sure this path is correct
import 'settings.dart';              // Make sure this path is correct
import 'map.dart';                   // Make sure this path is correct
import 'models/article.dart';        // Import the Article model
import 'services/nyt_service.dart';  // Import the API service

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
      debugShowCheckedModeBanner: false,
      title: 'GreenWatch', // App title
      themeMode: themeProvider.themeMode,
      theme: lightTheme, // Your light theme
      darkTheme: darkTheme, // Your dark theme
      home: const HomePage(),
      routes: {
        // Your existing routes
        '/home': (context) => const HomePage(),
        '/map': (context) => const MapPage(),
        '/about': (context) => const AboutPage(),
        '/settings': (context) => const SettingsPage(),
      },
    );
  }
}

// --- HomePage (Main Widget) ---
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Quotes
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
  late String _randomQuote;

  // API service instance and Future for articles
  final NytApiService _nytService = NytApiService();
  late Future<List<Article>> _articlesFuture;

  @override
  void initState() {
    super.initState();
    // Select a random quote
    _randomQuote = _quotes[Random().nextInt(_quotes.length)];
    // Start fetching articles right when the widget initializes
    _fetchArticles();
  }

  // Method to (re)start fetching articles
  void _fetchArticles() {
    setState(() {
      _articlesFuture = _nytService.fetchClimateArticles();
    });
  }

  // Utility function to open a URL in the browser
  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (urlString.isEmpty) {
      print('Attempting to open an empty URL.');
      if(mounted) { // Check if the widget is still in the tree
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Article link not available.')),
        );
      }
      return;
    }
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      // Handle the error if the URL cannot be launched
      print('Could not launch URL: $urlString');
      if(mounted) { // Check if the widget is still in the tree
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open link: $urlString')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("GreenWatch 🌍"), // AppBar title
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showAboutDialog(
                context: context,
                applicationName: "GreenWatch",
                applicationVersion: "1.0.0",
                applicationLegalese: "© 2025 GreenWatch", // Keep legalese as is usually
                // You can add more info here if needed
              );
            },
          ),
          // Add a button to refresh articles (optional)
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh articles', // Tooltip text
            onPressed: _fetchArticles, // Calls the method to reload
          ),
        ],
      ),
      drawer: const CustomDrawer(), // Your custom drawer
      body: SingleChildScrollView( // Allows scrolling if content overflows
        padding: const EdgeInsets.only(bottom: 20.0), // Space at the bottom
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch children horizontally
          children: [
            // --- Image Banner ---
            Image.asset(
              "assets/nature.jpg", // Make sure asset path is correct
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 25),

            // --- Quote Card ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                elevation: 4.0, // A bit of shadow
                shape: RoundedRectangleBorder( // Rounded corners
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _randomQuote,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                      // Color will adapt to the theme (light/dark)
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // --- Articles Section Title ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                "Latest Climate News (NYT)", // Section title
                style: theme.textTheme.headlineSmall, // More prominent title style
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 15),

            // --- List of Articles (via FutureBuilder) ---
            FutureBuilder<List<Article>>(
              future: _articlesFuture, // The Future we are listening to
              builder: (context, snapshot) {
                // 1. Loading in progress
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(30.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                // 2. Error during fetch
                else if (snapshot.hasError) {
                  print("FutureBuilder Error: ${snapshot.error}"); // Log for debugging
                  print("Stack trace: ${snapshot.stackTrace}");
                  return Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, color: theme.colorScheme.error, size: 40),
                          const SizedBox(height: 10),
                          Text(
                            "Could not load articles.", // Error message
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            // Display a simpler message to the user
                            "Check your internet connection or try again later.\n(${snapshot.error.toString().split(':').first})", // Hint about the error
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: 15),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.refresh),
                            label: const Text("Retry"), // Button text
                            onPressed: _fetchArticles,
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
                // 3. Data received successfully
                else if (snapshot.hasData) {
                  final articles = snapshot.data!;
                  // Case where the list is empty (API returned nothing)
                  if (articles.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(30.0),
                        child: Text("No recent climate articles found."), // Empty list message
                      ),
                    );
                  }
                  // Displaying articles in a column
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0), // Slight indent for the cards
                    child: Column(
                      // Creates an ArticleCard for each article in the list
                      children: articles.map((article) => ArticleCard(
                        article: article,
                        onTap: () => _launchUrl(article.webUrl), // Action on tap
                      )).toList(),
                    ),
                  );
                }
                // 4. Default case (should not happen if future is initialized correctly)
                else {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(30.0),
                      child: Text("Preparing to load..."), // Initial state text
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

// --- ArticleCard (Widget to display an article card) ---
class ArticleCard extends StatelessWidget {
  final Article article;
  final VoidCallback onTap; // Function to call on tap

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
      clipBehavior: Clip.antiAlias, // So the image respects the Card's rounded corners
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      child: InkWell( // Makes the card tappable
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Image Display ---
            _buildImage(context), // Use a separate method for clarity

            // --- Text Content (Title and Snippet) ---
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
                    maxLines: 2, // Limit title to 2 lines
                    overflow: TextOverflow.ellipsis, // Add '...' if too long
                  ),
                  const SizedBox(height: 8),
                  Text(
                    article.snippet,
                    style: theme.textTheme.bodyMedium,
                    maxLines: 3, // Limit snippet to 3 lines
                    overflow: TextOverflow.ellipsis, // Add '...' if too long
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Private method to build the image part of the card
  Widget _buildImage(BuildContext context) {
    const double imageHeight = 160.0; // Standard height for the image
    final placeholderColor = Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.3);
    final errorIconColor = Theme.of(context).colorScheme.onSecondaryContainer;

    // If the image URL exists and is not empty
    if (article.imageUrl != null && article.imageUrl!.isNotEmpty) {
      return Image.network(
        article.imageUrl!,
        height: imageHeight,
        width: double.infinity, // Takes the full width of the card
        fit: BoxFit.cover, // Covers the available space, may crop
        // Widget displayed while the image is loading
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child; // Image loaded
          return Container(
            height: imageHeight,
            color: placeholderColor,
            child: Center(
              child: CircularProgressIndicator(
                // Show progress if available
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 2.0,
              ),
            ),
          );
        },
        // Widget displayed if the image cannot be loaded
        errorBuilder: (context, error, stackTrace) {
          print("Error loading image: ${article.imageUrl} -> $error");
          return Container(
            height: imageHeight,
            color: placeholderColor,
            child: Center(child: Icon(Icons.broken_image, color: errorIconColor, size: 40)),
          );
        },
      );
    }
    // If no image URL is provided
    else {
      return Container(
        height: imageHeight / 1.5, // Smaller if no image
        color: placeholderColor,
        child: Center(child: Icon(Icons.image_not_supported, color: errorIconColor, size: 40)),
      );
    }
  }
}