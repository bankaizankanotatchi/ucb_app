import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Modèles
import '../models/technicien.dart';
import '../models/refrigerateur.dart';
import '../models/intervention.dart';
import '../models/rapport_intervention.dart';
import '../models/checklist.dart';
import '../models/piece_detachee.dart';
import '../models/client.dart';
import '../models/notification.dart';
import '../models/parametres_app.dart';
import '../models/historique_localisation.dart';
import '../models/template_checklist.dart';

class HiveService {
  // Noms des boxes
  static const String _technicienBox = 'techniciens';
  static const String _refrigerateurBox = 'refrigerateurs';
  static const String _interventionBox = 'interventions';
  static const String _rapportBox = 'rapports_intervention';
  static const String _checklistBox = 'checklists';
  static const String _pieceBox = 'pieces_detachees';
  static const String _clientBox = 'clients';
  static const String _notificationBox = 'notifications';
  static const String _parametresBox = 'parametres_app';
  static const String _localisationBox = 'historique_localisation';
  static const String _templateBox = 'templates_checklist';
  
  static const String _currentUserKey = 'current_user';
  static const String _sessionKey = 'session_data';

  // Variables pour génération de données
  static final Random _random = Random();
  static final List<String> _technicienNoms = ['Dupont', 'Martin', 'Bernard', 'Thomas', 'Petit', 'Robert'];
  static final List<String> _technicienPrenoms = ['Jean', 'Pierre', 'Paul', 'Marie', 'Sophie', 'Luc'];
  static final List<String> _technicienSpecialites = ['Réfrigération', 'Électricité', 'Mécanique', 'Froid industriel'];
  static final List<String> _clientNoms = ['Restaurant Le Gourmet', 'Hôpital Central', 'Super Marché Express', 'Clinique Saint-Louis', 'Boulangerie Tradition', 'Pharmacie du Centre'];
  static final List<String> _marquesRefrigerateurs = ['Liebert', 'Carrier', 'Daikin', 'Mitsubishi', 'Thermo King', 'Cold Tech'];
  static final List<String> _modelesRefrigerateurs = ['RTM-400', 'CTP-200', 'FROID-500', 'GLACE-300', 'NEO-100', 'PRO-600'];
  static final List<String> _typesRefrigerateurs = ['Medical', 'Alimentaire', 'Industriel'];
  static final List<String> _adresses = ['123 Rue de Paris', '45 Avenue des Champs', '67 Boulevard Central', '89 Rue du Commerce', '12 Place de la République'];
  static final List<String> _cities = ['Paris', 'Lyon', 'Marseille', 'Toulouse', 'Bordeaux'];
  static final List<String> _pieceNoms = ['Compresseur R404A', 'Thermostat Digital', 'Moteur Ventilateur', 'Condenseur', 'Évaporateur', 'Détendeur', 'Filtre Déshydrateur', 'Relais de Démarrage'];
  static final List<String> _pieceCategories = ['Compresseur', 'Thermostat', 'Moteur', 'Condenseur', 'Évaporateur'];
  static final List<String> _problemesDiagnostiques = ['Compresseur défectueux', 'Fuite de gaz réfrigérant', 'Problème électrique', 'Thermostat en panne', 'Ventilateur bloqué'];
  static final List<String> _actionsRealisees = ['Remplacement du compresseur', 'Remplissage de gaz', 'Nettoyage des filtres', 'Calibrage du thermostat', 'Lubrification des ventilateurs'];

  // ============================================================
  //                      INITIALISATION
  // ============================================================

  static Future<void> init() async {
    await Hive.initFlutter();

    // Enregistrer tous les adaptateurs
    Hive.registerAdapter(TechnicienAdapter());
    Hive.registerAdapter(RefrigerateurAdapter());
    Hive.registerAdapter(InterventionAdapter());
    Hive.registerAdapter(RapportInterventionAdapter());
    Hive.registerAdapter(ChecklistAdapter());
    Hive.registerAdapter(ChecklistItemAdapter());
    Hive.registerAdapter(PieceDetacheeAdapter());
    Hive.registerAdapter(ClientAdapter());
    Hive.registerAdapter(NotificationTechAdapter());
    Hive.registerAdapter(ParametresAppAdapter());
    Hive.registerAdapter(HistoriqueLocalisationAdapter());
    Hive.registerAdapter(TemplateChecklistAdapter());
    Hive.registerAdapter(TemplateItemAdapter());

    // Ouvrir toutes les boxes
    await Hive.openBox<Technicien>(_technicienBox);
    await Hive.openBox<Refrigerateur>(_refrigerateurBox);
    await Hive.openBox<Intervention>(_interventionBox);
    await Hive.openBox<RapportIntervention>(_rapportBox);
    await Hive.openBox<Checklist>(_checklistBox);
    await Hive.openBox<PieceDetachee>(_pieceBox);
    await Hive.openBox<Client>(_clientBox);
    await Hive.openBox<NotificationTech>(_notificationBox);
    await Hive.openBox<ParametresApp>(_parametresBox);
    await Hive.openBox<HistoriqueLocalisation>(_localisationBox);
    await Hive.openBox<TemplateChecklist>(_templateBox);
    await Hive.openBox(_currentUserKey);
    await Hive.openBox(_sessionKey);
    
    // Charger les données de démo si nécessaire
    await _loadDemoData();
    
    print('✅ Hive initialisé avec ${await _getAllDataCount()} données');
  }

  static Future<int> _getAllDataCount() async {
    int total = 0;
    total += (await Hive.openBox<Technicien>(_technicienBox)).length;
    total += (await Hive.openBox<Refrigerateur>(_refrigerateurBox)).length;
    total += (await Hive.openBox<Intervention>(_interventionBox)).length;
    total += (await Hive.openBox<RapportIntervention>(_rapportBox)).length;
    return total;
  }

  // ============================================================
  //                      CHARGEMENT DONNÉES DÉMO
  // ============================================================

  static Future<void> _loadDemoData() async {
    // Vérifier si des données existent déjà
    if (Hive.box<Technicien>(_technicienBox).isEmpty) {
      await _createDemoTechniciens();
      await _createDemoClients();
      await _createDemoRefrigerateurs();
      await _createDemoPiecesDetachees();
      await _createDemoTemplates();
      await _createDemoInterventions();
      await _createDemoNotifications();
      await _createDemoLocalisations();
      
      // Créer des paramètres par défaut
      final params = ParametresApp(
        langue: 'fr',
        notifications: true,
        gpsAuto: true,
        modeHorsLigne: false,
        derniereSession: '',
        derniereSynchro: DateTime.now(),
        tokenNotification: 'demo_token_12345',
      );
      await saveParametres(params);
      
      print('✅ Données de démo chargées avec succès');
    }
  }

  static Future<void> _createDemoTechniciens() async {
    final box = Hive.box<Technicien>(_technicienBox);
    
    final techniciens = [
      Technicien(
        id: 'tech_001',
        matricule: 'TECH-2024-001',
        nom: 'Onomo',
        prenom: 'JB',
        telephone: '+237 6 56 34 56 78',
        email: 'jb.onomo@kes-africa.com',
        motDePasse: 'password123',
        specialite: 'Réfrigération',
        createdAt: DateTime.now().subtract(Duration(days: 365)),
        zoneAffectation: 'Cameroun',
        actif: true,
      ),
      Technicien(
        id: 'tech_002',
        matricule: 'TECH-2024-002',
        nom: 'Martin',
        prenom: 'Sophie',
        telephone: '+33 6 23 45 67 89',
        email: 'sophie.martin@coldservice.com',
        motDePasse: 'password123',
        specialite: 'Électricité',
        createdAt: DateTime.now().subtract(Duration(days: 300)),
        zoneAffectation: 'Lyon',
        actif: true,
      ),
      Technicien(
        id: 'tech_003',
        matricule: 'TECH-2024-003',
        nom: 'Bernard',
        prenom: 'Pierre',
        telephone: '+33 6 34 56 78 90',
        email: 'pierre.bernard@coldservice.com',
        motDePasse: 'password123',
        specialite: 'Mécanique',
        createdAt: DateTime.now().subtract(Duration(days: 250)),
        zoneAffectation: 'Marseille',
        actif: true,
      ),
    ];
    
    for (var technicien in techniciens) {
      await box.put(technicien.id, technicien);
    }
  }

