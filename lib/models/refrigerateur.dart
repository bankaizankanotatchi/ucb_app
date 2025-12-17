import 'package:hive/hive.dart';

part 'refrigerateur.g.dart';

@HiveType(typeId: 2)
class Refrigerateur extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String codeQR; // Unique

  @HiveField(2)
  String numeroSerie;

  @HiveField(3)
  String marque;

  @HiveField(4)
  String modele;

  @HiveField(5)
  String type; // Medical, Alimentaire, Industriel

  @HiveField(6)
  String clientId; // Propriétaire

  @HiveField(7)
  String adresse;

  @HiveField(8)
  double latitude;

  @HiveField(9)
  double longitude;

  @HiveField(10)
  String statut; // Fonctionnel, En_panne, Maintenance

  @HiveField(11)
  DateTime? dateInstallation;

  @HiveField(12)
  DateTime? dateDerniereMaintenance;

  @HiveField(13)
  Map<String, dynamic> caracteristiques; // Température, capacité, etc.

  // NOUVEAUX CHAMPS : Photos par catégorie
  @HiveField(14)
  List<String> photosAvantReparation; // Photos avant toute intervention

  @HiveField(15)
  List<String> photosPendantReparation; // Photos pendant les réparations

  @HiveField(16)
  List<String> photosApresReparation; // Photos après réparation complète

  @HiveField(17)
  DateTime? dateDernieresPhotos; // Date des dernières photos ajoutées

  @HiveField(18)
  String? dernierTechnicienPhotos; // ID du technicien qui a pris les dernières photos

  Refrigerateur({
    required this.id,
    required this.codeQR,
    required this.numeroSerie,
    required this.marque,
    required this.modele,
    required this.type,
    required this.clientId,
    required this.adresse,
    required this.latitude,
    required this.longitude,
    required this.statut,
    this.dateInstallation,
    this.dateDerniereMaintenance,
    this.caracteristiques = const {},
    this.photosAvantReparation = const [],
    this.photosPendantReparation = const [],
    this.photosApresReparation = const [],
    this.dateDernieresPhotos,
    this.dernierTechnicienPhotos,
  });

  factory Refrigerateur.fromJson(Map<String, dynamic> json) {
    return Refrigerateur(
      id: json['id'] ?? '',
      codeQR: json['code_qr'] ?? '',
      numeroSerie: json['numero_serie'] ?? '',
      marque: json['marque'] ?? '',
      modele: json['modele'] ?? '',
      type: json['type'] ?? 'Alimentaire',
      clientId: json['client_id'] ?? '',
      adresse: json['adresse'] ?? '',
      latitude: json['latitude'] ?? 0.0,
      longitude: json['longitude'] ?? 0.0,
      statut: json['statut'] ?? 'Fonctionnel',
      dateInstallation: json['date_installation'] != null
          ? DateTime.parse(json['date_installation'])
          : null,
      dateDerniereMaintenance: json['date_derniere_maintenance'] != null
          ? DateTime.parse(json['date_derniere_maintenance'])
          : null,
      caracteristiques: Map<String, dynamic>.from(json['caracteristiques'] ?? {}),
      photosAvantReparation: List<String>.from(json['photos_avant_reparation'] ?? []),
      photosPendantReparation: List<String>.from(json['photos_pendant_reparation'] ?? []),
      photosApresReparation: List<String>.from(json['photos_apres_reparation'] ?? []),
      dateDernieresPhotos: json['date_dernieres_photos'] != null
          ? DateTime.parse(json['date_dernieres_photos'])
          : null,
      dernierTechnicienPhotos: json['dernier_technicien_photos'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code_qr': codeQR,
      'numero_serie': numeroSerie,
      'marque': marque,
      'modele': modele,
      'type': type,
      'client_id': clientId,
      'adresse': adresse,
      'latitude': latitude,
      'longitude': longitude,
      'statut': statut,
      'date_installation': dateInstallation?.toIso8601String(),
      'date_derniere_maintenance': dateDerniereMaintenance?.toIso8601String(),
      'caracteristiques': caracteristiques,
      'photos_avant_reparation': photosAvantReparation,
      'photos_pendant_reparation': photosPendantReparation,
      'photos_apres_reparation': photosApresReparation,
      'date_dernieres_photos': dateDernieresPhotos?.toIso8601String(),
      'dernier_technicien_photos': dernierTechnicienPhotos,
    };
  }

  // ==================== MÉTHODES UTILITAIRES ====================

  /// Obtenir toutes les photos (toutes catégories confondues)
  List<String> get toutesLesPhotos {
    return [
      ...photosAvantReparation,
      ...photosPendantReparation,
      ...photosApresReparation,
    ];
  }

  /// Compter le nombre total de photos
  int get nombreTotalPhotos {
    return photosAvantReparation.length +
           photosPendantReparation.length +
           photosApresReparation.length;
  }

  /// Ajouter une photo dans une catégorie spécifique
  void ajouterPhoto(String cheminPhoto, String categorie, {String? technicienId}) {
    switch (categorie.toLowerCase()) {
      case 'avant':
        photosAvantReparation.add(cheminPhoto);
        break;
      case 'pendant':
        photosPendantReparation.add(cheminPhoto);
        break;
      case 'apres':
        photosApresReparation.add(cheminPhoto);
        break;
      default:
        throw ArgumentError('Catégorie invalide: $categorie. Utilisez "avant", "pendant" ou "apres"');
    }

    dateDernieresPhotos = DateTime.now();
    if (technicienId != null) {
      dernierTechnicienPhotos = technicienId;
    }
  }

  /// Obtenir les photos d'une catégorie spécifique
  List<String> getPhotosParCategorie(String categorie) {
    switch (categorie.toLowerCase()) {
      case 'avant':
        return photosAvantReparation;
      case 'pendant':
        return photosPendantReparation;
      case 'apres':
        return photosApresReparation;
      default:
        return [];
    }
  }

  /// Vérifier si le réfrigérateur a des photos
  bool get aDesPhotos {
    return photosAvantReparation.isNotEmpty ||
           photosPendantReparation.isNotEmpty ||
           photosApresReparation.isNotEmpty;
  }

  /// Obtenir la dernière photo ajoutée (toutes catégories)
  String? get dernierePhoto {
    if (photosApresReparation.isNotEmpty) {
      return photosApresReparation.last;
    }
    if (photosPendantReparation.isNotEmpty) {
      return photosPendantReparation.last;
    }
    if (photosAvantReparation.isNotEmpty) {
      return photosAvantReparation.last;
    }
    return null;
  }

  /// Vider toutes les photos d'une catégorie
  void viderPhotos(String categorie) {
    switch (categorie.toLowerCase()) {
      case 'avant':
        photosAvantReparation.clear();
        break;
      case 'pendant':
        photosPendantReparation.clear();
        break;
      case 'apres':
        photosApresReparation.clear();
        break;
      default:
        throw ArgumentError('Catégorie invalide');
    }
  }

  /// Obtenir un résumé des photos
  Map<String, int> get resumePhotos {
    return {
      'avant': photosAvantReparation.length,
      'pendant': photosPendantReparation.length,
      'apres': photosApresReparation.length,
      'total': nombreTotalPhotos,
    };
  }
}