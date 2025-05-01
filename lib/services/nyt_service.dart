// lib/services/nyt_service.dart

import 'dart:async'; // Pour Future et TimeoutException
import 'dart:convert'; // Pour json.decode
import 'dart:io'; // Pour SocketException

import 'package:http/http.dart' as http; // Importe le package http

// Importe tes modèles et services
import '../models/article.dart';
import 'settings_service.dart';

class NytApiService {
  // Méthode pour récupérer les articles sur le climat
  Future<List<Article>> fetchClimateArticles() async {
    print(
        '[DEBUG NytApiService] fetchClimateArticles: Attempting to fetch articles...');

    final apiKey = await SettingsService.getNytApiKey();

    // 1. Vérifier si la clé API existe
    if (apiKey == null || apiKey.isEmpty) {
      print('[DEBUG NytApiService] fetchClimateArticles: API Key is missing.');
      throw Exception('NYT API Key is missing. Please add it in Settings.');
    }

    // Calcul des dates pour la requête
    final now = DateTime.now();
    final oneMonthAgo = DateTime(now.year, now.month - 1, now.day);
    final String formattedEndDate =
        "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}";
    final String formattedBeginDate =
        "${oneMonthAgo.year}${oneMonthAgo.month.toString().padLeft(2, '0')}${oneMonthAgo.day.toString().padLeft(2, '0')}";

    print(
        '[DEBUG NytApiService] Date Range: $formattedBeginDate to $formattedEndDate');

    // 2. Construire l'URL
    final queryParams = {
      'q': 'climate change OR global warming OR environment',
      'begin_date': formattedBeginDate,
      'end_date': formattedEndDate,
      'sort': 'newest',
      'api-key': apiKey,
    };
    final url = Uri.https(
        'api.nytimes.com', '/svc/search/v2/articlesearch.json', queryParams);

    print(
        '[DEBUG NytApiService] fetchClimateArticles: Requesting URL (with dates): ${url.toString()}');

    try {
      // 3. Faire la requête HTTP GET avec Timeout
      final response = await http
          .get(url)
          .timeout(const Duration(seconds: 15)); // Ajout d'un timeout

      print(
          '[DEBUG NytApiService] fetchClimateArticles: Response Status Code: ${response.statusCode}');
      // print('[DEBUG NytApiService] fetchClimateArticles: Response Body (start): ${response.body.substring(0, (response.body.length > 300 ? 300 : response.body.length))}...');

      // 4. Vérifier le code de statut de la réponse
      if (response.statusCode == 200) {
        // Parsing JSON (reste identique)
        print(
            '[DEBUG NytApiService] fetchClimateArticles: Status OK (200). Parsing JSON...');
        try {
          final Map<String, dynamic> data = json.decode(response.body);
          if (data['status'] == 'OK' &&
              data.containsKey('response') &&
              data['response'] is Map) {
            final responseData = data['response'];
            if (responseData.containsKey('docs') &&
                responseData['docs'] is List) {
              final List<dynamic> results = responseData['docs'];
              print(
                  '[DEBUG NytApiService] fetchClimateArticles: JSON parsed successfully. Found ${results.length} documents in "docs" List.');
              List<Article> articles = [];
              for (var jsonDoc in results) {
                try {
                  articles.add(Article.fromJson(jsonDoc));
                } catch (e) {
                  print(
                      '[DEBUG NytApiService] fetchClimateArticles: Error parsing one article: $e. Skipping it.\nFaulty JSON: $jsonDoc');
                }
              }
              print(
                  '[DEBUG NytApiService] fetchClimateArticles: Successfully parsed ${articles.length} articles.');
              return articles;
            } else if (responseData['docs'] == null &&
                responseData.containsKey('metadata') &&
                responseData['metadata'] is Map &&
                responseData['metadata']['hits'] == 0) {
              print(
                  '[DEBUG NytApiService] fetchClimateArticles: JSON parsed successfully. Found 0 documents (docs: null, hits: 0). Returning empty list.');
              return <Article>[];
            } else {
              print(
                  '[DEBUG NytApiService] fetchClimateArticles: Unexpected structure within "response" object. Body: ${response.body}');
              throw Exception(
                  'Failed to parse articles: Unexpected structure in API response\'s "response" field.');
            }
          } else {
            print(
                '[DEBUG NytApiService] fetchClimateArticles: Status not OK or base response structure missing. Body: ${response.body}');
            throw Exception('Invalid API response format or status not OK.');
          }
        } catch (e) {
          print(
              '[DEBUG NytApiService] fetchClimateArticles: Error decoding JSON or processing response structure: $e');
          print(
              '[DEBUG NytApiService] fetchClimateArticles: Raw response body was: ${response.body}');
          throw Exception('Failed to process NYT response: $e');
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        // Gestion spécifique 401/403 (reste identique)
        print(
            '[DEBUG NytApiService] fetchClimateArticles: Authentication Error (${response.statusCode}). Check API Key validity and permissions.');
        print(
            '[DEBUG NytApiService] fetchClimateArticles: Response Body: ${response.body}');
        String errorMessage =
            'Invalid or unauthorized NYT API Key (Code: ${response.statusCode}).';
        try {
          final errorData = json.decode(response.body);
          if (errorData['fault'] != null &&
              errorData['fault']['faultstring'] != null) {
            errorMessage =
            'NYT API Error (${response.statusCode}): ${errorData['fault']['faultstring']}';
          }
        } catch (_) {}
        throw Exception(errorMessage);
      } else if (response.statusCode == 429) {
        // Gestion spécifique 429 (reste identique)
        print(
            '[DEBUG NytApiService] fetchClimateArticles: Rate Limit Exceeded (429). Too many requests.');
        print(
            '[DEBUG NytApiService] fetchClimateArticles: Response Body: ${response.body}');
        String errorMessage =
            'NYT API rate limit exceeded (Code: ${response.statusCode}). Please wait and try again later.';
        throw Exception(errorMessage);
      } else {
        // Autres erreurs HTTP (reste identique)
        print(
            '[DEBUG NytApiService] fetchClimateArticles: Failed to load articles. Status Code: ${response.statusCode}');
        print(
            '[DEBUG NytApiService] fetchClimateArticles: Response Body: ${response.body}');
        throw Exception(
            'Failed to load articles from NYT (Code: ${response.statusCode})');
      }
      // ***** NOUVEAU : Catch spécifiques pour erreurs réseau *****
    } on SocketException catch (e) {
      print(
          '[DEBUG NytApiService] fetchClimateArticles: Network Error (SocketException): $e');
      throw Exception(
          'Network Error: Could not reach NYT servers. Please check your internet connection.');
    } on TimeoutException catch (e) {
      print(
          '[DEBUG NytApiService] fetchClimateArticles: Network Timeout Error: $e');
      throw Exception(
          'Network Timeout: The request to NYT took too long to respond.');
      // **********************************************************
    } catch (e) {
      // Catch générique pour autres erreurs imprévues
      print(
          '[DEBUG NytApiService] fetchClimateArticles: Error during HTTP request or processing: $e');
      // Relance l'exception pour qu'elle soit gérée par l'appelant (ex: HomePage)
      // ou transforme en une exception plus générique si nécessaire.
      // Si e est déjà une Exception, on peut la relancer directement.
      // Sinon, on l'encapsule.
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('An unexpected error occurred: $e');
      }
    }
  }
}