  static Future<void> _createDemoClients() async {
    final box = Hive.box<Client>(_clientBox);
    
    final clients = [
      Client(
        id: 'client_001',
        nom: 'Restaurant Le Gourmet',
        contact: 'M. Leblanc',
        telephone: '+237 6 55 45 67 89',
        email: 'contact@legourmet.com',
        adresse: 'Cité des Palmiers, Douala',
        latitude: 4.05,
        longitude: 9.76,
        type: 'Restaurant',
        refrigerateurIds: ['ref_001', 'ref_002'],
        dateInscription: DateTime.now().subtract(Duration(days: 180)),
      ),
      Client(
        id: 'client_002',
        nom: 'Hôpital Central',
        contact: 'Dr. Martin',
        telephone: '+33 1 34 56 78 90',
        email: 'maintenance@hopitalcentral.fr',
        adresse: '45 Avenue des Champs, 69000 Lyon',
        latitude: 45.7640,
        longitude: 4.8357,
        type: 'Hopital',
        refrigerateurIds: ['ref_003', 'ref_004', 'ref_005'],
        dateInscription: DateTime.now().subtract(Duration(days: 150)),
      ),
      Client(
        id: 'client_003',
        nom: 'Super Marché Express',
        contact: 'Mme. Dubois',
        telephone: '+33 1 45 67 89 01',
        email: 'achats@supermarché.fr',
        adresse: '67 Boulevard Central, 13000 Marseille',
        latitude: 43.2965,
        longitude: 5.3698,
        type: 'Supermarche',
        refrigerateurIds: ['ref_006', 'ref_007'],
        dateInscription: DateTime.now().subtract(Duration(days: 120)),
      ),
      Client(
        id: 'client_004',
        nom: 'Clinique Saint-Louis',
        contact: 'M. Durand',
        telephone: '+33 1 56 78 90 12',
        email: 'technique@cliniquesaintlouis.fr',
        adresse: '89 Rue du Commerce, 31000 Toulouse',
        latitude: 43.6047,
        longitude: 1.4442,
        type: 'Hopital',
        refrigerateurIds: ['ref_008'],
        dateInscription: DateTime.now().subtract(Duration(days: 90)),
      ),
    ];
    
    for (var client in clients) {
      await box.put(client.id, client);
    }
  }

static Future<void> _createDemoRefrigerateurs() async {
  final box = Hive.box<Refrigerateur>(_refrigerateurBox);
  
  // Chemins d'images d'assets pour les démos
  final List<String> imagesAvant = [
    'assets/images/frigo_avant_1.jpg',
    'assets/images/frigo_avant_1.jpg',
    'assets/images/frigo_avant_1.jpg',
  ];
  
  final List<String> imagesPendant = [
    'assets/images/frigo_avant_1.jpg',
    'assets/images/frigo_avant_1.jpg',
  ];
  
  final List<String> imagesApres = [
    'assets/images/frigo_avant_1.jpg',
    'assets/images/frigo_avant_1.jpg',
    'assets/images/frigo_avant_1.jpg',
  ];
  
  final refrigerateurs = [
    Refrigerateur(
      id: 'ref_001',
      codeQR: 'QR001-2024-001',
      numeroSerie: 'SN2024001',
      marque: 'Liebert',
      modele: 'RTM-400',
      type: 'Medical',
      clientId: 'client_001',
      adresse: '123 Rue de Paris, 75001 Paris',
      latitude: 4.05,
      longitude: 9.76,
      statut: 'Fonctionnel',
      dateInstallation: DateTime.now().subtract(Duration(days: 200)),
      dateDerniereMaintenance: DateTime.now().subtract(Duration(days: 30)),
      caracteristiques: {
        'temperature': '4°C',
        'capacite': '400L',
        'consommation': '2.5kWh/jour',
        'gaz_refrigerant': 'R404A',
      },
      photosAvantReparation: [imagesAvant[0]],
      photosPendantReparation: [],
      photosApresReparation: [imagesApres[0]],
      dateDernieresPhotos: DateTime.now().subtract(Duration(days: 10)),
      dernierTechnicienPhotos: 'tech_001',
    ),
    Refrigerateur(
      id: 'ref_002',
      codeQR: 'QR001-2024-002',
      numeroSerie: 'SN2024002',
      marque: 'Carrier',
      modele: 'CTP-200',
      type: 'Alimentaire',
      clientId: 'client_001',
      adresse: '123 Rue de Paris, 75001 Paris',
      latitude: 4.052,
      longitude: 9.761,
      statut: 'En_panne',
      dateInstallation: DateTime.now().subtract(Duration(days: 180)),
      dateDerniereMaintenance: DateTime.now().subtract(Duration(days: 45)),
      caracteristiques: {
        'temperature': '-18°C',
        'capacite': '200L',
        'consommation': '1.8kWh/jour',
        'gaz_refrigerant': 'R134a',
      },
      photosAvantReparation: [imagesAvant[0], imagesAvant[1]],
      photosPendantReparation: [imagesPendant[0]],
      photosApresReparation: [],
      dateDernieresPhotos: DateTime.now().subtract(Duration(days: 2)),
      dernierTechnicienPhotos: 'tech_002',
    ),
    Refrigerateur(
      id: 'ref_003',
      codeQR: 'QR001-2024-003',
      numeroSerie: 'SN2024003',
      marque: 'Daikin',
      modele: 'FROID-500',
      type: 'Medical',
      clientId: 'client_002',
      adresse: '45 Avenue des Champs, 69000 Lyon',
      latitude: 45.7640,
      longitude: 4.8357,
      statut: 'Maintenance',
      dateInstallation: DateTime.now().subtract(Duration(days: 160)),
      dateDerniereMaintenance: DateTime.now().subtract(Duration(days: 15)),
      caracteristiques: {
        'temperature': '2°C',
        'capacite': '500L',
        'consommation': '3.2kWh/jour',
        'gaz_refrigerant': 'R410A',
      },
      photosAvantReparation: [imagesAvant[2]],
      photosPendantReparation: [imagesPendant[0], imagesPendant[1]],
      photosApresReparation: [imagesApres[1]],
      dateDernieresPhotos: DateTime.now().subtract(Duration(days: 1)),
      dernierTechnicienPhotos: 'tech_001',
    ),
    Refrigerateur(
      id: 'ref_004',
      codeQR: 'QR001-2024-004',
      numeroSerie: 'SN2024004',
      marque: 'Mitsubishi',
      modele: 'GLACE-300',
      type: 'Medical',
      clientId: 'client_002',
      adresse: '45 Avenue des Champs, 69000 Lyon',
      latitude: 45.7640,
      longitude: 4.8358,
      statut: 'Fonctionnel',
      dateInstallation: DateTime.now().subtract(Duration(days: 140)),
      dateDerniereMaintenance: DateTime.now().subtract(Duration(days: 60)),
      caracteristiques: {
        'temperature': '-25°C',
        'capacite': '300L',
        'consommation': '2.1kWh/jour',
        'gaz_refrigerant': 'R407C',
      },
      photosAvantReparation: [],
      photosPendantReparation: [],
      photosApresReparation: [imagesApres[0], imagesApres[2]],
      dateDernieresPhotos: DateTime.now().subtract(Duration(days: 5)),
      dernierTechnicienPhotos: 'tech_003',
    ),
    Refrigerateur(
      id: 'ref_005',
      codeQR: 'QR001-2024-005',
      numeroSerie: 'SN2024005',
      marque: 'Thermo King',
      modele: 'NEO-100',
      type: 'Industriel',
      clientId: 'client_002',
      adresse: '45 Avenue des Champs, 69000 Lyon',
      latitude: 45.7641,
      longitude: 4.8359,
      statut: 'Fonctionnel',
      dateInstallation: DateTime.now().subtract(Duration(days: 120)),
      dateDerniereMaintenance: DateTime.now().subtract(Duration(days: 90)),
      caracteristiques: {
        'temperature': '-40°C',
        'capacite': '1000L',
        'consommation': '5.5kWh/jour',
        'gaz_refrigerant': 'R507',
      },
      photosAvantReparation: [imagesAvant[0]],
      photosPendantReparation: [imagesPendant[1]],
      photosApresReparation: [imagesApres[1], imagesApres[2]],
      dateDernieresPhotos: DateTime.now().subtract(Duration(days: 7)),
      dernierTechnicienPhotos: 'tech_002',
    ),
    // Ajout de 3 autres réfrigérateurs pour plus de variété
    Refrigerateur(
      id: 'ref_006',
      codeQR: 'QR001-2024-006',
      numeroSerie: 'SN2024006',
      marque: 'Cold Tech',
      modele: 'PRO-600',
      type: 'Alimentaire',
      clientId: 'client_003',
      adresse: '67 Boulevard Central, 13000 Marseille',
      latitude: 43.2965,
      longitude: 5.3698,
      statut: 'Fonctionnel',
      dateInstallation: DateTime.now().subtract(Duration(days: 100)),
      dateDerniereMaintenance: DateTime.now().subtract(Duration(days: 20)),
      caracteristiques: {
        'temperature': '3°C',
        'capacite': '600L',
        'consommation': '4.0kWh/jour',
        'gaz_refrigerant': 'R134a',
      },
      photosAvantReparation: [imagesAvant[1]],
      photosPendantReparation: [],
      photosApresReparation: [imagesApres[0]],
      dateDernieresPhotos: DateTime.now().subtract(Duration(days: 15)),
      dernierTechnicienPhotos: 'tech_001',
    ),
    Refrigerateur(
      id: 'ref_007',
      codeQR: 'QR001-2024-007',
      numeroSerie: 'SN2024007',
      marque: 'Liebert',
      modele: 'RTM-400',
      type: 'Medical',
      clientId: 'client_003',
      adresse: '67 Boulevard Central, 13000 Marseille',
      latitude: 43.2966,
      longitude: 5.3699,
      statut: 'En_panne',
      dateInstallation: DateTime.now().subtract(Duration(days: 80)),
      dateDerniereMaintenance: DateTime.now().subtract(Duration(days: 35)),
      caracteristiques: {
        'temperature': '5°C',
        'capacite': '400L',
        'consommation': '2.8kWh/jour',
        'gaz_refrigerant': 'R404A',
      },
      photosAvantReparation: [imagesAvant[2]],
      photosPendantReparation: [imagesPendant[0]],
      photosApresReparation: [],
      dateDernieresPhotos: DateTime.now().subtract(Duration(days: 3)),
      dernierTechnicienPhotos: 'tech_002',
    ),
    Refrigerateur(
      id: 'ref_008',
      codeQR: 'QR001-2024-008',
      numeroSerie: 'SN2024008',
      marque: 'Daikin',
      modele: 'FROID-500',
      type: 'Medical',
      clientId: 'client_004',
      adresse: '89 Rue du Commerce, 31000 Toulouse',
      latitude: 43.6047,
      longitude: 1.4442,
      statut: 'Maintenance',
      dateInstallation: DateTime.now().subtract(Duration(days: 60)),
      dateDerniereMaintenance: DateTime.now().subtract(Duration(days: 10)),
      caracteristiques: {
        'temperature': '2°C',
        'capacite': '500L',
        'consommation': '3.5kWh/jour',
        'gaz_refrigerant': 'R410A',
      },
      photosAvantReparation: [imagesAvant[0], imagesAvant[1]],
      photosPendantReparation: [imagesPendant[1]],
      photosApresReparation: [imagesApres[2]],
      dateDernieresPhotos: DateTime.now().subtract(Duration(days: 2)),
      dernierTechnicienPhotos: 'tech_003',
    ),
  ];
  
  for (var refrigerateur in refrigerateurs) {
    await box.put(refrigerateur.id, refrigerateur);
  }
}
  static Future<void> _createDemoPiecesDetachees() async {
    final box = Hive.box<PieceDetachee>(_pieceBox);
    
    final pieces = [
      PieceDetachee(
        id: 'piece_001',
        reference: 'COMP-R404A-001',
        nom: 'Compresseur R404A',
        categorie: 'Compresseur',
        quantiteStock: 15,
        seuilMin: 5,
        prixUnitaire: 450.0,
        modelesCompatibles: ['RTM-400', 'CTP-200'],
      ),
      PieceDetachee(
        id: 'piece_002',
        reference: 'THERMO-DIG-001',
        nom: 'Thermostat Digital',
        categorie: 'Thermostat',
        quantiteStock: 8,
        seuilMin: 3,
        prixUnitaire: 120.0,
        modelesCompatibles: ['FROID-500', 'GLACE-300', 'NEO-100'],
      ),
      PieceDetachee(
        id: 'piece_003',
        reference: 'MOTEUR-VENT-001',
        nom: 'Moteur Ventilateur',
        categorie: 'Moteur',
        quantiteStock: 3,
        seuilMin: 2,
        prixUnitaire: 85.0,
        modelesCompatibles: ['RTM-400', 'PRO-600'],
      ),
      PieceDetachee(
        id: 'piece_004',
        reference: 'COND-AL-001',
        nom: 'Condenseur Aluminium',
        categorie: 'Condenseur',
        quantiteStock: 6,
        seuilMin: 2,
        prixUnitaire: 320.0,
        modelesCompatibles: ['CTP-200', 'GLACE-300'],
      ),
      PieceDetachee(
        id: 'piece_005',
        reference: 'EVAP-CU-001',
        nom: 'Évaporateur Cuivre',
        categorie: 'Évaporateur',
        quantiteStock: 1,
        seuilMin: 2,
        prixUnitaire: 280.0,
        modelesCompatibles: ['FROID-500', 'NEO-100'],
      ),
      PieceDetachee(
        id: 'piece_006',
        reference: 'FILTRE-DRY-001',
        nom: 'Filtre Déshydrateur',
        categorie: 'Accessoire',
        quantiteStock: 20,
        seuilMin: 10,
        prixUnitaire: 45.0,
        modelesCompatibles: ['RTM-400', 'CTP-200', 'FROID-500', 'GLACE-300', 'NEO-100', 'PRO-600'],
      ),
    ];
    
    for (var piece in pieces) {
      await box.put(piece.id, piece);
    }
  }

