import 'package:hive/hive.dart';

part 'technicien.g.dart';

@HiveType(typeId: 1)
class Technicien extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String matricule;

  @HiveField(2)
  String nom;

  @HiveField(3)
  String prenom;

  @HiveField(4)
  String telephone;

  @HiveField(5)
  String email;

  @HiveField(6)
  String motDePasse; // Hashé localement

  @HiveField(7)
  String specialite;

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  String? zoneAffectation;

  @HiveField(10)
  bool actif;

  Technicien({
    required this.id,
    required this.matricule,
    required this.nom,
    required this.prenom,
    required this.telephone,
    required this.email,
    required this.motDePasse,
    required this.specialite,
    required this.createdAt,
    this.zoneAffectation,
    this.actif = true,
  });

  factory Technicien.fromJson(Map<String, dynamic> json) {
    return Technicien(
      id: json['id'] ?? '',
      matricule: json['matricule'] ?? '',
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      telephone: json['telephone'] ?? '',
      email: json['email'] ?? '',
      motDePasse: json['mot_de_passe'] ?? '',
      specialite: json['specialite'] ?? 'Technicien',
      zoneAffectation: json['zone_affectation'],
      actif: json['actif'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'matricule': matricule,
      'nom': nom,
      'prenom': prenom,
      'telephone': telephone,
      'email': email,
      'mot_de_passe': motDePasse,
      'specialite': specialite,
      'zone_affectation': zoneAffectation,
      'actif': actif,
      'created_at': createdAt.toIso8601String(),
    };
  }
}