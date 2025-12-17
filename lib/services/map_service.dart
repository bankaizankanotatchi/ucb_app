import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ucb_app/models/refrigerateur.dart';
import 'package:ucb_app/models/historique_localisation.dart';
import 'package:ucb_app/services/hive_service.dart';
import 'package:ucb_app/services/offline_tile_service.dart';
import 'package:http/http.dart' as http; 

class MapService {
  static final MapService _instance = MapService._internal();
  factory MapService() => _instance;
  MapService._internal();

  // 👇 NEW: Add your API key here after signing up
  static const String _openRouteServiceApiKey = 'eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6IjRkYTIwZGQ1YWRkYzQ5NjI4NjFmMzlhNjA4ZGY0ODA2IiwiaCI6Im11cm11cjY0In0='; 

  // Variables pour la géolocalisation continue
  StreamSubscription<Position>? _positionStream;
  LatLng? _currentUserPosition;
  bool _isTracking = false;

  // Configuration
  static const double _defaultZoom = 13.0;
  static const double _maxZoom = 25.0;
  static const double _minZoom = 1.0;

  // Initialiser le service - MODIFIÉ
  Future<void> initialize() async {
    print('🔄 Initialisation MapService...');
    
    try {
      // 1. Initialiser le service de tuiles offline
      await OfflineTileService().initialize();
      
      print('✅ MapService initialisé avec tuiles offline');
      
    } catch (e) {
      print('❌ Erreur initialisation MapService: $e');
    }
  }

  // ==================== GÉOLOCALISATION ====================
  
  /// Obtenir la position actuelle avec permission - MODIFIÉ
  Future<LatLng?> getCurrentPosition({bool requestPermission = true}) async {
    try {
      if (requestPermission) {
        final hasPermission = await _requestLocationPermission();
        if (!hasPermission) {
          print('❌ Permission de localisation refusée');
          return null;
        }
      }
      
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('⚠️ Service de localisation désactivé');
        // Optionnel : Demander à l'utilisateur d'activer la localisation
        return null;
      }
      
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: Duration(seconds: 10),
      );
      
      _currentUserPosition = LatLng(position.latitude, position.longitude);
      print('📍 Position obtenue: ${_currentUserPosition!.latitude}, ${_currentUserPosition!.longitude}');
      return _currentUserPosition;
      
    } catch (e) {
      print('❌ Erreur getCurrentPosition: $e');
      return null;
    }
  }
  
  /// Démarrer le tracking en temps réel - MODIFIÉ
  Future<void> startTracking(String technicienId) async {
    if (_isTracking) return;
    
    try {
      final hasPermission = await _requestLocationPermission();
      if (!hasPermission) {
        print('❌ Permission refusée, tracking impossible');
        return;
      }
      
      // Vérifier si le service est activé
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('⚠️ Service GPS désactivé');
        return;
      }
      
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 10, // Mètres
          timeLimit: Duration(seconds: 30),
        ),
      ).listen((Position position) {
        _currentUserPosition = LatLng(position.latitude, position.longitude);
        
        // Sauvegarder dans l'historique
        _savePositionToHistory(technicienId, position);
        
        // Émettre un événement pour les listeners
        if (_positionController.hasListener && !_positionController.isClosed) {
          _positionController.add(_currentUserPosition!);
        }
        
        print('📍 Position mise à jour: ${position.latitude}, ${position.longitude}');
      }, onError: (e) {
        print('❌ Erreur flux position: $e');
      });
      
      _isTracking = true;
      print('📍 Tracking GPS démarré avec succès');
      
    } catch (e) {
      print('❌ Erreur startTracking: $e');
      _isTracking = false;
    }
  }
  
  /// Arrêter le tracking
  void stopTracking() {
    if (_positionStream != null) {
      _positionStream!.cancel();
      _positionStream = null;
    }
    _isTracking = false;
    print('📍 Tracking GPS arrêté');
  }
  
  /// Sauvegarder la position dans l'historique
  Future<void> _savePositionToHistory(String technicienId, Position position) async {
    try {
      final localisation = HistoriqueLocalisation(
        id: 'loc_${DateTime.now().millisecondsSinceEpoch}',
        technicienId: technicienId,
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
      );
      
      await HiveService.saveLocalisation(localisation);
    } catch (e) {
      print('❌ Erreur savePositionToHistory: $e');
    }
  }
  