  static Future<void> _createDemoTemplates() async {
    final box = Hive.box<TemplateChecklist>(_templateBox);
    
    final templates = [
      TemplateChecklist(
        id: 'template_001',
        nom: 'Checklist Maintenance Préventive',
        typePanne: 'Maintenance',
        items: [
          TemplateItem(
            id: 'item_001',
            description: 'Nettoyage des filtres et condenseur',
            obligatoire: true,
            ordre: 1,
          ),
          TemplateItem(
            id: 'item_002',
            description: 'Vérification des températures',
            obligatoire: true,
            ordre: 2,
          ),
          TemplateItem(
            id: 'item_003',
            description: 'Contrôle des fuites',
            obligatoire: true,
            ordre: 3,
          ),
          TemplateItem(
            id: 'item_004',
            description: 'Lubrification des parties mobiles',
            obligatoire: false,
            ordre: 4,
          ),
        ],
      ),
      TemplateChecklist(
        id: 'template_002',
        nom: 'Checklist Panne Électrique',
        typePanne: 'Electrique',
        items: [
          TemplateItem(
            id: 'item_005',
            description: 'Vérifier l\'alimentation électrique',
            obligatoire: true,
            ordre: 1,
          ),
          TemplateItem(
            id: 'item_006',
            description: 'Tester les fusibles et disjoncteurs',
            obligatoire: true,
            ordre: 2,
          ),
          TemplateItem(
            id: 'item_007',
            description: 'Contrôler le thermostat',
            obligatoire: true,
            ordre: 3,
          ),
          TemplateItem(
            id: 'item_008',
            description: 'Vérifier les connexions électriques',
            obligatoire: true,
            ordre: 4,
          ),
        ],
      ),
      TemplateChecklist(
        id: 'template_003',
        nom: 'Checklist Problème de Froid',
        typePanne: 'Froid',
        items: [
          TemplateItem(
            id: 'item_009',
            description: 'Vérifier la pression du gaz',
            obligatoire: true,
            ordre: 1,
          ),
          TemplateItem(
            id: 'item_010',
            description: 'Contrôler le compresseur',
            obligatoire: true,
            ordre: 2,
          ),
          TemplateItem(
            id: 'item_011',
            description: 'Inspecter les ventilateurs',
            obligatoire: true,
            ordre: 3,
          ),
          TemplateItem(
            id: 'item_012',
            description: 'Vérifier le détendeur',
            obligatoire: false,
            ordre: 4,
          ),
        ],
      ),
    ];
    
    for (var template in templates) {
      await box.put(template.id, template);
    }
  }

