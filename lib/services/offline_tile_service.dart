import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:archive/archive.dart';
import 'package:latlong2/latlong.dart';

class OfflineTileService {
  static const String _tilesDirectory = 'offline_tiles';
  static const String _manifestFile = 'tile_manifest.json';
  
  // MODIFIEZ CES LIGNES :
  Directory? _appDocumentsDir;
  Directory? _tilesDir;
  
  // Fournisseurs de tuiles - SIMPLIFIÉ
  final Map<String, String> _tileProviders = {
    'osm': 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    'carto_light': 'https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
  };
  
  // Initialiser le service - CORRIGÉ
  Future<void> initialize() async {
    try {
      print('🔄 Initialisation OfflineTileService...');
      
      _appDocumentsDir = await getApplicationDocumentsDirectory();
      _tilesDir = Directory('${_appDocumentsDir!.path}/$_tilesDirectory');
      
      print('📁 Chemin tuiles: ${_tilesDir!.path}');
      
      if (!await _tilesDir!.exists()) {
        await _tilesDir!.create(recursive: true);
        print('✅ Répertoire tuiles créé');
      } else {
        print('✅ Répertoire tuiles existe déjà');
      }
      
      // Charger ou créer le manifest
      await _loadOrCreateManifest();
      
      // Vérifier le contenu actuel
      final manifest = _loadManifest();
      print('📊 Manifest chargé: ${manifest['areas']?.length ?? 0} zones');
      
      print('✅ OfflineTileService initialisé');
      
    } catch (e) {
      print('❌ Erreur initialisation OfflineTileService: $e');
      // Créer un répertoire fallback
      _tilesDir = Directory('offline_tiles');
    }
  }
  
  /// Télécharger les tuiles pour une zone spécifique - AMÉLIORÉ
  Future<void> downloadAreaTiles({
    required LatLng center,
    required double radiusKm,
    required List<int> zoomLevels,
    String provider = 'osm',
  }) async {
    try {
      if (_tilesDir == null) {
        await initialize();
      }
      
      print('🗺️ Téléchargement tuiles pour zone autour de $center');
      print('📐 Rayon: ${radiusKm}km, Zooms: $zoomLevels');
      
      // Calculer les limites de la zone
      final bounds = _calculateBoundingBox(center, radiusKm);
      print('📦 Bounding Box: N${bounds.north}, S${bounds.south}, E${bounds.east}, W${bounds.west}');
      
      // Pour chaque niveau de zoom
      for (final zoom in zoomLevels) {
        print('🔍 Niveau zoom: $zoom');
        
        // Calculer les coordonnées de tuiles
        final tileRange = _calculateTileRange(bounds, zoom);
        
        print('📊 Plage tuiles: X[${tileRange.minX}-${tileRange.maxX}], Y[${tileRange.minY}-${tileRange.maxY}]');
        
        int totalTiles = (tileRange.maxX - tileRange.minX + 1) * 
                        (tileRange.maxY - tileRange.minY + 1);
        
        if (totalTiles > 100) {
          print('⚠️ Attention: $totalTiles tuiles à télécharger pour zoom $zoom');
          print('⚠️ Cela peut prendre plusieurs minutes et consommer des données');
        }
        
        int downloaded = 0;
        int errors = 0;
        
        // Télécharger chaque tuile
        for (int x = tileRange.minX; x <= tileRange.maxX; x++) {
          for (int y = tileRange.minY; y <= tileRange.maxY; y++) {
            try {
              await _downloadTile(x, y, zoom, provider);
              downloaded++;
              
              // Progress indication
              if (downloaded % 5 == 0 || downloaded == totalTiles) {
                final progress = (downloaded / totalTiles * 100).toStringAsFixed(1);
                print('📥 Progression: $progress% ($downloaded/$totalTiles)');
              }
            } catch (e) {
              errors++;
              if (errors <= 3) {
                print('⚠️ Échec tuile $x,$y,$zoom: $e');
              }
            }
          }
        }
        
        print('✅ Niveau $zoom terminé: $downloaded/$totalTiles tuiles (erreurs: $errors)');
        
        // Sauvegarder dans le manifest
        if (downloaded > 0) {
          await _updateManifest(center, radiusKm, zoom, tileRange, provider);
        }
      }
      
      print('🎉 Téléchargement terminé!');
      
    } catch (e) {
      print('❌ Erreur downloadAreaTiles: $e');
      rethrow;
    }
  }
  
