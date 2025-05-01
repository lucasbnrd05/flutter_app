// lib/models/article.dart

class Article {
  final String headline;
  final String
      snippet; // Utiliser 'snippet' qui est fourni, 'abstract' est aussi possible
  final String webUrl;
  final String? imageUrl; // L'URL de l'image peut être nulle

  Article({
    required this.headline,
    required this.snippet,
    required this.webUrl,
    this.imageUrl,
  });

  // Factory constructor pour créer une instance depuis un JSON
  factory Article.fromJson(Map<String, dynamic> json) {
    // --- DEBUG LOG ---
    // print('[DEBUG ArticleModel] fromJson: Parsing article. JSON keys: ${json.keys.toList()}');
    // print('[DEBUG ArticleModel] fromJson: Raw headline object: ${json['headline']}');
    // print('[DEBUG ArticleModel] fromJson: Raw multimedia object: ${json['multimedia']}'); // Changed log
    // --- FIN DEBUG LOG ---

    // Extraction du titre (headline)
    String headline = 'No headline available';
    if (json['headline'] != null &&
        json['headline'] is Map &&
        json['headline']['main'] != null) {
      headline = json['headline']['main'];
    } else {
      print(
          '[DEBUG ArticleModel] fromJson: Warning - Missing or invalid headline[\'main\'] in JSON: ${json['headline']}');
    }

    // Utilisation de 'snippet' ou 'abstract'
    String snippet =
        json['snippet'] ?? json['abstract'] ?? 'No description available';
    String webUrl = json['web_url'] ?? '';

    // ******************************************************
    // ****** CORRECTION ICI : Traiter multimedia comme Map ******
    // ******************************************************
    String? imageUrl;
    // Vérifie si 'multimedia' existe ET est une Map (objet JSON)
    if (json['multimedia'] != null && json['multimedia'] is Map) {
      // Accéder directement aux clés de l'objet multimedia
      final multimediaMap = json['multimedia'] as Map<String, dynamic>;

      // Essayer de récupérer l'URL depuis la clé 'default' ou une autre clé pertinente si 'default' n'existe pas
      // (Note: L'API NYT peut parfois retourner différents formats d'images ici)
      // On cherche une clé qui contient une URL valide. 'default' semble être un bon candidat.
      if (multimediaMap['default'] != null &&
          multimediaMap['default'] is Map &&
          multimediaMap['default']['url'] != null) {
        imageUrl = multimediaMap['default']['url'];
        // --- DEBUG LOG ---
        // print('[DEBUG ArticleModel] fromJson: Found image URL in multimedia[\'default\'][\'url\']: $imageUrl');
        // --- FIN LOG ---
      }
      // Ajoute d'autres `else if` ici pour vérifier d'autres clés possibles dans `multimediaMap` si nécessaire
      // Par exemple, parfois l'API peut retourner directement une clé 'url' au premier niveau de 'multimedia'
      else if (multimediaMap['url'] != null && multimediaMap['url'] is String) {
        imageUrl = multimediaMap['url'];
        // --- DEBUG LOG ---
        // print('[DEBUG ArticleModel] fromJson: Found image URL directly in multimedia[\'url\']: $imageUrl');
        // --- FIN LOG ---
      } else {
        // --- DEBUG LOG ---
        print(
            '[DEBUG ArticleModel] fromJson: Warning - Could not find a suitable image URL key (like \'default\' or \'url\') within the multimedia object: $multimediaMap');
        // --- FIN DEBUG LOG ---
      }
    } else {
      // --- DEBUG LOG ---
      // print('[DEBUG ArticleModel] fromJson: No multimedia object (Map) found or it is not a Map.');
      // --- FIN DEBUG LOG ---
    }
    // ******************************************************
    // ****** FIN DE LA CORRECTION pour multimedia     ******
    // ******************************************************

    // --- DEBUG LOG ---
    // print('[DEBUG ArticleModel] fromJson: Parsed -> headline: "$headline", snippet: "${snippet.substring(0, min(30, snippet.length))}...", webUrl: "$webUrl", imageUrl: ${imageUrl ?? "null"}');
    // --- FIN DEBUG LOG ---

    return Article(
      headline: headline,
      snippet: snippet, // Utilise la variable snippet définie ci-dessus
      webUrl: webUrl,
      imageUrl: imageUrl, // Peut être null
    );
  }
}
