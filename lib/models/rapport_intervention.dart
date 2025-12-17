import 'package:hive/hive.dart';

part 'rapport_intervention.g.dart';

@HiveType(typeId: 4)
class RapportIntervention extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String interventionId;

  @HiveField(2)
  String technicienId;

  @HiveField(3)
  DateTime dateRapport;

  @HiveField(4)
  String problemeDiagnostique;

  @HiveField(5)
  String actionsRealisees;

  @HiveField(6)
  List<String> piecesUtilisees; // IDs des pièces

  @HiveField(7)
  double tempsPasse; // en heures

  @HiveField(8)
  List<String> photosAvant;

  @HiveField(9)
  List<String> photosApres;

  @HiveField(10)
  String? signaturePath; // Chemin de la signature

  @HiveField(11)
  String observations;

  @HiveField(12)
  bool clientSatisfait;

  RapportIntervention({
    required this.id,
    required this.interventionId,
    required this.technicienId,
    required this.dateRapport,
    required this.problemeDiagnostique,
    required this.actionsRealisees,
    required this.piecesUtilisees,
    required this.tempsPasse,
    required this.photosAvant,
    required this.photosApres,
    this.signaturePath,
    required this.observations,
    this.clientSatisfait = true,
  });

  factory RapportIntervention.fromJson(Map<String, dynamic> json) {
    return RapportIntervention(
      id: json['id'] ?? '',
      interventionId: json['intervention_id'] ?? '',
      technicienId: json['technicien_id'] ?? '',
      dateRapport: json['date_rapport'] != null
          ? DateTime.parse(json['date_rapport'])
          : DateTime.now(),
      problemeDiagnostique: json['probleme_diagnostique'] ?? '',
      actionsRealisees: json['actions_realisees'] ?? '',
      piecesUtilisees: List<String>.from(json['pieces_utilisees'] ?? []),
      tempsPasse: json['temps_passe'] ?? 0.0,
      photosAvant: List<String>.from(json['photos_avant'] ?? []),
      photosApres: List<String>.from(json['photos_apres'] ?? []),
      signaturePath: json['signature_path'],
      observations: json['observations'] ?? '',
      clientSatisfait: json['client_satisfait'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'intervention_id': interventionId,
      'technicien_id': technicienId,
      'date_rapport': dateRapport.toIso8601String(),
      'probleme_diagnostique': problemeDiagnostique,
      'actions_realisees': actionsRealisees,
      'pieces_utilisees': piecesUtilisees,
      'temps_passe': tempsPasse,
      'photos_avant': photosAvant,
      'photos_apres': photosApres,
      'signature_path': signaturePath,
      'observations': observations,
      'client_satisfait': clientSatisfait,
    };
  }
}