  /// Télécharger une tuile individuelle - AMÉLIORÉ
  Future<void> _downloadTile(int x, int y, int zoom, String provider) async {
    final url = _tileProviders[provider]!
        .replaceAll('{x}', x.toString())
        .replaceAll('{y}', y.toString())
        .replaceAll('{z}', zoom.toString());
    
    final tilePath = '${_tilesDir!.path}/$provider/$zoom/$x';
    final tileFile = File('$tilePath/${y}${_getTileExtension(provider)}');
    
    // Vérifier si la tuile existe déjà
    if (await tileFile.exists()) {
      return;
    }
    
    try {
      // Créer le répertoire
      await Directory(tilePath).create(recursive: true);
      
      // Télécharger avec Dio avec timeout
      final dio = Dio();
      final response = await dio.get(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: Duration(seconds: 10),
        ),
      );
      
      // Vérifier la taille
      if (response.data != null && response.data.length > 100) {
        await tileFile.writeAsBytes(response.data);
        // print('   ✓ Tuile $x,$y,$zoom téléchargée');
      } else {
        print('   ⚠️ Tuile $x,$y,$zoom vide ou trop petite');
      }
      
    } catch (e) {
      // Échec silencieux pour ne pas ralentir le processus
      throw Exception('Tuile $x,$y,$zoom: $e');
    }
  }
  
  /// Obtenir le chemin d'une tuile - CORRIGÉ
  String? getTilePath(int x, int y, int zoom, {String provider = 'osm'}) {
    if (_tilesDir == null) {
      print('⚠️ _tilesDir non initialisé');
      return null;
    }
    
    final tilePath = '${_tilesDir!.path}/$provider/$zoom/$x/${y}${_getTileExtension(provider)}';
    final tileFile = File(tilePath);
    
    if (tileFile.existsSync()) {
      return tileFile.path;
    }
    
    return null;
  }
  
  /// Vérifier si une zone est disponible offline
  bool isAreaAvailable(LatLng center, double radiusKm, int zoom) {
    if (_tilesDir == null) return false;
    
    final manifest = _loadManifest();
    
    for (final entry in manifest['areas'] ?? []) {
      final areaCenter = LatLng(
        entry['center']['lat'],
        entry['center']['lng'],
      );
      
      final areaRadius = entry['radius'];
      final areaZooms = List<int>.from(entry['zooms'] ?? []);
      
      final distance = _calculateDistance(
        center.latitude,
        center.longitude,
        areaCenter.latitude,
        areaCenter.longitude,
      );
      
      if (distance <= (areaRadius + radiusKm) && areaZooms.contains(zoom)) {
        return true;
      }
    }
    
    return false;
  }
  
  /// Vérifier le nombre de tuiles téléchargées
  int countDownloadedTiles() {
    if (_tilesDir == null || !_tilesDir!.existsSync()) return 0;
    
    int count = 0;
    try {
      final directories = _tilesDir!.listSync(recursive: true);
      for (var entity in directories) {
        if (entity is File && entity.path.endsWith('.png')) {
          count++;
        }
      }
    } catch (e) {
      print('❌ Erreur comptage tuiles: $e');
    }
    
    return count;
  }
  
  // ==================== MÉTHODES PRIVÉES ====================
  
  Future<void> _loadOrCreateManifest() async {
    if (_tilesDir == null) return;
    
    final manifestFile = File('${_tilesDir!.path}/$_manifestFile');
    
    if (!await manifestFile.exists()) {
      final initialManifest = {
        'version': '1.0',
        'created': DateTime.now().toIso8601String(),
        'areas': [],
        'total_tiles': 0,
      };
      
      await manifestFile.writeAsString(jsonEncode(initialManifest));
      print('📄 Manifest créé');
    } else {
      print('📄 Manifest existant chargé');
    }
  }
  
  Future<void> _updateManifest(
    LatLng center,
    double radius,
    int zoom,
    TileRange range,
    String provider,
  ) async {
    if (_tilesDir == null) return;
    
    try {
      final manifestFile = File('${_tilesDir!.path}/$_manifestFile');
      final content = await manifestFile.readAsString();
      final manifest = jsonDecode(content);
      
      final areaData = {
        'center': {'lat': center.latitude, 'lng': center.longitude},
        'radius': radius,
        'zooms': [zoom],
        'provider': provider,
        'tile_range': {
          'min_x': range.minX,
          'max_x': range.maxX,
          'min_y': range.minY,
          'max_y': range.maxY,
          'zoom': zoom,
        },
        'downloaded_at': DateTime.now().toIso8601String(),
        'tile_count': (range.maxX - range.minX + 1) * (range.maxY - range.minY + 1),
      };
      
      // Ajouter ou mettre à jour la zone
      final areas = List<dynamic>.from(manifest['areas'] ?? []);
      
      // Vérifier si cette zone existe déjà
      bool updated = false;
      for (int i = 0; i < areas.length; i++) {
        final area = areas[i];
        if (area['center']['lat'] == center.latitude &&
            area['center']['lng'] == center.longitude &&
            area['provider'] == provider) {
          
          // Ajouter le zoom si pas déjà présent
          final zooms = List<int>.from(area['zooms'] ?? []);
          if (!zooms.contains(zoom)) {
            zooms.add(zoom);
            area['zooms'] = zooms;
          }
          
          areas[i] = area;
          updated = true;
          break;
        }
      }
      
      if (!updated) {
        areas.add(areaData);
      }
      
      // Mettre à jour le manifest
      manifest['areas'] = areas;
      manifest['last_updated'] = DateTime.now().toIso8601String();
      manifest['total_tiles'] = countDownloadedTiles();
      
      await manifestFile.writeAsString(jsonEncode(manifest));
      print('📄 Manifest mis à jour');
      
    } catch (e) {
      print('❌ Erreur mise à jour manifest: $e');
    }
  }
  
  Map<String, dynamic> _loadManifest() {
    if (_tilesDir == null || !_tilesDir!.existsSync()) {
      return {'areas': []};
    }
    
    final manifestFile = File('${_tilesDir!.path}/$_manifestFile');
    
    if (manifestFile.existsSync()) {
      try {
        final content = manifestFile.readAsStringSync();
        return jsonDecode(content);
      } catch (e) {
        print('❌ Erreur chargement manifest: $e');
      }
    }
    
    return {'areas': []};
  }
  
  /// Calculer la boîte englobante
  BoundingBox _calculateBoundingBox(LatLng center, double radiusKm) {
    // Conversion degrés -> km (approximative)
    const latPerKm = 1 / 111.32; // 1 degré de latitude ≈ 111.32 km
    final lngPerKm = 1 / (111.32 * cos(center.latitude * pi / 180));
    
    final deltaLat = radiusKm * latPerKm;
    final deltaLng = radiusKm * lngPerKm;
    
    return BoundingBox(
      north: center.latitude + deltaLat,
      south: center.latitude - deltaLat,
      east: center.longitude + deltaLng,
      west: center.longitude - deltaLng,
    );
  }
  
  /// Calculer la plage de tuiles
  TileRange _calculateTileRange(BoundingBox bounds, int zoom) {
    try {
      final minTile = _latLngToTile(bounds.south, bounds.west, zoom);
      final maxTile = _latLngToTile(bounds.north, bounds.east, zoom);
      
      return TileRange(
        minX: minTile.x.floor(),
        maxX: maxTile.x.ceil(),
        minY: minTile.y.floor(),
        maxY: maxTile.y.ceil(),
      );
    } catch (e) {
      print('❌ Erreur calcul plage tuiles: $e');
      return TileRange(minX: 0, maxX: 0, minY: 0, maxY: 0);
    }
  }
  
  /// Convertir latitude/longitude en coordonnées tuile
  Point<double> _latLngToTile(double lat, double lng, int zoom) {
    final latRad = lat * pi / 180;
    final n = pow(2.0, zoom);
    
    final x = ((lng + 180.0) / 360.0) * n;
    final y = (1.0 - (log(tan(latRad) + 1 / cos(latRad)) / pi)) / 2.0 * n;
    
    return Point<double>(x, y);
  }
  
  /// Calculer la distance entre deux points (km)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0;
    
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    
    final a = sin(dLat / 2) * sin(dLat / 2) +
             cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
             sin(dLon / 2) * sin(dLon / 2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return R * c;
  }
  
  String _getTileExtension(String provider) {
    if (provider.contains('pbf')) return '.pbf';
    if (provider.contains('png')) return '.png';
    if (provider.contains('jpg')) return '.jpg';
    return '.png';
  }
}

// Classes auxiliaires
class BoundingBox {
  final double north;
  final double south;
  final double east;
  final double west;
  
  BoundingBox({
    required this.north,
    required this.south,
    required this.east,
    required this.west,
  });
}

class TileRange {
  final int minX;
  final int maxX;
  final int minY;
  final int maxY;
  
  TileRange({
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
  });
}