  static Future<void> _createDemoInterventions() async {
    final box = Hive.box<Intervention>(_interventionBox);
    
    final interventions = [
      Intervention(
        id: 'int_001',
        code: 'INT-2024-001',
        type: 'Reparation',
        priorite: 2,
        statut: 'Terminee',
        dateCreation: DateTime.now().subtract(Duration(days: 5)),
        datePlanifiee: DateTime.now().subtract(Duration(days: 4)),
        dateDebut: DateTime.now().subtract(Duration(days: 4, hours: 2)),
        dateFin: DateTime.now().subtract(Duration(days: 4, hours: 5)),
        technicienIds: ['tech_001'],
        refrigerateurIds: ['ref_002'],
        description: 'Réparation du réfrigérateur en panne - compresseur défectueux',
        rapportId: 'rapport_001',
        checklistId: 'checklist_001',
        clientId: 'client_001',
        synchronise: true,
        updatedAt: DateTime.now().subtract(Duration(days: 4, hours: 5)),
      ),
      Intervention(
        id: 'int_002',
        code: 'INT-2024-002',
        type: 'Maintenance',
        priorite: 3,
        statut: 'En_cours',
        dateCreation: DateTime.now().subtract(Duration(days: 2)),
        datePlanifiee: DateTime.now().subtract(Duration(days: 1)),
        dateDebut: DateTime.now().subtract(Duration(hours: 3)),
        technicienIds: ['tech_002'],
        refrigerateurIds: ['ref_003'],
        description: 'Maintenance préventive annuelle',
        rapportId: 'rapport_002',
        checklistId: 'checklist_002',
        clientId: 'client_002',
        synchronise: false,
        updatedAt: DateTime.now().subtract(Duration(hours: 3)),
      ),
      Intervention(
        id: 'int_003',
        code: 'INT-2024-003',
        type: 'Urgence',
        priorite: 1,
        statut: 'Planifiee',
        dateCreation: DateTime.now().subtract(Duration(days: 1)),
        datePlanifiee: DateTime.now().add(Duration(days: 1)),
        technicienIds: ['tech_003'],
        refrigerateurIds: ['ref_005'],
        description: 'Panne urgente - pas de froid',
        clientId: 'client_002',
        synchronise: false,
        updatedAt: DateTime.now().subtract(Duration(days: 1)),
      ),
      Intervention(
        id: 'int_004',
        code: 'INT-2024-004',
        type: 'Maintenance',
        priorite: 3,
        statut: 'Planifiee',
        dateCreation: DateTime.now().subtract(Duration(days: 3)),
        datePlanifiee: DateTime.now().add(Duration(days: 3)),
        technicienIds: ['tech_001', 'tech_002'],
        refrigerateurIds: ['ref_001', 'ref_004'],
        description: 'Maintenance préventive multi-équipements',
        clientId: 'client_001',
        synchronise: false,
        updatedAt: DateTime.now().subtract(Duration(days: 3)),
      ),
    ];
    
    for (var intervention in interventions) {
      await box.put(intervention.id, intervention);
    }
    
    // Créer les rapports associés
    await _createDemoRapports();
    await _createDemoChecklists();
  }

static Future<void> _createDemoRapports() async {
  final box = Hive.box<RapportIntervention>(_rapportBox);
  
  final rapports = [
    RapportIntervention(
      id: 'rapport_001',
      interventionId: 'int_001',
      technicienId: 'tech_001',
      dateRapport: DateTime.now().subtract(Duration(days: 4, hours: 5)),
      problemeDiagnostique: 'Compresseur défectueux et fuite de gaz R134a',
      actionsRealisees: 'Remplacement du compresseur et recharge en gaz',
      piecesUtilisees: ['piece_001', 'piece_006'],
      tempsPasse: 3.5,
      photosAvant: ['assets/images/rapport_avant_1.jpg', 'assets/images/rapport_avant_2.jpg'],
      photosApres: ['assets/images/rapport_apres_1.jpg', 'assets/images/rapport_apres_2.jpg'],
      signaturePath: 'assets/signatures/signature1.png',
      observations: 'Client satisfait du travail réalisé. Recommandation : vérifier l\'installation électrique dans 6 mois.',
      clientSatisfait: true,
    ),
    RapportIntervention(
      id: 'rapport_002',
      interventionId: 'int_002',
      technicienId: 'tech_002',
      dateRapport: DateTime.now().subtract(Duration(hours: 2)),
      problemeDiagnostique: 'Maintenance préventive - pas de panne détectée',
      actionsRealisees: 'Nettoyage complet, vérification des températures, contrôle des fuites',
      piecesUtilisees: ['piece_006'],
      tempsPasse: 2.0,
      photosAvant: ['assets/images/rapport_avant_3.jpg'],
      photosApres: ['assets/images/rapport_apres_3.jpg'],
      observations: 'Équipement en bon état. Filtre remplacé.',
      clientSatisfait: true,
    ),
  ];
  
  for (var rapport in rapports) {
    await box.put(rapport.id, rapport);
  }
}
static Future<void> _createDemoChecklists() async {
  final box = Hive.box<Checklist>(_checklistBox);
  
  final checklists = [
    Checklist(
      id: 'checklist_001',
      interventionId: 'int_001',
      type: 'Reparation',
      items: [
        ChecklistItem(
          id: 'item_001',
          description: 'Vérifier l\'alimentation électrique',
          verifie: true,
          observation: 'Alimentation OK - 230V',
          photos: ['assets/images/checklist_photo1.jpg'],
          obligatoire: true,
        ),
        ChecklistItem(
          id: 'item_002',
          description: 'Contrôler les fusibles',
          verifie: true,
          observation: 'Fusible principal grillé - remplacé',
          obligatoire: true,
        ),
        ChecklistItem(
          id: 'item_003',
          description: 'Tester le compresseur',
          verifie: true,
          observation: 'Compresseur HS - remplacé',
          photos: ['assets/images/checklist_photo2.jpg'],
          obligatoire: true,
        ),
      ],
      dateCompletion: DateTime.now().subtract(Duration(days: 4, hours: 5)),
      complete: true,
    ),
    Checklist(
      id: 'checklist_002',
      interventionId: 'int_002',
      type: 'Maintenance',
      items: [
        ChecklistItem(
          id: 'item_004',
          description: 'Nettoyage des filtres et condenseur',
          verifie: true,
          observation: 'Filtre très sale - remplacé',
          photos: ['assets/images/checklist_photo3.jpg'],
          obligatoire: true,
        ),
        ChecklistItem(
          id: 'item_005',
          description: 'Vérification des températures',
          verifie: true,
          observation: 'Température stable à 4°C',
          obligatoire: true,
        ),
        ChecklistItem(
          id: 'item_006',
          description: 'Contrôle des fuites',
          verifie: false,
          obligatoire: true,
        ),
      ],
      dateCompletion: DateTime.now(),
      complete: false,
    ),
  ];
  
  for (var checklist in checklists) {
    await box.put(checklist.id, checklist);
  }
}
  static Future<void> _createDemoNotifications() async {
    final box = Hive.box<NotificationTech>(_notificationBox);
    
    final notifications = [
      NotificationTech(
        id: 'notif_001',
        titre: 'Nouvelle Intervention',
        message: 'Une nouvelle intervention urgente a été assignée : INT-2024-003',
        type: 'Intervention',
        date: DateTime.now().subtract(Duration(hours: 2)),
        lue: false,
        interventionId: 'int_003',
      ),
      NotificationTech(
        id: 'notif_002',
        titre: 'Stock Bas',
        message: 'Le stock de compresseurs R404A est critique (3 unités restantes)',
        type: 'Stock',
        date: DateTime.now().subtract(Duration(days: 1)),
        lue: true,
      ),
      NotificationTech(
        id: 'notif_003',
        titre: 'Maintenance Préventive',
        message: 'Maintenance prévue demain pour le réfrigérateur SN2024003',
        type: 'Intervention',
        date: DateTime.now().subtract(Duration(days: 2)),
        lue: true,
        interventionId: 'int_002',
        refrigerateurId: 'ref_003',
      ),
      NotificationTech(
        id: 'notif_004',
        titre: 'Synchronisation Réussie',
        message: '5 interventions synchronisées avec le serveur',
        type: 'Systeme',
        date: DateTime.now().subtract(Duration(days: 4)),
        lue: true,
      ),
    ];
    
    for (var notification in notifications) {
      await box.put(notification.id, notification);
    }
  }

  static Future<void> _createDemoLocalisations() async {
    final box = Hive.box<HistoriqueLocalisation>(_localisationBox);
    
    final now = DateTime.now();
    final localisations = [
      HistoriqueLocalisation(
        id: 'loc_001',
        technicienId: 'tech_001',
        latitude: 48.8566,
        longitude: 2.3522,
        timestamp: now.subtract(Duration(hours: 3)),
        interventionId: 'int_001',
      ),
      HistoriqueLocalisation(
        id: 'loc_002',
        technicienId: 'tech_001',
        latitude: 48.8570,
        longitude: 2.3530,
        timestamp: now.subtract(Duration(hours: 2)),
      ),
      HistoriqueLocalisation(
        id: 'loc_003',
        technicienId: 'tech_002',
        latitude: 45.7640,
        longitude: 4.8357,
        timestamp: now.subtract(Duration(hours: 1)),
        interventionId: 'int_002',
      ),
      HistoriqueLocalisation(
        id: 'loc_004',
        technicienId: 'tech_003',
        latitude: 43.2965,
        longitude: 5.3698,
        timestamp: now.subtract(Duration(minutes: 30)),
      ),
    ];
    
    for (var localisation in localisations) {
      await box.add(localisation);
    }
  }

  // ============================================================
  //                      GESTION TECHNICIEN
  // ============================================================

/// Sauvegarder le technicien connecté
static Future<void> saveCurrentTechnicien(Technicien technicien) async {
  // Sauvegarder le technicien dans la box avec son ID comme clé
  final box = Hive.box<Technicien>(_technicienBox);
  await box.put(technicien.id, technicien);

  // Sauvegarder les informations de session dans une box séparée
  final currentBox = Hive.box(_currentUserKey);
  await currentBox.put('matricule', technicien.matricule);
  await currentBox.put('isLoggedIn', true);
  await currentBox.put('technicienId', technicien.id); // Sauvegarder aussi l'ID

  print("🔵 Technicien sauvegardé et connecté : ${technicien.matricule}");
}

/// Récupérer le technicien actuellement connecté
static Technicien? getCurrentTechnicien() {
  try {
    final currentBox = Hive.box(_currentUserKey);
    final technicienId = currentBox.get('technicienId'); // Récupérer par ID
    final isLoggedIn = currentBox.get('isLoggedIn', defaultValue: false);

    if (technicienId == null || !isLoggedIn) return null;

    final box = Hive.box<Technicien>(_technicienBox);
    final technicien = box.get(technicienId);

    if (technicien == null) {
      // Nettoyer la session si le technicien n'existe plus
      currentBox.delete('matricule');
      currentBox.delete('technicienId');
      currentBox.delete('isLoggedIn');
    }

    return technicien;
  } catch (e) {
    print('❌ Erreur getCurrentTechnicien: $e');
    return null;
  }
}

/// Récupérer un technicien par son matricule
static Technicien? getTechnicienByMatricule(String matricule) {
  final box = Hive.box<Technicien>(_technicienBox);
  try {
    return box.values.firstWhere((tech) => tech.matricule == matricule);
  } catch (e) {
    return null;
  }
}

