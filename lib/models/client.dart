import 'package:hive/hive.dart';

part 'client.g.dart';

@HiveType(typeId: 9)
class Client extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String nom;

  @HiveField(2)
  String? contact;

  @HiveField(3)
  String telephone;

  @HiveField(4)
  String email;

  @HiveField(5)
  String adresse;

  @HiveField(6)
  double latitude;

  @HiveField(7)
  double longitude;

  @HiveField(8)
  String type; // Restaurant, Hopital, Supermarche

  @HiveField(9)
  List<String> refrigerateurIds;

  @HiveField(10)
  DateTime dateInscription;

  // NOUVEAU CHAMP : Liste simple de photos
  @HiveField(11)
  List<String> photos;

  Client({
    required this.id,
    required this.nom,
    this.contact,
    required this.telephone,
    required this.email,
    required this.adresse,
    required this.latitude,
    required this.longitude,
    required this.type,
    this.refrigerateurIds = const [],
    required this.dateInscription,
    this.photos = const [],
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'] ?? '',
      nom: json['nom'] ?? '',
      contact: json['contact'],
      telephone: json['telephone'] ?? '',
      email: json['email'] ?? '',
      adresse: json['adresse'] ?? '',
      latitude: json['latitude'] ?? 0.0,
      longitude: json['longitude'] ?? 0.0,
      type: json['type'] ?? 'Restaurant',
      refrigerateurIds: List<String>.from(json['refrigerateur_ids'] ?? []),
      dateInscription: json['date_inscription'] != null
          ? DateTime.parse(json['date_inscription'])
          : DateTime.now(),
      photos: List<String>.from(json['photos'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'contact': contact,
      'telephone': telephone,
      'email': email,
      'adresse': adresse,
      'latitude': latitude,
      'longitude': longitude,
      'type': type,
      'refrigerateur_ids': refrigerateurIds,
      'date_inscription': dateInscription.toIso8601String(),
      'photos': photos,
    };
  }

  // ==================== MÉTHODES UTILITAIRES SIMPLES ====================

  /// Ajouter une photo à la liste
  void ajouterPhoto(String cheminPhoto) {
    photos.add(cheminPhoto);
  }

  /// Ajouter plusieurs photos à la fois
  void ajouterPlusieursPhotos(List<String> cheminsPhotos) {
    photos.addAll(cheminsPhotos);
  }

  /// Supprimer une photo spécifique
  bool supprimerPhoto(String cheminPhoto) {
    return photos.remove(cheminPhoto);
  }

  /// Vérifier si une photo existe
  bool photoExiste(String cheminPhoto) {
    return photos.contains(cheminPhoto);
  }

  /// Vérifier si le client a des photos
  bool get aDesPhotos {
    return photos.isNotEmpty;
  }

  /// Compter le nombre de photos
  int get nombrePhotos {
    return photos.length;
  }

  /// Obtenir la dernière photo ajoutée
  String? get dernierePhoto {
    return photos.isNotEmpty ? photos.last : null;
  }

  /// Vider toutes les photos
  void viderPhotos() {
    photos.clear();
  }
}