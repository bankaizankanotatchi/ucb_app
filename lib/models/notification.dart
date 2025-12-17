import 'package:hive/hive.dart';

part 'notification.g.dart';

@HiveType(typeId: 8)
class NotificationTech extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String titre;

  @HiveField(2)
  String message;

  @HiveField(3)
  String type; // Intervention, Stock, Systeme

  @HiveField(4)
  DateTime date;

  @HiveField(5)
  bool lue;

  @HiveField(6)
  String? interventionId;

  @HiveField(7)
  String? refrigerateurId;

  NotificationTech({
    required this.id,
    required this.titre,
    required this.message,
    required this.type,
    required this.date,
    this.lue = false,
    this.interventionId,
    this.refrigerateurId,
  });

  factory NotificationTech.fromJson(Map<String, dynamic> json) {
    return NotificationTech(
      id: json['id'] ?? '',
      titre: json['titre'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'Systeme',
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      lue: json['lue'] ?? false,
      interventionId: json['intervention_id'],
      refrigerateurId: json['refrigerateur_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titre': titre,
      'message': message,
      'type': type,
      'date': date.toIso8601String(),
      'lue': lue,
      'intervention_id': interventionId,
      'refrigerateur_id': refrigerateurId,
    };
  }
}