  /// Vérifier si un technicien existe localement
  static bool technicienExists(String matricule) {
    final box = Hive.box<Technicien>(_technicienBox);
    return box.containsKey(matricule);
  }

  /// Vérifier si un technicien est connecté
  static bool isTechnicienLoggedIn() {
    final currentBox = Hive.box(_currentUserKey);
    return currentBox.get('isLoggedIn', defaultValue: false);
  }

  /// Déconnecter le technicien
  static Future<void> logout() async {
    try {
      final currentBox = Hive.box(_currentUserKey);
      await currentBox.put('isLoggedIn', false);
      print('🟡 Technicien déconnecté proprement.');
    } catch (e) {
      print('❌ Erreur lors de logout: $e');
      throw Exception('Erreur lors de la déconnexion');
    }
  }

  /// Déconnexion complète
  static Future<void> logoutCompletely() async {
    try {
      final currentBox = Hive.box(_currentUserKey);
      await currentBox.clear();
      print('🔴 Déconnexion complète : session effacée.');
    } catch (e) {
      print('❌ Erreur logoutCompletely: $e');
      throw Exception('Erreur lors de la déconnexion complète');
    }
  }

  /// Obtenir tous les techniciens
  static List<Technicien> getAllTechniciens() {
    try {
      final box = Hive.box<Technicien>(_technicienBox);
      return box.values.toList();
    } catch (e) {
      print('❌ Erreur getAllTechniciens: $e');
      return [];
    }
  }

  /// Mettre à jour un technicien
  static Future<bool> updateTechnicien(Technicien technicien) async {
    try {
      await technicien.save();
      print('✅ Technicien mis à jour: ${technicien.matricule}');
      return true;
    } catch (e) {
      print('❌ Erreur updateTechnicien: $e');
      return false;
    }
  }

  // ============================================================
  //                      GESTION RÉFRIGÉRATEURS
  // ============================================================

  /// Sauvegarder un réfrigérateur
  static Future<void> saveRefrigerateur(Refrigerateur refrigerateur) async {
    final box = Hive.box<Refrigerateur>(_refrigerateurBox);
    await box.put(refrigerateur.id, refrigerateur);
    print('✅ Réfrigérateur sauvegardé: ${refrigerateur.codeQR}');
  }

  /// Récupérer un réfrigérateur par ID
  static Refrigerateur? getRefrigerateurById(String id) {
    final box = Hive.box<Refrigerateur>(_refrigerateurBox);
    return box.get(id);
  }

  /// Récupérer un réfrigérateur par QR code
  static Refrigerateur? getRefrigerateurByQR(String qrCode) {
    final box = Hive.box<Refrigerateur>(_refrigerateurBox);
    try {
      return box.values.firstWhere((r) => r.codeQR == qrCode);
    } catch (e) {
      return null;
    }
  }

  /// Obtenir tous les réfrigérateurs
  static List<Refrigerateur> getAllRefrigerateurs() {
    final box = Hive.box<Refrigerateur>(_refrigerateurBox);
    return box.values.toList();
  }

  /// Obtenir les réfrigérateurs en panne
  static List<Refrigerateur> getRefrigerateursEnPanne() {
    final box = Hive.box<Refrigerateur>(_refrigerateurBox);
    return box.values.where((r) => r.statut == 'En_panne').toList();
  }

  /// Obtenir les réfrigérateurs par client
  static List<Refrigerateur> getRefrigerateursByClient(String clientId) {
    final box = Hive.box<Refrigerateur>(_refrigerateurBox);
    return box.values.where((r) => r.clientId == clientId).toList();
  }

  /// Mettre à jour le statut d'un réfrigérateur
  static Future<bool> updateRefrigerateurStatut({
    required String refrigerateurId,
    required String nouveauStatut,
  }) async {
    try {
      final refrigerateur = getRefrigerateurById(refrigerateurId);
      if (refrigerateur == null) return false;
      
      refrigerateur.statut = nouveauStatut;
      await refrigerateur.save();
      print('✅ Statut réfrigérateur mis à jour: $refrigerateurId -> $nouveauStatut');
      return true;
    } catch (e) {
      print('❌ Erreur updateRefrigerateurStatut: $e');
      return false;
    }
  }

  /// Vérifier si un QR code existe déjà
  static bool qrCodeExists(String qrCode) {
    return getRefrigerateurByQR(qrCode) != null;
  }

  // ============================================================
  //                      GESTION INTERVENTIONS
  // ============================================================

  /// Sauvegarder une intervention
  static Future<void> saveIntervention(Intervention intervention) async {
    final box = Hive.box<Intervention>(_interventionBox);
    await box.put(intervention.id, intervention);
    print('✅ Intervention sauvegardée: ${intervention.code}');
  }

  /// Récupérer une intervention par ID
  static Intervention? getInterventionById(String id) {
    final box = Hive.box<Intervention>(_interventionBox);
    return box.get(id);
  }

  /// Obtenir toutes les interventions
  static List<Intervention> getAllInterventions() {
    final box = Hive.box<Intervention>(_interventionBox);
    return box.values.toList();
  }

  /// Obtenir les interventions d'un technicien
  static List<Intervention> getInterventionsByTechnicien(String technicienId) {
    final box = Hive.box<Intervention>(_interventionBox);
    return box.values.where((i) => i.technicienIds.contains(technicienId)).toList();
  }

  /// Obtenir les interventions du jour
  static List<Intervention> getInterventionsDuJour() {
    final aujourdHui = DateTime.now();
    final box = Hive.box<Intervention>(_interventionBox);
    
    return box.values.where((intervention) {
      return intervention.datePlanifiee.year == aujourdHui.year &&
             intervention.datePlanifiee.month == aujourdHui.month &&
             intervention.datePlanifiee.day == aujourdHui.day;
    }).toList();
  }

  /// Obtenir les interventions par statut
  static List<Intervention> getInterventionsByStatut(String statut) {
    final box = Hive.box<Intervention>(_interventionBox);
    return box.values.where((i) => i.statut == statut).toList();
  }

  /// Obtenir les interventions par priorité
  static List<Intervention> getInterventionsByPriorite(int priorite) {
    final box = Hive.box<Intervention>(_interventionBox);
    return box.values.where((i) => i.priorite == priorite).toList();
  }

  /// Mettre à jour le statut d'une intervention
  static Future<bool> updateInterventionStatut({
    required String interventionId,
    required String nouveauStatut,
  }) async {
    try {
      final intervention = getInterventionById(interventionId);
      if (intervention == null) return false;
      
      intervention.statut = nouveauStatut;
      intervention.updatedAt = DateTime.now();
      
      if (nouveauStatut == 'En_cours' && intervention.dateDebut == null) {
        intervention.dateDebut = DateTime.now();
      }
      
      if (nouveauStatut == 'Terminee' && intervention.dateFin == null) {
        intervention.dateFin = DateTime.now();
      }
      
      await intervention.save();
      print('✅ Statut intervention mis à jour: $interventionId -> $nouveauStatut');
      return true;
    } catch (e) {
      print('❌ Erreur updateInterventionStatut: $e');
      return false;
    }
  }

