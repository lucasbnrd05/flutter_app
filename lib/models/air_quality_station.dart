// lib/models/air_quality_station.dart
import 'package:latlong2/latlong.dart';
import 'dart:convert';

class AirQualityStation {
  final int locationId;
  final String locationName;
  final LatLng coordinates;
  final List<String> parameters;
  List<Measurement> measurements;
  final String? city;
  final String? country;

  AirQualityStation({
    required this.locationId,
    required this.locationName,
    required this.coordinates,
    required this.parameters,
    this.measurements = const [],
    this.city,
    this.country,
  });

  factory AirQualityStation.fromJson(Map<String, dynamic> json) {
    LatLng coords = const LatLng(0, 0);
    if (json['coordinates'] != null && json['coordinates'] is Map) {
      final latNum = json['coordinates']['latitude'];
      final lonNum = json['coordinates']['longitude'];
      if (latNum is num &&
          lonNum is num &&
          (latNum.abs() > 0.0001 || lonNum.abs() > 0.0001)) {
        coords = LatLng(latNum.toDouble(), lonNum.toDouble());
      } else {
        print(
            "[WARN AQModel Loc] Invalid or (0,0) coordinates: ${json['coordinates']}");
      }
    } else {
      print("[WARN AQModel Loc] Missing 'coordinates' field.");
    }

    List<String> paramNames = [];
    if (json['sensors'] != null && json['sensors'] is List) {
      for (var sensorObj in (json['sensors'] as List)) {
        if (sensorObj is Map<String, dynamic> &&
            sensorObj['parameter'] is Map<String, dynamic>) {
          final parameterMap = sensorObj['parameter'] as Map<String, dynamic>;
          final paramCode = parameterMap['name'] as String?;
          if (paramCode != null && !paramNames.contains(paramCode)) {
            paramNames.add(paramCode);
          }
        }
      }
      paramNames.sort();
    } else {
      print(
          "[WARN AQModel Loc] Missing or invalid 'sensors' list for loc id ${json['id']}.");
    }

    return AirQualityStation(
      locationId: json['id'] as int? ?? 0,
      locationName:
      _tryDecodeUtf8(json['name'] as String? ?? 'Unknown Location'),
      coordinates: coords,
      parameters: paramNames,
      measurements: const [],
      city: _tryDecodeUtf8(
          json['city'] as String? ?? json['locality'] as String? ?? 'N/A'),
      country: json['country'] is Map
          ? _tryDecodeUtf8(json['country']['name'] as String? ?? 'N/A')
          : 'N/A',
    );
  }

  static String _tryDecodeUtf8(String input) {
    try {
      return utf8.decode(latin1.encode(input));
    } catch (_) {
      return input;
    }
  }

  AirQualityStation copyWith({List<Measurement>? measurements}) {
    return AirQualityStation(
      locationId: locationId, locationName: locationName,
      coordinates: coordinates, parameters: parameters,
      measurements: measurements ?? this.measurements,
      city: city, country: country,
    );
  }
}

class Measurement {
  final int? locationId;
  final String parameter;
  final double value;
  final DateTime lastUpdated;
  final String unit;
  final String? locationName;
  final int? parameterId;

  Measurement({
    this.locationId,
    required this.parameter,
    required this.value,
    required this.lastUpdated,
    required this.unit,
    this.locationName,
    this.parameterId,
  });

  factory Measurement.fromJson(Map<String, dynamic> json, String? locName) {
    DateTime updated = DateTime.now().toUtc();
    final dateObject = json['date'];
    if (dateObject is Map && dateObject['utc'] is String) {
      updated = DateTime.tryParse(dateObject['utc'])?.toUtc() ?? updated;
    } else {
      print("[WARN Measurement] Missing 'date.utc'");
    }

    final valueNum = json['value'] as num?;
    final String paramName = json['parameter'] as String? ?? 'unknown';
    final int? paramId = json['parameterId'] as int?;

    return Measurement(
      locationId: json['locationId'] as int?,
      parameter: paramName,
      value: valueNum?.toDouble() ?? -1.0,
      lastUpdated: updated,
      unit: json['unit'] as String? ?? '',
      locationName: locName,
      parameterId: paramId,
    );
  }
}