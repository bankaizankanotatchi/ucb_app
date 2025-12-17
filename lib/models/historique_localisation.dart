import 'package:hive/hive.dart';

part 'historique_localisation.g.dart';

@HiveType(typeId: 11)
class HistoriqueLocalisation extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String technicienId;

  @HiveField(2)
  double latitude;

  @HiveField(3)
  double longitude;

  @HiveField(4)
  DateTime timestamp;

  @HiveField(5)
  String? interventionId;

  HistoriqueLocalisation({
    required this.id,
    required this.technicienId,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.interventionId,
  });

  factory HistoriqueLocalisation.fromJson(Map<String, dynamic> json) {
    return HistoriqueLocalisation(
      id: json['id'] ?? '',
      technicienId: json['technicien_id'] ?? '',
      latitude: json['latitude'] ?? 0.0,
      longitude: json['longitude'] ?? 0.0,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      interventionId: json['intervention_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'technicien_id': technicienId,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'intervention_id': interventionId,
    };
  }
}