  /// Ajouter un technicien à une intervention
  static Future<bool> addTechnicienToIntervention({
    required String interventionId,
    required String technicienId,
  }) async {
    try {
      final intervention = getInterventionById(interventionId);
      if (intervention == null) return false;
      
      if (!intervention.technicienIds.contains(technicienId)) {
        intervention.technicienIds.add(technicienId);
        await intervention.save();
        print('✅ Technicien ajouté à l\'intervention: $technicienId');
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Erreur addTechnicienToIntervention: $e');
      return false;
    }
  }

  /// Ajouter un réfrigérateur à une intervention
  static Future<bool> addRefrigerateurToIntervention({
    required String interventionId,
    required String refrigerateurId,
  }) async {
    try {
      final intervention = getInterventionById(interventionId);
      if (intervention == null) return false;
      
      if (!intervention.refrigerateurIds.contains(refrigerateurId)) {
        intervention.refrigerateurIds.add(refrigerateurId);
        await intervention.save();
        print('✅ Réfrigérateur ajouté à l\'intervention: $refrigerateurId');
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Erreur addRefrigerateurToIntervention: $e');
      return false;
    }
  }

  // ============================================================
  //                      GESTION RAPPORTS
  // ============================================================

  /// Sauvegarder un rapport d'intervention
  static Future<void> saveRapport(RapportIntervention rapport) async {
    final box = Hive.box<RapportIntervention>(_rapportBox);
    await box.put(rapport.id, rapport);
    print('✅ Rapport sauvegardé: ${rapport.id}');
  }

  /// Récupérer un rapport par ID
  static RapportIntervention? getRapportById(String id) {
    final box = Hive.box<RapportIntervention>(_rapportBox);
    return box.get(id);
  }

  /// Récupérer le rapport d'une intervention
  static RapportIntervention? getRapportByIntervention(String interventionId) {
    final box = Hive.box<RapportIntervention>(_rapportBox);
    try {
      return box.values.firstWhere((r) => r.interventionId == interventionId);
    } catch (e) {
      return null;
    }
  }

  /// Obtenir tous les rapports d'un technicien
  static List<RapportIntervention> getRapportsByTechnicien(String technicienId) {
    final box = Hive.box<RapportIntervention>(_rapportBox);
    return box.values.where((r) => r.technicienId == technicienId).toList();
  }

  /// Ajouter une photo au rapport
  static Future<bool> addPhotoToRapport({
    required String rapportId,
    required String cheminPhoto,
    required String type, // 'avant' ou 'apres'
  }) async {
    try {
      final rapport = getRapportById(rapportId);
      if (rapport == null) return false;
      
      if (type == 'avant') {
        rapport.photosAvant.add(cheminPhoto);
      } else {
        rapport.photosApres.add(cheminPhoto);
      }
      
      await rapport.save();
      print('✅ Photo $type ajoutée au rapport: $rapportId');
      return true;
    } catch (e) {
      print('❌ Erreur addPhotoToRapport: $e');
      return false;
    }
  }

  // ============================================================
//                      GESTION PHOTOS
// ============================================================

/// Sauvegarder une photo pour un réfrigérateur
static Future<bool> addPhotoToRefrigerateur({
  required String refrigerateurId,
  required String cheminPhoto,
  required String type, // 'avant', 'pendant', 'apres'
}) async {
  try {
    final refrigerateur = getRefrigerateurById(refrigerateurId);
    if (refrigerateur == null) return false;
    
    // Convertir File en String (chemin)
    final photoPath = cheminPhoto; // Si c'est déjà un chemin
    
    if (type == 'avant') {
      refrigerateur.photosAvantReparation.add(photoPath);
    } else if (type == 'pendant') {
      refrigerateur.photosPendantReparation.add(photoPath);
    } else {
      refrigerateur.photosApresReparation.add(photoPath);
    }
    
    refrigerateur.dateDernieresPhotos = DateTime.now();
    refrigerateur.dernierTechnicienPhotos = getCurrentTechnicien()?.id ?? '';
    
    await refrigerateur.save();
    print('✅ Photo $type ajoutée au réfrigérateur: $refrigerateurId');
    return true;
  } catch (e) {
    print('❌ Erreur addPhotoToRefrigerateur: $e');
    return false;
  }
}

/// Obtenir toutes les photos d'un réfrigérateur
static Map<String, List<String>> getPhotosRefrigerateur(String refrigerateurId) {
  final refrigerateur = getRefrigerateurById(refrigerateurId);
  if (refrigerateur == null) return {};
  
  return {
    'avant': refrigerateur.photosAvantReparation,
    'pendant': refrigerateur.photosPendantReparation,
    'apres': refrigerateur.photosApresReparation,
  };
}

/// Supprimer une photo d'un réfrigérateur
static Future<bool> deletePhotoFromRefrigerateur({
  required String refrigerateurId,
  required String cheminPhoto,
  required String type,
}) async {
  try {
    final refrigerateur = getRefrigerateurById(refrigerateurId);
    if (refrigerateur == null) return false;
    
    bool removed = false;
    
    if (type == 'avant') {
      removed = refrigerateur.photosAvantReparation.remove(cheminPhoto);
    } else if (type == 'pendant') {
      removed = refrigerateur.photosPendantReparation.remove(cheminPhoto);
    } else {
      removed = refrigerateur.photosApresReparation.remove(cheminPhoto);
    }
    
    if (removed) {
      await refrigerateur.save();
      print('✅ Photo supprimée du réfrigérateur: $refrigerateurId');
    }
    
    return removed;
  } catch (e) {
    print('❌ Erreur deletePhotoFromRefrigerateur: $e');
    return false;
  }
}

/// Obtenir le résumé des photos d'un réfrigérateur
static Map<String, int> getResumePhotosRefrigerateur(String refrigerateurId) {
  final refrigerateur = getRefrigerateurById(refrigerateurId);
  if (refrigerateur == null) return {'avant': 0, 'pendant': 0, 'apres': 0, 'total': 0};
  
  final total = refrigerateur.photosAvantReparation.length +
                refrigerateur.photosPendantReparation.length +
                refrigerateur.photosApresReparation.length;
  
  return {
    'avant': refrigerateur.photosAvantReparation.length,
    'pendant': refrigerateur.photosPendantReparation.length,
    'apres': refrigerateur.photosApresReparation.length,
    'total': total,
  };
}

  // ============================================================
  //                      GESTION CHECKLISTS
  // ============================================================

  /// Sauvegarder une checklist
  static Future<void> saveChecklist(Checklist checklist) async {
    final box = Hive.box<Checklist>(_checklistBox);
    await box.put(checklist.id, checklist);
    print('✅ Checklist sauvegardée: ${checklist.id}');
  }

  /// Récupérer une checklist par ID
  static Checklist? getChecklistById(String id) {
    final box = Hive.box<Checklist>(_checklistBox);
    return box.get(id);
  }

  /// Récupérer la checklist d'une intervention
  static Checklist? getChecklistByIntervention(String interventionId) {
    final box = Hive.box<Checklist>(_checklistBox);
    try {
      return box.values.firstWhere((c) => c.interventionId == interventionId);
    } catch (e) {
      return null;
    }
  }

  /// Créer ou récupérer une checklist pour une intervention
  static Future<Checklist> getOrCreateChecklist({
    required String interventionId,
    required String typePanne,
  }) async {
    final box = Hive.box<Checklist>(_checklistBox);
    
    try {
      final existing = box.values.firstWhere((c) => c.interventionId == interventionId);
      return existing;
    } catch (e) {
      // Créer une nouvelle checklist
      final newChecklist = Checklist(
        id: 'checklist_${DateTime.now().millisecondsSinceEpoch}',
        interventionId: interventionId,
        type: typePanne,
        items: _getDefaultChecklistItems(typePanne),
        dateCompletion: DateTime.now(),
        complete: false,
      );
      
      await box.add(newChecklist);
      print('✅ Checklist créée pour intervention: $interventionId');
      return newChecklist;
    }
  }

  static List<ChecklistItem> _getDefaultChecklistItems(String typePanne) {
    // Template par défaut selon le type de panne
    switch (typePanne) {
      case 'Electrique':
        return [
          ChecklistItem(
            id: '1',
            description: 'Vérifier l\'alimentation électrique',
            verifie: false,
            obligatoire: true,
          ),
          ChecklistItem(
            id: '2',
            description: 'Contrôler les fusibles',
            verifie: false,
            obligatoire: true,
          ),
          ChecklistItem(
            id: '3',
            description: 'Tester le compresseur',
            verifie: false,
            obligatoire: true,
          ),
        ];
      case 'Mecanique':
        return [
          ChecklistItem(
            id: '1',
            description: 'Vérifier les joints d\'étanchéité',
            verifie: false,
            obligatoire: true,
          ),
          ChecklistItem(
            id: '2',
            description: 'Contrôler les ventilateurs',
            verifie: false,
            obligatoire: true,
          ),
          ChecklistItem(
            id: '3',
            description: 'Inspecter les serpentins',
            verifie: false,
            obligatoire: true,
          ),
        ];
      default:
        return [
          ChecklistItem(
            id: '1',
            description: 'Diagnostic général',
            verifie: false,
            obligatoire: true,
          ),
        ];
    }
  }

  /// Mettre à jour un item de checklist
  static Future<bool> updateChecklistItem({
    required String checklistId,
    required String itemId,
    required bool verifie,
    String? observation,
    List<String>? photos,
  }) async {
    try {
      final checklist = getChecklistById(checklistId);
      if (checklist == null) return false;
      
      final index = checklist.items.indexWhere((item) => item.id == itemId);
      if (index == -1) return false;
      
      checklist.items[index].verifie = verifie;
      if (observation != null) checklist.items[index].observation = observation;
      if (photos != null) checklist.items[index].photos = photos;
      
      // Vérifier si tous les items obligatoires sont vérifiés
      final tousVerifies = checklist.items
          .where((item) => item.obligatoire)
          .every((item) => item.verifie);
      
      checklist.complete = tousVerifies;
      checklist.dateCompletion = DateTime.now();
      
      await checklist.save();
      print('✅ Item checklist mis à jour: $itemId');
      return true;
    } catch (e) {
      print('❌ Erreur updateChecklistItem: $e');
      return false;
    }
  }

  // ============================================================
  //                      GESTION PIÈCES DÉTACHÉES
  // ============================================================

  /// Sauvegarder une pièce détachée
  static Future<void> savePieceDetachee(PieceDetachee piece) async {
    final box = Hive.box<PieceDetachee>(_pieceBox);
    await box.put(piece.id, piece);
    print('✅ Pièce détachée sauvegardée: ${piece.reference}');
  }

  /// Récupérer une pièce par ID
  static PieceDetachee? getPieceById(String id) {
    final box = Hive.box<PieceDetachee>(_pieceBox);
    return box.get(id);
  }

  /// Récupérer une pièce par référence
  static PieceDetachee? getPieceByReference(String reference) {
    final box = Hive.box<PieceDetachee>(_pieceBox);
    try {
      return box.values.firstWhere((p) => p.reference == reference);
    } catch (e) {
      return null;
    }
  }

  /// Obtenir toutes les pièces
  static List<PieceDetachee> getAllPieces() {
    final box = Hive.box<PieceDetachee>(_pieceBox);
    return box.values.toList();
  }

  /// Obtenir les pièces par catégorie
  static List<PieceDetachee> getPiecesByCategorie(String categorie) {
    final box = Hive.box<PieceDetachee>(_pieceBox);
    return box.values.where((p) => p.categorie == categorie).toList();
  }

  /// Obtenir les pièces en rupture de stock
  static List<PieceDetachee> getPiecesRuptureStock() {
    final box = Hive.box<PieceDetachee>(_pieceBox);
    return box.values.where((p) => p.quantiteStock <= p.seuilMin).toList();
  }

  /// Mettre à jour la quantité en stock
  static Future<bool> updateStockPiece({
    required String pieceId,
    required int nouvelleQuantite,
  }) async {
    try {
      final piece = getPieceById(pieceId);
      if (piece == null) return false;
      
      piece.quantiteStock = nouvelleQuantite;
      await piece.save();
      print('✅ Stock mis à jour pour pièce $pieceId: $nouvelleQuantite');
      return true;
    } catch (e) {
      print('❌ Erreur updateStockPiece: $e');
      return false;
    }
  }

  /// Utiliser une pièce (décrementer le stock)
  static Future<bool> utiliserPiece({
    required String pieceId,
    required int quantiteUtilisee,
  }) async {
    try {
      final piece = getPieceById(pieceId);
      if (piece == null) return false;
      
      if (piece.quantiteStock < quantiteUtilisee) {
        print('❌ Stock insuffisant pour pièce $pieceId');
        return false;
      }
      
      piece.quantiteStock -= quantiteUtilisee;
      await piece.save();
      print('✅ Pièce utilisée: $pieceId (-$quantiteUtilisee)');
      return true;
    } catch (e) {
      print('❌ Erreur utiliserPiece: $e');
      return false;
    }
  }

  // ============================================================
  //                      GESTION CLIENTS
  // ============================================================

  /// Sauvegarder un client
  static Future<void> saveClient(Client client) async {
    final box = Hive.box<Client>(_clientBox);
    await box.put(client.id, client);
    print('✅ Client sauvegardé: ${client.nom}');
  }

  /// Récupérer un client par ID
  static Client? getClientById(String id) {
    final box = Hive.box<Client>(_clientBox);
    return box.get(id);
  }

  /// Obtenir tous les clients
  static List<Client> getAllClients() {
    final box = Hive.box<Client>(_clientBox);
    return box.values.toList();
  }

  /// Obtenir les clients par type
  static List<Client> getClientsByType(String type) {
    final box = Hive.box<Client>(_clientBox);
    return box.values.where((c) => c.type == type).toList();
  }

  // ============================================================
  //                      GESTION NOTIFICATIONS
  // ============================================================

  /// Sauvegarder une notification
  static Future<void> saveNotification(NotificationTech notification) async {
    final box = Hive.box<NotificationTech>(_notificationBox);
    await box.put(notification.id, notification);
    print('✅ Notification sauvegardée: ${notification.titre}');
  }

  /// Récupérer une notification par ID
  static NotificationTech? getNotificationById(String id) {
    final box = Hive.box<NotificationTech>(_notificationBox);
    return box.get(id);
  }

  /// Obtenir toutes les notifications
  static List<NotificationTech> getAllNotifications() {
    final box = Hive.box<NotificationTech>(_notificationBox);
    return box.values.toList();
  }

  /// Obtenir les notifications non lues
  static List<NotificationTech> getNotificationsNonLues() {
    final box = Hive.box<NotificationTech>(_notificationBox);
    return box.values.where((n) => !n.lue).toList();
  }

  /// Marquer une notification comme lue
  static Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      final notification = getNotificationById(notificationId);
      if (notification == null) return false;
      
      notification.lue = true;
      await notification.save();
      print('✅ Notification marquée comme lue: $notificationId');
      return true;
    } catch (e) {
      print('❌ Erreur markNotificationAsRead: $e');
      return false;
    }
  }

