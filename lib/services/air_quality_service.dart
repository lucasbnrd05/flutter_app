// lib/services/air_quality_service.dart
import 'dart:async'; // Pour TimeoutException
import 'dart:convert';
import 'dart:io'; // Pour SocketException

import 'package:http/http.dart' as http;
import '../models/latest_measurement.dart';
import 'settings_service.dart';

class AirQualityService {
  final String _baseUrl = 'api.openaq.org';
  final String _parametersLatestBasePath = '/v3/parameters';

  Future<List<LatestMeasurementResult>> fetchGlobalLatestMeasurements(
      {String parameterId = '3'}) async {
    // Default O3 (ID=3)
    print(
        '[DEBUG AirQualityService] Fetching global V3 LATEST for parameter_id=$parameterId via specific endpoint...');

    final apiKey = await SettingsService.getOpenAqApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('OpenAQ API Key missing. Please add it in Settings.');
    }

    final Map<String, String> queryParams = {
      'limit': '1000',
      'page': '1',
      'offset': '0',
      'sort': 'desc',
      'order_by': 'datetime',
    };

    final url = Uri.https(_baseUrl,
        '$_parametersLatestBasePath/$parameterId/latest', queryParams);
    print(
        '[DEBUG AirQualityService] Requesting V3 PARAMETERS LATEST URL: ${url.toString()}');

    try {
      // Ajout d'un timeout
      final response = await http.get(url, headers: {
        'accept': 'application/json',
        'X-API-Key': apiKey
      }).timeout(const Duration(seconds: 20)); // Timeout un peu plus long pour OpenAQ

      print(
          '[DEBUG AirQualityService] Parameter V3 Latest Response Status: ${response.statusCode}');
      // print('[DEBUG AirQualityService] Parameter V3 Latest RAW BODY: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data.containsKey('results') && data['results'] is List) {
          final List<dynamic> results = data['results'];
          print(
              '[DEBUG AirQualityService] Parameter V3 Latest Found ${results.length} results for parameter $parameterId.');
          List<LatestMeasurementResult> measurements = [];
          int parseErrors = 0;
          int skippedCount = 0;
          for (var resultJson in results) {
            if (resultJson is Map<String, dynamic>) {
              try {
                // Utilise le constructeur fromJson qui peut retourner null
                final measurement = LatestMeasurementResult.fromJson(resultJson,
                    parameterId: int.tryParse(parameterId) ?? 0);
                if (measurement != null) {
                  measurements.add(measurement);
                } else {
                  // Compte les objets JSON valides mais qui n'ont pas pu être parsés en objet valide
                  // (ex: coordonnées 0,0 ou id manquant comme géré dans fromJson)
                  skippedCount++;
                }
              } catch (e) {
                // Attrape les erreurs inattendues durant l'appel à fromJson
                parseErrors++;
                print(
                    '[ERROR AirQualityService] Parameter V3 Latest Parse Exception: $e\nJSON: $resultJson');
              }
            } else {
              // Si un élément de la liste 'results' n'est pas une Map
              parseErrors++;
              print(
                  '[ERROR AirQualityService] Unexpected item type in results list: $resultJson');
            }
          }
          print(
              '[DEBUG AirQualityService] Parameter V3 Latest Successfully parsed ${measurements.length} measurements (skipped $skippedCount invalid data points, encountered $parseErrors parsing errors).');
          return measurements;
        } else {
          throw Exception(
              'Unexpected API /v3/parameters/{id}/latest response structure (missing "results" list).');
        }
      } else {
        // Gestion erreurs API HTTP (ex: 4xx, 5xx)
        String detail = response.body;
        try {
          final errorJson = json.decode(response.body);
          if (errorJson['detail'] != null) {
            // Essaye de récupérer le message d'erreur détaillé de l'API OpenAQ
            detail = errorJson['detail'] is List
                ? errorJson['detail'][0]['msg'] ?? detail // Souvent une liste
                : errorJson['detail'].toString();
          }
        } catch (_) {
          // Si le corps n'est pas du JSON ou n'a pas la structure attendue
        }
        print(
            '[ERROR AirQualityService] Parameter V3 Latest API Error ${response.statusCode}: $detail');
        throw Exception(
            'Failed to load latest parameter measurements (Code: ${response.statusCode}). Detail: $detail');
      }
      // ***** NOUVEAU : Catch spécifiques pour erreurs réseau *****
    } on SocketException catch (e) {
      print(
          '[ERROR AirQualityService] Parameter V3 Latest Network Error (SocketException): $e');
      throw Exception(
          'Network Error: Could not reach OpenAQ servers. Please check your internet connection.');
    } on TimeoutException catch (e) {
      print(
          '[ERROR AirQualityService] Parameter V3 Latest Network Timeout Error: $e');
      throw Exception(
          'Network Timeout: The request to OpenAQ took too long to respond.');
      // **********************************************************
    } catch (e) {
      // Catch générique pour autres erreurs (ex: parsing JSON initial, etc.)
      print(
          '[ERROR AirQualityService] Parameter V3 Latest Network/Parse Error: $e');
      // Relance l'exception pour traitement dans l'UI (MapPage)
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('An unexpected error occurred fetching air quality data: $e');
      }
    }
  }
}