/// Demander la permission de localisation - VERSION CORRIGÉE
Future<bool> _requestLocationPermission() async {
  try {
    print('🔍 Vérification des permissions...');
    
    // Pour Flutter, utiliser locationWhenInUse au lieu de location
    var status = await Permission.locationWhenInUse.status;
    print('📱 État permission (locationWhenInUse): $status');
    
    if (status.isDenied) {
      print('📱 Demande de permission locationWhenInUse...');
      status = await Permission.locationWhenInUse.request();
      
      if (status.isPermanentlyDenied) {
        print('⚠️ Permission refusée définitivement');
        await openAppSettings();
        return false;
      }
    }
    
    // Vérifier aussi locationAlways pour le tracking en arrière-plan
    if (_isTracking) {
      final alwaysStatus = await Permission.locationAlways.status;
      if (alwaysStatus.isDenied) {
        await Permission.locationAlways.request();
      }
    }
    
    final isGranted = status.isGranted || status.isLimited;
    print(isGranted ? '✅ Permission accordée' : '❌ Permission refusée');
    return isGranted;
    
  } catch (e) {
    print('❌ Erreur permission: $e');
    return false;
  }
}
  
  // ==================== RÉFRIGÉRATEURS ====================
  
  /// Trouver les réfrigérateurs en panne les plus proches
  List<Refrigerateur> getNearestRefrigerateursEnPanne({
    required LatLng userPosition,
    double radiusKm = 15.0,
    int limit = 10,
  }) {
    try {
      final allRefrigerateurs = HiveService.getAllRefrigerateurs();
      
      // Filtrer et calculer les distances
      final refrigerateursAvecDistance = allRefrigerateurs
          .where((r) => r.statut == 'En_panne')
          .map((r) {
            final distance = calculateDistance(
              userPosition.latitude,
              userPosition.longitude,
              r.latitude,
              r.longitude,
            );
            return {
              'refrigerateur': r,
              'distance': distance,
            };
          })
          .where((item) => (item['distance'] as double) <= radiusKm)
          .toList();
      
      // Trier par distance
      refrigerateursAvecDistance.sort((a, b) => 
          (a['distance'] as double).compareTo(b['distance'] as double));
      
      // Retourner la limite demandée
      return refrigerateursAvecDistance
          .take(limit)
          .map((item) => item['refrigerateur'] as Refrigerateur)
          .toList();
    } catch (e) {
      print('❌ Erreur getNearestRefrigerateursEnPanne: $e');
      return [];
    }
  }
  
  /// Trouver le chemin optimal (algorithme du plus proche voisin)
  List<Refrigerateur> findOptimalRoute({
    required LatLng startPosition,
    required List<Refrigerateur> refrigerateurs,
  }) {
    if (refrigerateurs.isEmpty) return [];
    
    final List<Refrigerateur> route = [];
    final List<Refrigerateur> remaining = List.from(refrigerateurs);
    LatLng currentPosition = startPosition;
    
    while (remaining.isNotEmpty) {
      // Trouver le plus proche
      Refrigerateur nearest = remaining[0];
      double nearestDistance = calculateDistance(
        currentPosition.latitude,
        currentPosition.longitude,
        nearest.latitude,
        nearest.longitude,
      );
      
      for (int i = 1; i < remaining.length; i++) {
        final distance = calculateDistance(
          currentPosition.latitude,
          currentPosition.longitude,
          remaining[i].latitude,
          remaining[i].longitude,
        );
        
        if (distance < nearestDistance) {
          nearest = remaining[i];
          nearestDistance = distance;
        }
      }
      
      // Ajouter à la route et passer à la position suivante
      route.add(nearest);
      remaining.remove(nearest);
      currentPosition = LatLng(nearest.latitude, nearest.longitude);
    }
    
    return route;
  }
  
  // ==================== CALCULS GÉOMÉTRIQUES ====================
  
  /// Calculer la distance entre deux points (km)
  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0; // Rayon de la Terre en km
    
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    
    final a = sin(dLat / 2) * sin(dLat / 2) +
             cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
             sin(dLon / 2) * sin(dLon / 2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return R * c;
  }
  
  /// Calculer le temps estimé (minutes)
  static int calculateEstimatedTime(double distanceKm, 
      {String transportMode = 'car'}) {
    double speedKmh;
    
    switch (transportMode) {
      case 'car':
        speedKmh = 40.0; // Circulation urbaine
        break;
      case 'motorcycle':
        speedKmh = 50.0;
        break;
      case 'bike':
        speedKmh = 15.0;
        break;
      case 'walking':
        speedKmh = 5.0;
        break;
      default:
        speedKmh = 40.0;
    }
    
    return ((distanceKm / speedKmh) * 60).round();
  }
  
  /// Convertir degrés en radians
  static double _toRadians(double degrees) {
    return degrees * pi / 180;
  }
  
  /// Calculer le point médian entre plusieurs positions
  static LatLng calculateCenterPoint(List<LatLng> points) {
    if (points.isEmpty) {
      return const LatLng(4.0511, 9.7679); // Douala par défaut
    }
    
    double sumX = 0;
    double sumY = 0;
    double sumZ = 0;
    
    for (final point in points) {
      final latRad = _toRadians(point.latitude);
      final lonRad = _toRadians(point.longitude);
      
      sumX += cos(latRad) * cos(lonRad);
      sumY += cos(latRad) * sin(lonRad);
      sumZ += sin(latRad);
    }
    
    final avgX = sumX / points.length;
    final avgY = sumY / points.length;
    final avgZ = sumZ / points.length;
    
    final lon = atan2(avgY, avgX);
    final hyp = sqrt(avgX * avgX + avgY * avgY);
    final lat = atan2(avgZ, hyp);
    
    return LatLng(
      lat * 180 / pi,
      lon * 180 / pi,
    );
  }
  
  // ==================== ÉVÉNEMENTS ET LISTENERS ====================
  
  final StreamController<LatLng> _positionController = 
      StreamController<LatLng>.broadcast();
  
  Stream<LatLng> get positionStream => _positionController.stream;
  
  LatLng? get currentUserPosition => _currentUserPosition;
  
  bool get isTracking => _isTracking;
  
  // Nettoyage
  void dispose() {
    stopTracking();
    _positionController.close();
  }

    // ==================== ROUTE CALCULATION (NEW METHOD) ====================
  
  /// Calculate a realistic route between two points using OpenRouteService API.
  Future<List<LatLng>> calculateRoute({
    required LatLng start,
    required LatLng end,
    String profile = 'driving-car', // Other options: 'foot-walking', 'cycling-regular'
  }) async {
    // 👇 Basic validation for the API key
    if (_openRouteServiceApiKey.isEmpty || _openRouteServiceApiKey == 'YOUR_API_KEY_HERE') {
      print('❌ OpenRouteService API key not configured. Please sign up at openrouteservice.org and add your key.');
      // Fallback to a straight line if no key
      return _createStraightLineRoute(start, end);
    }

    try {
      final url = Uri.parse('https://api.openrouteservice.org/v2/directions/$profile/geojson');
      
      final response = await http.post(
        url,
        headers: {
          'Authorization': _openRouteServiceApiKey,
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json, application/geo+json',
        },
        body: json.encode({
          'coordinates': [
            [start.longitude, start.latitude], // ORS expects [lon, lat]
            [end.longitude, end.latitude]
          ]
        }),
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        // Navigate the GeoJSON structure to extract coordinates
        final List<dynamic> coordinates = data['features'][0]['geometry']['coordinates'];
        
        // Convert from [lon, lat] to LatLng(lat, lon)
        return coordinates.map<LatLng>((coord) {
          return LatLng(coord[1], coord[0]);
        }).toList();
      } else {
        print('❌ API Error: ${response.statusCode} - ${response.body}');
        // Fallback to a straight line on API error
        return _createStraightLineRoute(start, end);
      }
    } catch (e) {
      print('❌ Network/Request Error calculating route: $e');
      // Fallback to a straight line on network error
      return _createStraightLineRoute(start, end);
    }
  }
  
  /// Fallback method: creates a simple straight-line route.
  List<LatLng> _createStraightLineRoute(LatLng start, LatLng end) {
    print('⚠️ Using straight-line fallback route.');
    return [start, end];
  }
  /// Calcule la distance totale d'une route (en km)
static double calculateRouteDistance(List<LatLng> routePoints) {
  if (routePoints.length < 2) return 0.0;
  
  double totalDistance = 0.0;
  for (int i = 0; i < routePoints.length - 1; i++) {
    final point1 = routePoints[i];
    final point2 = routePoints[i + 1];
    totalDistance += calculateDistance(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    );
  }
  return totalDistance;
}
}