  /// Créer une notification d'intervention
  static Future<NotificationTech> createInterventionNotification({
    required String interventionId,
    required String titre,
    required String message,
    int priorite = 2,
  }) async {
    final notification = NotificationTech(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      titre: titre,
      message: message,
      type: 'Intervention',
      date: DateTime.now(),
      lue: false,
      interventionId: interventionId,
    );
    
    await saveNotification(notification);
    return notification;
  }

  // ============================================================
  //                      GESTION PARAMÈTRES
  // ============================================================

  /// Sauvegarder les paramètres
  static Future<void> saveParametres(ParametresApp parametres) async {
    final box = Hive.box<ParametresApp>(_parametresBox);
    
    // Il ne devrait y avoir qu'un seul enregistrement de paramètres
    final existing = box.values.toList();
    if (existing.isNotEmpty) {
      await existing.first.delete();
    }
    
    await box.add(parametres);
    print('✅ Paramètres sauvegardés');
  }

  /// Récupérer les paramètres
  static ParametresApp getParametres() {
    final box = Hive.box<ParametresApp>(_parametresBox);
    
    if (box.values.isEmpty) {
      // Créer des paramètres par défaut
      final defaultParams = ParametresApp(
        langue: 'fr',
        notifications: true,
        gpsAuto: true,
        modeHorsLigne: false,
        derniereSession: '',
        derniereSynchro: DateTime.now(),
      );
      
      box.add(defaultParams);
      return defaultParams;
    }
    
    return box.values.first;
  }

  /// Mettre à jour la langue
  static Future<bool> updateLangue(String langue) async {
    try {
      final parametres = getParametres();
      parametres.langue = langue;
      await parametres.save();
      print('✅ Langue mise à jour: $langue');
      return true;
    } catch (e) {
      print('❌ Erreur updateLangue: $e');
      return false;
    }
  }

  /// Mettre à jour les préférences GPS
  static Future<bool> updateGPSAuto(bool gpsAuto) async {
    try {
      final parametres = getParametres();
      parametres.gpsAuto = gpsAuto;
      await parametres.save();
      print('✅ GPS auto mis à jour: $gpsAuto');
      return true;
    } catch (e) {
      print('❌ Erreur updateGPSAuto: $e');
      return false;
    }
  }

  // ============================================================
  //                      GESTION LOCALISATION
  // ============================================================

  /// Sauvegarder une position GPS
  static Future<void> saveLocalisation(HistoriqueLocalisation localisation) async {
    final box = Hive.box<HistoriqueLocalisation>(_localisationBox);
    await box.add(localisation);
    print('✅ Position GPS sauvegardée: ${localisation.latitude}, ${localisation.longitude}');
  }

  /// Obtenir l'historique des positions d'un technicien
  static List<HistoriqueLocalisation> getHistoriqueLocalisationTechnicien(String technicienId) {
    final box = Hive.box<HistoriqueLocalisation>(_localisationBox);
    return box.values
        .where((l) => l.technicienId == technicienId)
        .toList();
  }

  /// Obtenir la dernière position d'un technicien
  static HistoriqueLocalisation? getDernierePositionTechnicien(String technicienId) {
    final historique = getHistoriqueLocalisationTechnicien(technicienId);
    if (historique.isEmpty) return null;
    
    historique.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return historique.first;
  }

  // ============================================================
  //                      GESTION TEMPLATES
  // ============================================================

  /// Sauvegarder un template de checklist
  static Future<void> saveTemplate(TemplateChecklist template) async {
    final box = Hive.box<TemplateChecklist>(_templateBox);
    await box.put(template.id, template);
    print('✅ Template sauvegardé: ${template.nom}');
  }

  /// Récupérer un template par ID
  static TemplateChecklist? getTemplateById(String id) {
    final box = Hive.box<TemplateChecklist>(_templateBox);
    return box.get(id);
  }

  /// Obtenir tous les templates
  static List<TemplateChecklist> getAllTemplates() {
    final box = Hive.box<TemplateChecklist>(_templateBox);
    return box.values.toList();
  }

  /// Obtenir les templates par type de panne
  static List<TemplateChecklist> getTemplatesByTypePanne(String typePanne) {
    final box = Hive.box<TemplateChecklist>(_templateBox);
    return box.values.where((t) => t.typePanne == typePanne).toList();
  }

  // ============================================================
  //                      MÉTHODES UTILITAIRES
  // ============================================================

  /// Obtenir les statistiques globales
  static Map<String, dynamic> getStatistiquesGlobales(String technicienId) {
    final interventions = getInterventionsByTechnicien(technicienId);
    final rapports = getRapportsByTechnicien(technicienId);
    final refrigerateurs = getAllRefrigerateurs();
    
    final interventionsTerminees = interventions.where((i) => i.statut == 'Terminee').length;
    final interventionsEnCours = interventions.where((i) => i.statut == 'En_cours').length;
    final refrigerateursEnPanne = refrigerateurs.where((r) => r.statut == 'En_panne').length;
    
    return {
      'total_interventions': interventions.length,
      'interventions_terminees': interventionsTerminees,
      'interventions_en_cours': interventionsEnCours,
      'total_rapports': rapports.length,
      'refrigerateurs_en_panne': refrigerateursEnPanne,
      'pieces_stock_bas': getPiecesRuptureStock().length,
      'notifications_non_lues': getNotificationsNonLues().length,
    };
  }

