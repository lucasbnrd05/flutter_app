// lib/models/article.dart

import 'dart:math';

class Article {
  final String headline;
  final String snippet;
  final String webUrl;
  final String? imageUrl;

  Article({
    required this.headline,
    required this.snippet,
    required this.webUrl,
    this.imageUrl,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    String headline = 'No headline available';
    if (json['headline'] != null &&
        json['headline'] is Map &&
        json['headline']['main'] != null) {
      headline = json['headline']['main'];
    } else {
      print(
          '[DEBUG ArticleModel] fromJson: Warning - Missing or invalid headline[\'main\'] in JSON: ${json['headline']}');
    }

    String snippet =
        json['snippet'] ?? json['abstract'] ?? 'No description available';
    String webUrl = json['web_url'] ?? '';

    String? imageUrl;
    if (json['multimedia'] != null && json['multimedia'] is Map) {
      final multimediaMap = json['multimedia'] as Map<String, dynamic>;

      if (multimediaMap['default'] != null &&
          multimediaMap['default'] is Map &&
          multimediaMap['default']['url'] != null) {
        imageUrl = multimediaMap['default']['url'];
      } else if (multimediaMap['url'] != null &&
          multimediaMap['url'] is String) {
        imageUrl = multimediaMap['url'];
      } else {
        print(
            '[DEBUG ArticleModel] fromJson: Warning - Could not find a suitable image URL key (like \'default\' or \'url\') within the multimedia object: $multimediaMap');
      }
    } else {
      // Multimedia not found or not a Map
    }

    return Article(
      headline: headline,
      snippet: snippet,
      webUrl: webUrl,
      imageUrl: imageUrl,
    );
  }
}