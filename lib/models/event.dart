// lib/models/event.dart

class Event {
  final int? id; // Nullable car auto-incrémenté par la BDD lors de l'insertion
  final String type; // Ex: Flood, Drought, etc.
  final double latitude;
  final double longitude;
  final String description; // Champ texte pour la position/description
  final String timestamp;   // Stocké comme String ISO 8601 UTC

  Event({
    this.id, // Optionnel à la création
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.description,
    required this.timestamp,
  });

  // Méthode pour convertir un objet Event en Map<String, dynamic>
  // Utile pour l'insertion/mise à jour dans SQFlite
  // On n'inclut pas l'id ici car il est auto-géré par la BDD pour l'insertion
  Map<String, dynamic> toMap() {
    return {
      // 'id': id, // Ne pas inclure pour l'insertion si autoIncrement
      'type': type,
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
      'timestamp': timestamp, // Stocker en ISO 8601 UTC String
    };
  }

  // Méthode (factory constructor) pour créer un objet Event depuis une Map<String, dynamic>
  // Utile pour lire les données depuis SQFlite
  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'] as int?, // Lire l'ID depuis la map
      type: map['type'] as String? ?? 'Unknown Type',
      latitude: map['latitude'] as double? ?? 0.0,
      longitude: map['longitude'] as double? ?? 0.0,
      description: map['description'] as String? ?? 'No description',
      timestamp: map['timestamp'] as String? ?? DateTime.now().toUtc().toIso8601String(),
    );
  }

  // Optionnel: Override toString pour un débogage plus facile
  @override
  String toString() {
    return 'Event{id: $id, type: $type, latitude: $latitude, longitude: $longitude, description: $description, timestamp: $timestamp}';
  }
}