  /// Rechercher des réfrigérateurs proches
  static List<Refrigerateur> searchRefrigerateursProches({
    required double latitude,
    required double longitude,
    required double rayonKm,
    String? statut,
  }) {
    final tous = statut == null 
        ? getAllRefrigerateurs() 
        : getAllRefrigerateurs().where((r) => r.statut == statut).toList();
    
    return tous.where((refrigerateur) {
      final distance = _calculateDistance(
        latitude, longitude,
        refrigerateur.latitude, refrigerateur.longitude,
      );
      return distance <= rayonKm;
    }).toList();
  }

  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0; // Rayon de la Terre en km
    
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    
    final a = sin(dLat / 2) * sin(dLat / 2) +
             cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
             sin(dLon / 2) * sin(dLon / 2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return R * c;
  }

  static double _toRadians(double degrees) {
    return degrees * pi / 180;
  }

  /// Nettoyer les données anciennes
  static Future<void> cleanupOldData() async {
    try {
      final ilYA30Jours = DateTime.now().subtract(const Duration(days: 30));
      
      // Nettoyer l'historique de localisation
      final localisationBox = Hive.box<HistoriqueLocalisation>(_localisationBox);
      final anciennesPositions = localisationBox.values
          .where((l) => l.timestamp.isBefore(ilYA30Jours))
          .toList();
      
      for (var position in anciennesPositions) {
        await position.delete();
      }
      
      print('✅ Données nettoyées: ${anciennesPositions.length} positions supprimées');
    } catch (e) {
      print('❌ Erreur cleanupOldData: $e');
    }
  }

  /// Debug de l'état des données
  static void debugDataState() {
    print('====== DEBUG DATA STATE ======');
    print('Techniciens: ${Hive.box<Technicien>(_technicienBox).length}');
    print('Réfrigérateurs: ${Hive.box<Refrigerateur>(_refrigerateurBox).length}');
    print('Interventions: ${Hive.box<Intervention>(_interventionBox).length}');
    print('Rapports: ${Hive.box<RapportIntervention>(_rapportBox).length}');
    print('Checklists: ${Hive.box<Checklist>(_checklistBox).length}');
    print('Pièces détachées: ${Hive.box<PieceDetachee>(_pieceBox).length}');
    print('Clients: ${Hive.box<Client>(_clientBox).length}');
    print('Notifications: ${Hive.box<NotificationTech>(_notificationBox).length}');
    print('===============================');
  }

  /// Exporter toutes les données (pour debug)
  static Map<String, dynamic> exportAllData() {
    return {
      'techniciens': getAllTechniciens().map((t) => t.toJson()).toList(),
      'refrigerateurs': getAllRefrigerateurs().map((r) => r.toJson()).toList(),
      'interventions': getAllInterventions().map((i) => i.toJson()).toList(),
      'rapports': Hive.box<RapportIntervention>(_rapportBox).values.map((r) => r.toJson()).toList(),
      'parametres': getParametres().toJson(),
    };
  }

  /// Vider toutes les données (reset)
  static Future<void> clearAllData() async {
    try {
      await Hive.box<Technicien>(_technicienBox).clear();
      await Hive.box<Refrigerateur>(_refrigerateurBox).clear();
      await Hive.box<Intervention>(_interventionBox).clear();
      await Hive.box<RapportIntervention>(_rapportBox).clear();
      await Hive.box<Checklist>(_checklistBox).clear();
      await Hive.box<PieceDetachee>(_pieceBox).clear();
      await Hive.box<Client>(_clientBox).clear();
      await Hive.box<NotificationTech>(_notificationBox).clear();
      await Hive.box<ParametresApp>(_parametresBox).clear();
      await Hive.box<HistoriqueLocalisation>(_localisationBox).clear();
      await Hive.box<TemplateChecklist>(_templateBox).clear();
      await Hive.box(_currentUserKey).clear();
      await Hive.box(_sessionKey).clear();
      
      print('✅ Toutes les données ont été effacées');
    } catch (e) {
      print('❌ Erreur clearAllData: $e');
    }
  }

  /// Obtenir les notifications d'aujourd'hui
  static List<NotificationTech> getNotificationsDuJour() {
    final box = Hive.box<NotificationTech>(_notificationBox);
    final aujourdHui = DateTime.now();
    
    return box.values.where((notification) {
      return notification.date.year == aujourdHui.year &&
             notification.date.month == aujourdHui.month &&
             notification.date.day == aujourdHui.day;
    }).toList();
  }

  /// Obtenir le nombre de notifications par type
  static int getNotificationsCountByType(String type) {
    final box = Hive.box<NotificationTech>(_notificationBox);
    return box.values.where((n) => n.type == type).length;
  }

  /// Méthode utilitaire pour générer un ID unique
  static String generateUniqueId({String prefix = ''}) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(9999);
    return '${prefix}${timestamp}_$random';
  }

  /// Obtenir un technicien aléatoire (pour les tests)
  static Technicien getRandomTechnicien() {
    final techniciens = getAllTechniciens();
    if (techniciens.isEmpty) {
      throw Exception('Aucun technicien disponible');
    }
    return techniciens[_random.nextInt(techniciens.length)];
  }

  /// Obtenir un client aléatoire (pour les tests)
  static Client getRandomClient() {
    final clients = getAllClients();
    if (clients.isEmpty) {
      throw Exception('Aucun client disponible');
    }
    return clients[_random.nextInt(clients.length)];
  }

  /// Obtenir un réfrigérateur aléatoire (pour les tests)
  static Refrigerateur getRandomRefrigerateur() {
    final refrigerateurs = getAllRefrigerateurs();
    if (refrigerateurs.isEmpty) {
      throw Exception('Aucun réfrigérateur disponible');
    }
    return refrigerateurs[_random.nextInt(refrigerateurs.length)];
  }

  /// Obtenir une pièce aléatoire (pour les tests)
  static PieceDetachee getRandomPiece() {
    final pieces = getAllPieces();
    if (pieces.isEmpty) {
      throw Exception('Aucune pièce disponible');
    }
    return pieces[_random.nextInt(pieces.length)];
  }

  /// Générer des données de test supplémentaires
  static Future<void> generateMoreTestData({int count = 10}) async {
    print('🔄 Génération de $count données de test supplémentaires...');
    
    for (int i = 0; i < count; i++) {
      // Créer des interventions supplémentaires
      final newIntervention = Intervention(
        id: generateUniqueId(prefix: 'int_'),
        code: 'INT-2024-${100 + i}',
        type: _random.nextBool() ? 'Maintenance' : 'Reparation',
        priorite: _random.nextInt(3) + 1,
        statut: _random.nextBool() ? 'Planifiee' : 'Terminee',
        dateCreation: DateTime.now().subtract(Duration(days: _random.nextInt(30))),
        datePlanifiee: DateTime.now().add(Duration(days: _random.nextInt(30))),
        dateDebut: _random.nextBool() ? DateTime.now().subtract(Duration(days: _random.nextInt(10))) : null,
        dateFin: _random.nextBool() ? DateTime.now().subtract(Duration(days: _random.nextInt(5))) : null,
        technicienIds: [getRandomTechnicien().id],
        refrigerateurIds: [getRandomRefrigerateur().id],
        description: 'Intervention de test #${i + 1}',
        clientId: getRandomClient().id,
        synchronise: _random.nextBool(),
        updatedAt: DateTime.now(),
      );
      
      await saveIntervention(newIntervention);
    }
    
    print('✅ $count données de test supplémentaires générées');
  }


// Méthodes pour mettre à jour le statut d'une intervention
static void updateInterventionStatus(String interventionId, String newStatus) {
  final interventionBox = Hive.box<Intervention>('interventions');
  final intervention = interventionBox.values.firstWhere((i) => i.id == interventionId);
  intervention.statut = newStatus;
  intervention.save();
}

// Méthode pour mettre à jour les caractéristiques d'un réfrigérateur
static void updateRefrigerateurCaracteristique(String refrigerateurId, Map<String, dynamic> caracteristiques) {
  final refrigerateurBox = Hive.box<Refrigerateur>('refrigerateurs');
  final refrigerateur = refrigerateurBox.values.firstWhere((r) => r.id == refrigerateurId);
  refrigerateur.caracteristiques = caracteristiques;
  refrigerateur.save();
}

// Méthode pour mettre à jour le statut d'un réfrigérateur
static void updateRefrigerateurStatus(String refrigerateurId, String newStatus) {
  final refrigerateurBox = Hive.box<Refrigerateur>('refrigerateurs');
  final refrigerateur = refrigerateurBox.values.firstWhere((r) => r.id == refrigerateurId);
  refrigerateur.statut = newStatus;
  refrigerateur.save();
}
}