// lib/models/air_quality_station.dart
import 'package:latlong2/latlong.dart';
import 'dart:convert'; // Pour utf8/latin1

class AirQualityStation {
  final int locationId;
  final String locationName;
  final LatLng coordinates;
  final List<String> parameters; // Noms des paramètres que la station PEUT mesurer
  List<Measurement> measurements; // Dernières mesures récupérées pour cette station (mutable via copyWith)
  final String? city;
  final String? country;

  AirQualityStation({
    required this.locationId,
    required this.locationName,
    required this.coordinates,
    required this.parameters,
    this.measurements = const [], // Initialise avec une liste vide par défaut
    this.city,
    this.country,
  });

  // Constructeur fromJson pour la réponse de /v3/locations
  factory AirQualityStation.fromJson(Map<String, dynamic> json) {
    LatLng coords = const LatLng(0, 0);
    if (json['coordinates'] != null && json['coordinates'] is Map) {
      final latNum = json['coordinates']['latitude']; final lonNum = json['coordinates']['longitude'];
      // Vérifie que lat/lon sont des nombres valides ET non (0,0)
      if (latNum is num && lonNum is num && (latNum.abs() > 0.0001 || lonNum.abs() > 0.0001)) {
        coords = LatLng(latNum.toDouble(), lonNum.toDouble());
      } else { print("[WARN AQModel Loc] Invalid or (0,0) coordinates: ${json['coordinates']}"); }
    } else { print("[WARN AQModel Loc] Missing 'coordinates' field."); }

    // Parse la liste des noms de paramètres depuis la liste 'sensors'
    List<String> paramNames = [];
    if (json['sensors'] != null && json['sensors'] is List) {
      for (var sensorObj in (json['sensors'] as List)) {
        if (sensorObj is Map<String, dynamic> && sensorObj['parameter'] is Map<String, dynamic>) {
          final parameterMap = sensorObj['parameter'] as Map<String, dynamic>;
          // Utilise la clé 'name' qui contient "pm25", "o3" etc.
          final paramCode = parameterMap['name'] as String?;
          if (paramCode != null && !paramNames.contains(paramCode)) {
            paramNames.add(paramCode);
          }
        }
      }
      paramNames.sort();
    } else { print("[WARN AQModel Loc] Missing or invalid 'sensors' list for loc id ${json['id']}."); }

    return AirQualityStation(
      locationId: json['id'] as int? ?? 0,
      locationName: _tryDecodeUtf8(json['name'] as String? ?? 'Unknown Location'),
      coordinates: coords,
      parameters: paramNames,
      measurements: const [], // Initialement vide, sera rempli par le service
      city: _tryDecodeUtf8(json['city'] as String? ?? json['locality'] as String? ?? 'N/A'),
      country: json['country'] is Map ? _tryDecodeUtf8(json['country']['name'] as String? ?? 'N/A') : 'N/A',
    );
  }

  static String _tryDecodeUtf8(String input) { try { return utf8.decode(latin1.encode(input)); } catch (_) { return input; } }

  // Méthode pour créer une copie avec les mesures mises à jour
  AirQualityStation copyWith({ List<Measurement>? measurements }) {
    return AirQualityStation(
      locationId: locationId, locationName: locationName, coordinates: coordinates, parameters: parameters,
      measurements: measurements ?? this.measurements, // Utilise les nouvelles mesures
      city: city, country: country,
    );
  }
}

// Classe Measurement adaptée pour parser la réponse de /v3/measurements
class Measurement {
  final int? locationId; // Renvoyé par /v3/measurements
  final String parameter;  // Nom court (ex: "pm25")
  final double value;
  final DateTime lastUpdated; // Heure UTC de la mesure
  final String unit;
  final String? locationName; // Optionnel
  final int? parameterId; // Renvoyé aussi par /v3/measurements

  Measurement({
    this.locationId,
    required this.parameter,
    required this.value,
    required this.lastUpdated,
    required this.unit,
    this.locationName,
    this.parameterId,
  });

  // fromJson adapté pour la réponse de /v3/measurements
  factory Measurement.fromJson(Map<String, dynamic> json, String? locName) {
    DateTime updated = DateTime.now().toUtc();
    final dateObject = json['date'];
    if (dateObject is Map && dateObject['utc'] is String) {
      updated = DateTime.tryParse(dateObject['utc'])?.toUtc() ?? updated;
    } else { print("[WARN Measurement] Missing 'date.utc'"); }

    final valueNum = json['value'] as num?;
    final String paramName = json['parameter'] as String? ?? 'unknown';
    final int? paramId = json['parameterId'] as int?;

    return Measurement(
      locationId: json['locationId'] as int?, // Lire l'ID
      parameter: paramName,
      value: valueNum?.toDouble() ?? -1.0, // Gère null
      lastUpdated: updated,
      unit: json['unit'] as String? ?? '',
      locationName: locName,
      parameterId: paramId,
    );
  }
}

// --- La classe LatestMeasurementResult n'est plus utilisée ---
/*
class LatestMeasurementResult { ... }
*/

// --- La Map PARAMETER_ID_TO_INFO n'est plus nécessaire car Measurement a le nom et l'unité ---
/*
const Map<int, Map<String, String>> PARAMETER_ID_TO_INFO = { ... };
*/