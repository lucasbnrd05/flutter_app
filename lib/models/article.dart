// lib/models/article.dart
class Article {
  final String headline;
  final String snippet;
  final String webUrl;
  final String? imageUrl; // L'image peut être absente

  Article({
    required this.headline,
    required this.snippet,
    required this.webUrl,
    this.imageUrl,
  });

  // Méthode factory pour créer un Article depuis un objet JSON reçu de l'API NYT
  factory Article.fromJson(Map<String, dynamic> json) {
    String? imageUrl;
    // L'API NYT renvoie les images dans le champ 'multimedia' (une liste)
    if (json['multimedia'] != null && (json['multimedia'] as List).isNotEmpty) {
      // On cherche une image utilisable (par exemple, la première)
      // Note: Les URL des images NYT sont souvent relatives au domaine nytimes.com
      try {
        // Prend la première image qui a une URL non vide
        var validImage = (json['multimedia'] as List).firstWhere(
              (img) => img != null && img['url'] != null && img['url'].isNotEmpty,
          orElse: () => null, // Si aucune image valide n'est trouvée
        );
        if (validImage != null) {
          imageUrl = "https://www.nytimes.com/${validImage['url']}";
        }
      } catch (e) {
        print("Erreur lors de l'extraction de l'image: $e");
        // imageUrl reste null
      }
    }

    return Article(
      // Utilise l'opérateur '??' pour fournir une valeur par défaut si null
      headline: json['headline']?['main'] ?? 'Titre non disponible',
      // Prend 'abstract' en priorité, sinon 'snippet'
      snippet: json['abstract'] ?? json['snippet'] ?? 'Extrait non disponible',
      webUrl: json['web_url'] ?? '', // Important d'avoir une URL, même vide si non trouvée
      imageUrl: imageUrl, // Peut être null
    );
  }
}