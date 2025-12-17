import 'package:hive/hive.dart';

part 'intervention.g.dart';

@HiveType(typeId: 3)
class Intervention extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String code; // INT-2024-001

  @HiveField(2)
  String type; // Maintenance, Reparation, Urgence

  @HiveField(3)
  int priorite; // 1: Urgent, 2: Haute, 3: Normale

  @HiveField(4)
  String statut; // Planifiee, En_cours, Terminee, Annulee

  @HiveField(5)
  DateTime dateCreation;

  @HiveField(6)
  DateTime datePlanifiee;

  @HiveField(7)
  DateTime? dateDebut;

  @HiveField(8)
  DateTime? dateFin;

  @HiveField(9)
  List<String> technicienIds; // Plusieurs techniciens

  @HiveField(10)
  List<String> refrigerateurIds; // Plusieurs réfrigérateurs

  @HiveField(11)
  String description;

  @HiveField(12)
  String? rapportId; // Lien vers le rapport

  @HiveField(13)
  String? checklistId; // Lien vers la checklist

  @HiveField(14)
  String clientId; // Client concerné

  @HiveField(15)
  bool synchronise;

  @HiveField(16)
  DateTime updatedAt;

  Intervention({
    required this.id,
    required this.code,
    required this.type,
    required this.priorite,
    required this.statut,
    required this.dateCreation,
    required this.datePlanifiee,
    this.dateDebut,
    this.dateFin,
    required this.technicienIds,
    required this.refrigerateurIds,
    required this.description,
    this.rapportId,
    this.checklistId,
    required this.clientId,
    this.synchronise = false,
    required this.updatedAt,
  });

  factory Intervention.fromJson(Map<String, dynamic> json) {
    return Intervention(
      id: json['id'] ?? '',
      code: json['code'] ?? '',
      type: json['type'] ?? 'Maintenance',
      priorite: json['priorite'] ?? 3,
      statut: json['statut'] ?? 'Planifiee',
      dateCreation: json['date_creation'] != null
          ? DateTime.parse(json['date_creation'])
          : DateTime.now(),
      datePlanifiee: json['date_planifiee'] != null
          ? DateTime.parse(json['date_planifiee'])
          : DateTime.now(),
      dateDebut: json['date_debut'] != null
          ? DateTime.parse(json['date_debut'])
          : null,
      dateFin: json['date_fin'] != null
          ? DateTime.parse(json['date_fin'])
          : null,
      technicienIds: List<String>.from(json['technicien_ids'] ?? []),
      refrigerateurIds: List<String>.from(json['refrigerateur_ids'] ?? []),
      description: json['description'] ?? '',
      rapportId: json['rapport_id'],
      checklistId: json['checklist_id'],
      clientId: json['client_id'] ?? '',
      synchronise: json['synchronise'] ?? false,
      updatedAt: json['update_at'] != null
          ? DateTime.parse(json['update_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'type': type,
      'priorite': priorite,
      'statut': statut,
      'date_creation': dateCreation.toIso8601String(),
      'date_planifiee': datePlanifiee.toIso8601String(),
      'date_debut': dateDebut?.toIso8601String(),
      'date_fin': dateFin?.toIso8601String(),
      'technicien_ids': technicienIds,
      'refrigerateur_ids': refrigerateurIds,
      'description': description,
      'rapport_id': rapportId,
      'checklist_id': checklistId,
      'client_id': clientId,
      'synchronise': synchronise,
      'update_at': updatedAt.toIso8601String(),
    };
  }
}