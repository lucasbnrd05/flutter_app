// lib/services/nyt_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/article.dart';
import 'settings_service.dart'; // Importe le nouveau service

class NytApiService {
  static const String _baseUrl = "https://api.nytimes.com/svc/search/v2/articlesearch.json";

  Future<List<Article>> fetchClimateArticles() async {
    // 1. Récupérer la clé API depuis les préférences
    final String? apiKey = await SettingsService.getNytApiKey();

    // 2. Vérifier si la clé existe
    if (apiKey == null || apiKey.isEmpty) {
      print("Clé API NYT manquante ou vide dans les paramètres.");
      // Retourne une exception spécifique pour indiquer le problème
      throw Exception('NYT API Key is missing. Please add it in settings.');
    }

    final queryParams = {
      'api-key': apiKey, // Utilise la clé récupérée
      'fq': 'news_desk:("Climate") OR section_name:("Climate", "Environment") OR subject:("Global Warming", "Climate Change", "Environment", "Greenhouse Gas Emissions")',
      'sort': 'newest',
      'fl': 'headline,abstract,snippet,web_url,multimedia,pub_date',
    };

    final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams);
    print("Appel API NYT : $uri");

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['response'] != null && data['response']['docs'] != null) {
          final List<dynamic> results = data['response']['docs'];
          List<Article> articles = results
              .map((jsonArticle) => Article.fromJson(jsonArticle))
              .take(10)
              .toList();
          print("Articles récupérés: ${articles.length}");
          return articles;
        } else {
          print('Erreur de structure de réponse API NYT: ${response.body}');
          // Essayer de donner une erreur plus précise si possible (ex: clé invalide)
          if (response.body.toLowerCase().contains("invalid api key")) {
            throw Exception('Invalid NYT API Key.');
          }
          throw Exception('Invalid API response format or status not OK.');
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        print('Erreur API NYT: ${response.statusCode} - ${response.body}');
        throw Exception('Invalid or unauthorized NYT API Key.');
      } else if (response.statusCode == 429) {
        print('Erreur API NYT: ${response.statusCode} - ${response.body}');
        throw Exception('NYT API rate limit exceeded. Try again later.');
      }
      else {
        print('Erreur API NYT: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load articles (Code: ${response.statusCode})');
      }
    } catch (e) {
      print('Erreur lors de la récupération des articles NYT: $e');
      // Renvoyer l'exception existante si ce n'est pas une des erreurs gérées ci-dessus
      if (e is Exception) {
        rethrow; // Renvoyer l'exception spécifique déjà créée
      }
      throw Exception('Connection or data processing error: $e');
    }
  }
}