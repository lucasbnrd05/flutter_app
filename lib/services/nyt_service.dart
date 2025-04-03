// lib/services/nyt_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/article.dart';      // Importe le modèle Article
import '../config/api_config.dart';  // Importe la configuration (pour la clé API)

class NytApiService {
  // L'URL de base de l'API Article Search
  static const String _baseUrl = "https://api.nytimes.com/svc/search/v2/articlesearch.json";

  // Méthode pour récupérer les 10 derniers articles sur le climat
  Future<List<Article>> fetchClimateArticles() async {
    // Prépare les paramètres de la requête
    final queryParams = {
      'api-key': nytApiKey, // Utilise la clé API depuis api_config.dart
      // 'fq' (filter query) pour cibler les sujets/sections liés au climat/environnement
      'fq': 'news_desk:("Climate") OR section_name:("Climate", "Environment") OR subject:("Global Warming", "Climate Change", "Environment", "Greenhouse Gas Emissions")',
      'sort': 'newest', // Trie par les plus récents
      // 'fl' (field list) pour ne récupérer que les champs nécessaires
      'fl': 'headline,abstract,snippet,web_url,multimedia,pub_date',
      // L'API utilise la pagination, la taille par défaut est souvent 10,
      // donc on n'a pas besoin de spécifier 'page_size' explicitement pour en avoir 10.
    };

    // Construit l'URI complète avec les paramètres
    final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams);

    print("Appel API NYT : $uri"); // Utile pour le débogage

    try {
      // Effectue la requête GET
      final response = await http.get(uri);

      // Vérifie si la requête a réussi (code 200 OK)
      if (response.statusCode == 200) {
        // Décode la réponse JSON (qui est une chaîne de caractères) en Map Dart
        final data = json.decode(response.body);

        // Vérifie la structure attendue de la réponse NYT
        if (data['status'] == 'OK' && data['response'] != null && data['response']['docs'] != null) {
          // Extrait la liste des documents (articles)
          final List<dynamic> results = data['response']['docs'];

          // Transforme chaque objet JSON de la liste en objet Article
          // et s'assure de ne prendre que les 10 premiers (au cas où l'API en renverrait plus)
          List<Article> articles = results
              .map((jsonArticle) => Article.fromJson(jsonArticle))
              .take(10) // Prend les 10 premiers
              .toList();

          print("Articles récupérés: ${articles.length}"); // Log
          return articles;

        } else {
          // La structure de la réponse n'est pas celle attendue
          print('Erreur de structure de réponse API NYT: ${response.body}');
          throw Exception('Format de réponse API invalide ou statut non OK.');
        }
      } else {
        // Gère les autres codes d'erreur HTTP (ex: 401 Unauthorized, 429 Too Many Requests)
        print('Erreur API NYT: ${response.statusCode} - ${response.body}');
        throw Exception('Échec du chargement des articles (Code: ${response.statusCode})');
      }
    } catch (e) {
      // Gère les erreurs réseau (pas de connexion) ou de décodage JSON
      print('Erreur lors de la récupération des articles NYT: $e');
      throw Exception('Erreur de connexion ou de traitement des données: $e');
    }
  }
}