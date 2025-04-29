// lib/models/latest_measurement.dart
import 'package:latlong2/latlong.dart';

// Modèle simple pour parser UN résultat de /v3/parameters/{id}/latest
class LatestMeasurementResult {
  final DateTime datetimeUtc;
  final double value;
  final LatLng coordinates;
  final int parameterId;
  final int locationId;
  final int sensorId;

  LatestMeasurementResult._({
    required this.datetimeUtc, required this.value, required this.coordinates,
    required this.parameterId, required this.locationId, required this.sensorId,
  });

  static LatestMeasurementResult? fromJson(Map<String, dynamic> json, {required int parameterId}) {
    LatLng? coords;
    if (json['coordinates'] != null && json['coordinates'] is Map) {
      final coordMap = json['coordinates'] as Map<String, dynamic>;
      final latNum = coordMap['latitude']; final lonNum = coordMap['longitude'];
      if (latNum is num && lonNum is num && (latNum.abs() > 0.0001 || lonNum.abs() > 0.0001)) { coords = LatLng(latNum.toDouble(), lonNum.toDouble()); }
      else { return null; }
    } else { return null; }

    DateTime dt = DateTime.now().toUtc();
    if (json['datetime'] != null && json['datetime'] is Map && json['datetime']['utc'] is String) { dt = DateTime.tryParse(json['datetime']['utc'])?.toUtc() ?? dt; }
    else if (json['date'] != null && json['date'] is Map && json['date']['utc'] is String) { dt = DateTime.tryParse(json['date']['utc'])?.toUtc() ?? dt; }
    else { print("[WARN LatestMeasurementResult] Missing or invalid date field ('datetime.utc' or 'date.utc'): ${json['datetime'] ?? json['date']}"); }

    final valueNum = json['value'] as num?;
    final double value = valueNum?.toDouble() ?? -1.0;
    final locationId = json['locationsId'] as int?;
    final sensorId = json['sensorsId'] as int?;

    if (locationId == null || locationId == 0 || sensorId == null || sensorId == 0) { return null; }

    return LatestMeasurementResult._(
      datetimeUtc: dt, value: value, coordinates: coords, parameterId: parameterId,
      locationId: locationId, sensorId: sensorId,
    );
  }
}

// *** MAP STATIQUE ID -> INFO (AVEC DESCRIPTIONS AJOUTÉES) ***
const Map<int, Map<String, String>> PARAMETER_ID_TO_INFO = {
  1: {'name': 'pm10', 'unit': 'µg/m³', 'description': 'Particulate Matter < 10µm: Dust, pollen, mold spores. Can irritate eyes, nose, throat.'},
  2: {'name': 'pm25', 'unit': 'µg/m³', 'description': 'Fine Particulate Matter < 2.5µm: Combustion particles, organic compounds. Can penetrate deep into lungs.'},
  3: {'name': 'o3', 'unit': 'µg/m³', 'description': 'Ozone (mass): Ground-level ozone, a major component of smog. Irritates airways.'},
  4: {'name': 'co', 'unit': 'µg/m³', 'description': 'Carbon Monoxide (mass): Toxic gas from incomplete combustion. Reduces oxygen in blood.'},
  5: {'name': 'no2', 'unit': 'µg/m³', 'description': 'Nitrogen Dioxide (mass): From traffic and combustion. Irritates lungs, contributes to smog/acid rain.'},
  6: {'name': 'so2', 'unit': 'µg/m³', 'description': 'Sulfur Dioxide (mass): From burning fossil fuels. Irritates respiratory tract, contributes to acid rain.'},
  7: {'name': 'no2', 'unit': 'ppm', 'description': 'Nitrogen Dioxide (volume): Volume concentration. Irritates lungs.'},
  8: {'name': 'co', 'unit': 'ppm', 'description': 'Carbon Monoxide (volume): Volume concentration. Toxic gas.'},
  9: {'name': 'so2', 'unit': 'ppm', 'description': 'Sulfur Dioxide (volume): Volume concentration. Respiratory irritant.'},
  10: {'name': 'o3', 'unit': 'ppm', 'description': 'Ozone (volume): Volume concentration. Component of smog.'},
  11: {'name': 'bc', 'unit': 'µg/m³', 'description': 'Black Carbon: Soot from combustion, component of PM2.5.'},
  19: {'name': 'pm1', 'unit': 'µg/m³', 'description': 'Ultrafine Particulate Matter < 1µm: Very small particles, can enter bloodstream.'},
  35: {'name': 'no', 'unit': 'ppm', 'description': 'Nitrogen Monoxide (volume): Precursor to NO2 and ozone.'},
  98: {'name': 'relativehumidity', 'unit': '%', 'description': 'Relative Humidity: Amount of water vapor in the air.'},
  100: {'name': 'temperature', 'unit': '°C', 'description': 'Ambient Air Temperature.'},
  125: {'name': 'um003', 'unit': 'particles/cm³', 'description': 'Particle Count (> 0.3µm): Number of particles larger than 0.3 micrometers.'},
  19840: {'name': 'nox', 'unit': 'ppm', 'description': 'Nitrogen Oxides (volume): Combined NO and NO2.'},
  19843: {'name': 'no', 'unit': 'µg/m³', 'description': 'Nitrogen Monoxide (mass): Precursor pollutant.'},
  // Ajouter d'autres IDs et descriptions si nécessaire
};