import 'package:hive/hive.dart';

part 'piece_detachee.g.dart';

@HiveType(typeId: 7)
class PieceDetachee extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String reference;

  @HiveField(2)
  String nom;

  @HiveField(3)
  String categorie; // Compresseur, Thermostat, Moteur

  @HiveField(4)
  int quantiteStock;

  @HiveField(5)
  int seuilMin;

  @HiveField(6)
  double prixUnitaire;

  @HiveField(7)
  List<String> modelesCompatibles;

  PieceDetachee({
    required this.id,
    required this.reference,
    required this.nom,
    required this.categorie,
    required this.quantiteStock,
    this.seuilMin = 5,
    required this.prixUnitaire,
    this.modelesCompatibles = const [],
  });

  factory PieceDetachee.fromJson(Map<String, dynamic> json) {
    return PieceDetachee(
      id: json['id'] ?? '',
      reference: json['reference'] ?? '',
      nom: json['nom'] ?? '',
      categorie: json['categorie'] ?? '',
      quantiteStock: json['quantite_stock'] ?? 0,
      seuilMin: json['seuil_min'] ?? 5,
      prixUnitaire: json['prix_unitaire'] ?? 0.0,
      modelesCompatibles: List<String>.from(json['modeles_compatibles'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reference': reference,
      'nom': nom,
      'categorie': categorie,
      'quantite_stock': quantiteStock,
      'seuil_min': seuilMin,
      'prix_unitaire': prixUnitaire,
      'modeles_compatibles': modelesCompatibles,
    };
  }
}