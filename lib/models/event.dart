// lib/models/event.dart

class Event {
  final int? id;
  final String type;
  final double latitude;
  final double longitude;
  final String description;
  final String timestamp;

  Event({
    this.id,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.description,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
      'timestamp': timestamp,
    };
  }

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'] as int?,
      type: map['type'] as String? ?? 'Unknown Type',
      latitude: map['latitude'] as double? ?? 0.0,
      longitude: map['longitude'] as double? ?? 0.0,
      description: map['description'] as String? ?? 'No description',
      timestamp: map['timestamp'] as String? ??
          DateTime.now().toUtc().toIso8601String(),
    );
  }

  @override
  String toString() {
    return 'Event{id: $id, type: $type, latitude: $latitude, longitude: $longitude, description: $description, timestamp: $timestamp}';
  }
}