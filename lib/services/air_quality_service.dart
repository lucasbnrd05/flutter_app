// lib/services/air_quality_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/latest_measurement.dart';
import 'settings_service.dart';

class AirQualityService {
  final String _baseUrl = 'api.openaq.org';
  final String _parametersLatestBasePath = '/v3/parameters';

  // *** CHANGEMENT : Demander O3 (ID=3) par défaut ***
  Future<List<LatestMeasurementResult>> fetchGlobalLatestMeasurements({String parameterId = '3'}) async { // Default O3 (ID=3)
    print('[DEBUG AirQualityService] Fetching global V3 LATEST for parameter_id=$parameterId via specific endpoint...'); // Log mis à jour

    final apiKey = await SettingsService.getOpenAqApiKey();
    if (apiKey == null || apiKey.isEmpty) throw Exception('OpenAQ API Key missing.');

    final Map<String, String> queryParams = {
      'limit': '1000',
      'page': '1',
      'offset': '0',
      'sort': 'desc',
      'order_by': 'datetime',
    };

    final url = Uri.https( _baseUrl, '$_parametersLatestBasePath/$parameterId/latest', queryParams );
    print('[DEBUG AirQualityService] Requesting V3 PARAMETERS LATEST URL: ${url.toString()}');

    try {
      final response = await http.get(url, headers: {'accept': 'application/json', 'X-API-Key': apiKey});
      print('[DEBUG AirQualityService] Parameter V3 Latest Response Status: ${response.statusCode}');
      // print('[DEBUG AirQualityService] Parameter V3 Latest RAW BODY: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data.containsKey('results') && data['results'] is List) {
          final List<dynamic> results = data['results'];
          print('[DEBUG AirQualityService] Parameter V3 Latest Found ${results.length} results for parameter $parameterId.');
          List<LatestMeasurementResult> measurements = [];
          int parseErrors = 0;
          int skippedCount = 0;
          for (var resultJson in results) {
            if (resultJson is Map<String, dynamic>) {
              try {
                final measurement = LatestMeasurementResult.fromJson(resultJson, parameterId: int.tryParse(parameterId) ?? 0);
                if (measurement != null) { measurements.add(measurement); } else { skippedCount++; }
              } catch (e) { parseErrors++; print('[ERROR AirQualityService] Parameter V3 Latest Parse Error: $e\nJSON: $resultJson'); }
            }
          }
          print('[DEBUG AirQualityService] Parameter V3 Latest Successfully parsed ${measurements.length} measurements (skipped $skippedCount, $parseErrors parse errors).');
          return measurements;
        } else { throw Exception('Unexpected API /v3/parameters/{id}/latest response structure.'); }
      } else { // Gestion erreurs API
        String detail = response.body; try { final errorJson = json.decode(response.body); if (errorJson['detail'] != null) { detail = errorJson['detail'].toString(); } } catch (_) {}
        print('[ERROR AirQualityService] Parameter V3 Latest API Error ${response.statusCode}: $detail');
        throw Exception('Failed to load latest parameter measurements (Code: ${response.statusCode}). Detail: $detail');
      }
    } catch (e) { print('[ERROR AirQualityService] Parameter V3 Latest Network/Parse Error: $e'); rethrow; }
  }
}