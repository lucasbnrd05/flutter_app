// lib/services/air_quality_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import '../models/latest_measurement.dart';
import 'settings_service.dart';

class AirQualityService {
  final String _baseUrl = 'api.openaq.org';
  final String _parametersLatestBasePath = '/v3/parameters';

  Future<List<LatestMeasurementResult>> fetchGlobalLatestMeasurements(
      {String parameterId = '3'}) async {
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
      final response = await http.get(url, headers: {
        'accept': 'application/json',
        'X-API-Key': apiKey
      }).timeout(const Duration(seconds: 20));

      print(
          '[DEBUG AirQualityService] Parameter V3 Latest Response Status: ${response.statusCode}');

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
                final measurement = LatestMeasurementResult.fromJson(resultJson,
                    parameterId: int.tryParse(parameterId) ?? 0);
                if (measurement != null) {
                  measurements.add(measurement);
                } else {
                  skippedCount++;
                }
              } catch (e) {
                parseErrors++;
                print(
                    '[ERROR AirQualityService] Parameter V3 Latest Parse Exception: $e\nJSON: $resultJson');
              }
            } else {
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
        String detail = response.body;
        try {
          final errorJson = json.decode(response.body);
          if (errorJson['detail'] != null) {
            detail = errorJson['detail'] is List
                ? errorJson['detail'][0]['msg'] ?? detail
                : errorJson['detail'].toString();
          }
        } catch (_) {
        }
        print(
            '[ERROR AirQualityService] Parameter V3 Latest API Error ${response.statusCode}: $detail');
        throw Exception(
            'Failed to load latest parameter measurements (Code: ${response.statusCode}). Detail: $detail');
      }
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
    } catch (e) {
      print(
          '[ERROR AirQualityService] Parameter V3 Latest Network/Parse Error: $e');
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('An unexpected error occurred fetching air quality data: $e');
      }
    }
  }
}