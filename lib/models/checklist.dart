import 'package:hive/hive.dart';

part 'checklist.g.dart';

@HiveType(typeId: 5)
class Checklist extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String interventionId;

  @HiveField(2)
  String type; // Maintenance, Reparation, Installation

  @HiveField(3)
  List<ChecklistItem> items;

  @HiveField(4)
  DateTime dateCompletion;

  @HiveField(5)
  bool complete;

  Checklist({
    required this.id,
    required this.interventionId,
    required this.type,
    required this.items,
    required this.dateCompletion,
    this.complete = false,
  });

  factory Checklist.fromJson(Map<String, dynamic> json) {
    return Checklist(
      id: json['id'] ?? '',
      interventionId: json['intervention_id'] ?? '',
      type: json['type'] ?? 'Maintenance',
      items: (json['items'] as List? ?? [])
          .map((item) => ChecklistItem.fromJson(item))
          .toList(),
      dateCompletion: json['date_completion'] != null
          ? DateTime.parse(json['date_completion'])
          : DateTime.now(),
      complete: json['complete'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'intervention_id': interventionId,
      'type': type,
      'items': items.map((item) => item.toJson()).toList(),
      'date_completion': dateCompletion.toIso8601String(),
      'complete': complete,
    };
  }
}

@HiveType(typeId: 6)
class ChecklistItem extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String description;

  @HiveField(2)
  bool verifie;

  @HiveField(3)
  String? observation;

  @HiveField(4)
  List<String> photos;

  @HiveField(5)
  bool obligatoire;

  ChecklistItem({
    required this.id,
    required this.description,
    this.verifie = false,
    this.observation,
    this.photos = const [],
    this.obligatoire = true,
  });

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: json['id'] ?? '',
      description: json['description'] ?? '',
      verifie: json['verifie'] ?? false,
      observation: json['observation'],
      photos: List<String>.from(json['photos'] ?? []),
      obligatoire: json['obligatoire'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'verifie': verifie,
      'observation': observation,
      'photos': photos,
      'obligatoire': obligatoire,
    };
  }
}