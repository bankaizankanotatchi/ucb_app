import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:ucb_app/constants/app_theme.dart';
import 'package:ucb_app/models/technicien.dart';
import 'package:ucb_app/models/refrigerateur.dart';
import 'package:ucb_app/pages/dashboard/maps/refrigerateur_detail_screen.dart';
import 'package:ucb_app/pages/dashboard/maps/widgets/route_info_card.dart';
import 'package:ucb_app/services/hive_service.dart';
import 'package:ucb_app/services/map_service.dart';
import 'package:url_launcher/url_launcher.dart';

class MapScreen extends StatefulWidget {
  final Technicien technicien;
  
  const MapScreen({super.key, required this.technicien});
  
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Services
  final MapService _mapService = MapService();
  
  // Données
  LatLng? _userPosition;
  List<Refrigerateur> _refrigerateurs = [];
  Refrigerateur? _selectedRefrigerateur;
  
  // État UI
  bool _isLoading = true;
  bool _isTracking = false;
  double _mapZoom = 15.0;
  LatLng _mapCenter = const LatLng(4.0511, 9.7679);
  
  // Filtres
  Map<String, bool> _filters = {
    'Fonctionnel': true,
    'En_panne': true,
    'Maintenance': true,
    'Avec_photos': false,
  };
  
  // Types de carte
  int _selectedMapType = 0;
  List<String> _mapTypes = [
    'OpenStreetMap',
    'Satellite',
    'Terrain',
    'Routier'
  ];
  
  // Route entre technicien et réfrigérateur
  List<LatLng> _navigationRoute = [];
  double _routeDistance = 0.0; // Distance réelle de la route
  bool _isCalculatingRoute = false;
  String _transportMode = 'walking'; // Mode de transport
  Timer? _markerAnimationTimer;
  double _markerAnimationRadius = 0.0;
  bool _showMarkerAnimation = false;
  
  // État pour le bouton de suppression de route
  bool _showClearRouteButton = false;
  
  // Contrôleurs
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _initializeMap();
  }
  
  @override
  void dispose() {
    _mapService.dispose();
    _searchController.dispose();
    _mapController.dispose();
    _markerAnimationTimer?.cancel();
    super.dispose();
  }

  void _loadRefrigerateursDuTechnicien() {
    final technicien = HiveService.getCurrentTechnicien();
    if (technicien == null) return;
    
    final interventions = HiveService.getInterventionsByTechnicien(technicien.id);
    final refrigerateurIds = <String>{};
    
    for (final intervention in interventions) {
      refrigerateurIds.addAll(intervention.refrigerateurIds);
    }
    
    final tousRefrigerateurs = HiveService.getAllRefrigerateurs();
    
    setState(() {
      _refrigerateurs = tousRefrigerateurs
          .where((r) => refrigerateurIds.contains(r.id))
          .toList();
    });
    
    print('🧊 Réfrigérateurs du technicien: ${_refrigerateurs.length}');
  }
  
  Future<void> _initializeMap() async {
    setState(() => _isLoading = true);
    
    try {
      await _mapService.initialize();
      
      // 1. Obtenir position du technicien en priorité
      try {
        _userPosition = await _mapService.getCurrentPosition();
        if (_userPosition != null) {
          print('📍 Position GPS obtenue');
          _mapCenter = _userPosition!;
          _mapZoom = 15.0;
        }
      } catch (e) {
        print('⚠️ GPS non disponible: $e');
      }
      
      // 2. Charger les réfrigérateurs
      _loadRefrigerateursDuTechnicien();
      
      // 3. Si pas de position GPS, utiliser le centre des réfrigérateurs
      if (_userPosition == null && _refrigerateurs.isNotEmpty) {
        final latitudes = _refrigerateurs.map((r) => r.latitude).toList();
        final longitudes = _refrigerateurs.map((r) => r.longitude).toList();
        
        final avgLat = latitudes.reduce((a, b) => a + b) / latitudes.length;
        final avgLng = longitudes.reduce((a, b) => a + b) / longitudes.length;
        
        _mapCenter = LatLng(avgLat, avgLng);
        _mapZoom = 16.0;
      }
      
    } catch (e) {
      print('❌ Erreur initialisation carte: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<void> _toggleTracking() async {
    if (_isTracking) {
      _mapService.stopTracking();
      setState(() => _isTracking = false);
    } else {
      await _mapService.startTracking(widget.technicien.id);
      setState(() => _isTracking = true);
    }
  }
  
  void _selectRefrigerateur(Refrigerateur refrigerateur) {
    // Arrêter l'animation précédente
    _markerAnimationTimer?.cancel();
    
    setState(() {
      _selectedRefrigerateur = refrigerateur;
      _navigationRoute = [];
      _routeDistance = 0.0;
      _isCalculatingRoute = true;
      _showMarkerAnimation = true;
      _markerAnimationRadius = 0.0;
      _showClearRouteButton = true; // Afficher le bouton de suppression
    });
    
    // Démarrer l'animation
    _startMarkerAnimation();
    
    if (_userPosition != null) {
      _calculateNavigationRoute(refrigerateur);
    }
  }
  
  void _startMarkerAnimation() {
    _markerAnimationTimer?.cancel();
    
    _markerAnimationTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      if (mounted && _showMarkerAnimation) {
        setState(() {
          _markerAnimationRadius = 30.0;
        });
        
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              _markerAnimationRadius = 0.0;
            });
          }
        });
      } else {
        timer.cancel();
      }
    });
  }
  
  Future<void> _calculateNavigationRoute(Refrigerateur refrigerateur) async {
    if (_userPosition == null) return;
    
    try {
      setState(() => _isCalculatingRoute = true);
      
      // Convertir le mode de transport pour l'API
      String routeProfile = 'foot-walking';
      switch (_transportMode) {
        case 'walking':
          routeProfile = 'foot-walking';
          break;
        case 'bike':
          routeProfile = 'cycling-regular';
          break;
        case 'car':
          routeProfile = 'driving-car';
          break;
        case 'motorcycle':
          routeProfile = 'driving-car'; // Même profil que voiture
          break;
      }
      
      final routePoints = await _mapService.calculateRoute(
        start: _userPosition!,
        end: LatLng(refrigerateur.latitude, refrigerateur.longitude),
        profile: routeProfile,
      );
      
      if (routePoints.isNotEmpty) {
        // Calculer la distance réelle de la route
        final routeDistance = MapService.calculateRouteDistance(routePoints);
        
        setState(() {
          _navigationRoute = routePoints;
          _routeDistance = routeDistance;
          _isCalculatingRoute = false;
        });
      }
    } catch (e) {
      print('❌ Erreur calcul route: $e');
      
      // Route de secours en ligne droite
      _setStraightLineRoute(refrigerateur);
      
      setState(() => _isCalculatingRoute = false);
    }
  }
  
  void _setStraightLineRoute(Refrigerateur refrigerateur) {
    if (_userPosition != null) {
      setState(() {
        _navigationRoute = [
          _userPosition!,
          LatLng(refrigerateur.latitude, refrigerateur.longitude)
        ];
        // Distance en ligne droite
        _routeDistance = MapService.calculateDistance(
          _userPosition!.latitude,
          _userPosition!.longitude,
          refrigerateur.latitude,
          refrigerateur.longitude,
        );
      });
    }
  }
  
  void _fitRouteInView() {
    if (_navigationRoute.isEmpty) return;
    
    final points = [..._navigationRoute];
    if (_userPosition != null && !points.contains(_userPosition!)) {
      points.add(_userPosition!);
    }
    
    final bounds = LatLngBounds.fromPoints(points);
    
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(100),
      ),
    );
  }
  
  void _clearNavigationRoute() {
    _markerAnimationTimer?.cancel();
    setState(() {
      _navigationRoute = [];
      _selectedRefrigerateur = null;
      _routeDistance = 0.0;
      _showMarkerAnimation = false;
      _markerAnimationRadius = 0.0;
      _showClearRouteButton = false; // Cacher le bouton de suppression
    });
  }
  
  void _centerOnUser() {
    if (_userPosition != null) {
      _mapController.move(_userPosition!, 15.0);
    }
  }
  
  void _showRefrigerateurDetails() {
    if (_selectedRefrigerateur == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RefrigerateurDetailScreen(
          refrigerateur: _selectedRefrigerateur!,
        ),
      ),
    ).then((_) {
      // NE PAS supprimer la route quand on revient des détails
      // La route reste affichée
    });
  }
  
  void _navigateToRefrigerateur() async {
    if (_selectedRefrigerateur == null || _userPosition == null) return;
    
    final lat = _selectedRefrigerateur!.latitude;
    final lng = _selectedRefrigerateur!.longitude;
    
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=${_userPosition!.latitude},${_userPosition!.longitude}'
      '&destination=$lat,$lng'
      '&travelmode=driving'
    );
    
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Erreur'),
          content: const Text('Impossible d\'ouvrir l\'application de navigation'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
  
  // Méthode pour changer le mode de transport
  void _changeTransportMode(String newMode) {
    setState(() {
      _transportMode = newMode;
    });

  }
  
  List<Refrigerateur> get _filteredRefrigerateurs {
    return _refrigerateurs.where((refrigerateur) {
      final showByStatut = _filters[refrigerateur.statut] ?? true;
      final showByPhotos = !_filters['Avec_photos']! || refrigerateur.aDesPhotos;
      return showByStatut && showByPhotos;
    }).toList();
  }
  
  String get _mapLayerUrl {
    switch (_selectedMapType) {
      case 0: return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
      case 1: return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case 2: return 'https://tile.opentopomap.org/{z}/{x}/{y}.png';
      case 3: return 'https://tile.openstreetmap.fr/hot/{z}/{x}/{y}.png';
      default: return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final filteredCount = _filteredRefrigerateurs.length;
    final totalCount = _refrigerateurs.length;
    
    return Scaffold(
      body: Stack(
        children: [
          // Carte principale
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _mapCenter,
              initialZoom: _mapZoom,
              minZoom: 3.0,
              maxZoom: 18.0,
              onMapEvent: (mapEvent) {
                if (mapEvent.source == MapEventSource.mapController) {
                  final camera = _mapController.camera;
                  setState(() {
                    _mapCenter = camera.center;
                    _mapZoom = camera.zoom;
                  });
                }
              },
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              // Couche de carte principale
              TileLayer(
                urlTemplate: _mapLayerUrl,
                userAgentPackageName: 'com.ucb.refrigerateur_app',
              ),
              
              // Route de navigation (toujours affichée si elle existe)
              if (_navigationRoute.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _navigationRoute,
                      color: AppTheme.primaryColor,
                      strokeWidth: 5,
                      borderColor: Colors.white,
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
              
              // Flèche de direction (optionnel)
              if (_navigationRoute.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _navigationRoute,
                      color: Colors.white.withOpacity(0.5),
                      strokeWidth: 2,
                      strokeCap: StrokeCap.round,
                    ),
                  ],
                ),
              
              // HALO ANIMÉ pour le marqueur sélectionné (si sélectionné)
              if (_selectedRefrigerateur != null && _showMarkerAnimation && _markerAnimationRadius > 0)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: LatLng(
                        _selectedRefrigerateur!.latitude,
                        _selectedRefrigerateur!.longitude,
                      ),
                      color: AppTheme.primaryColor.withOpacity(0.2),
                      borderColor: AppTheme.primaryColor.withOpacity(0.5),
                      borderStrokeWidth: 2,
                      radius: _markerAnimationRadius,
                      useRadiusInMeter: false,
                    ),
                  ],
                ),
              
              // MARQUEURS INDIVIDUELS (sans clustering)
              MarkerLayer(
                markers: _filteredRefrigerateurs.map((refrigerateur) {
                  final isSelected = _selectedRefrigerateur?.id == refrigerateur.id;
                  
                  return Marker(
                    point: LatLng(refrigerateur.latitude, refrigerateur.longitude),
                    width: isSelected ? 45 : 35, // Taille augmentée si sélectionné
                    height: isSelected ? 45 : 35,
                    child: GestureDetector(
                      onTap: () => _selectRefrigerateur(refrigerateur),
                      child: _buildRefrigerateurMarker(refrigerateur, isSelected),
                    ),
                  );
                }).toList(),
              ),
              
              // Position du technicien
              if (_userPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _userPosition!,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.fromBorderSide(
                            BorderSide(color: Colors.white, width: 3),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.person_pin_circle,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          
          // Overlay de chargement
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                      strokeWidth: 3,
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Chargement de la carte...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Indicateur de calcul de route
          if (_isCalculatingRoute)
            Positioned(
              top: MediaQuery.of(context).padding.top + 100,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Calcul de l\'itinéraire...',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          
          // AppBar personnalisé
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: _buildAppBar(),
          ),
          
          // Contrôles de la carte
          Positioned(
            right: 16,
            bottom: 120,
            child: _buildMapControls(),
          ),
          
          // Détails du réfrigérateur sélectionné (seulement si sélectionné ET si on n'a pas cliqué sur la croix)
          if (_selectedRefrigerateur != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: _buildSelectedRefrigerateurCard(),
            ),
          
          // Statistiques
          Positioned(
            top: MediaQuery.of(context).padding.top + 90,
            left: 16,
            child: _buildStatsCard(),
          ),
          
          // Bouton de type de carte
          Positioned(
            top: MediaQuery.of(context).padding.top + 90,
            right: 16,
            child: GestureDetector(
              onTap: _changeMapType,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.map, size: 14, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text(
                      _mapTypes[_selectedMapType],
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Indicateur de filtre
          if (filteredCount != totalCount)
            Positioned(
              top: MediaQuery.of(context).padding.top + 140,
              right: 16,
              child: _buildFilterIndicator(filteredCount, totalCount),
            ),
          

        ],
      ),
    );
  }
  
  Widget _buildClearRouteButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(
          Icons.clear,
          color: Colors.red,
          size: 28,
        ),
        onPressed: _clearNavigationRoute,
        tooltip: 'Effacer l\'itinéraire',
      ),
    );
  }
  
  Widget _buildRefrigerateurMarker(Refrigerateur refrigerateur, bool isSelected) {
    Color markerColor;
    
    switch (refrigerateur.statut) {
      case 'Fonctionnel':
        markerColor = Colors.green;
        break;
      case 'En_panne':
        markerColor = Colors.red;
        break;
      case 'Maintenance':
        markerColor = Colors.orange;
        break;
      default:
        markerColor = Colors.grey;
    }
    
    return Container(
      decoration: BoxDecoration(
        color: markerColor,
        borderRadius: BorderRadius.circular(isSelected ? 30 : 25),
        border: Border.all(
          color: isSelected ? Colors.white : Colors.white,
          width: isSelected ? 4 : 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isSelected ? 0.5 : 0.3),
            blurRadius: isSelected ? 12 : 8,
            spreadRadius: isSelected ? 1 : 0,
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.kitchen,
          color: Colors.white,
          size: isSelected ? 24 : 20,
        ),
      ),
    );
  }
  
  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
            color: AppTheme.primaryColor,
          ),
          
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.greyLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Rechercher un réfrigérateur...',
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search, size: 20),
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          
          IconButton(
            icon: const Icon(Icons.filter_list, color: AppTheme.primaryColor),
            onPressed: () => _showFilterDialog(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMapControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildControlButton(
          icon: Icons.add,
          onPressed: () {
            final camera = _mapController.camera;
            if (camera.zoom < 18.0) {
              _mapController.move(camera.center, camera.zoom + 1);
            }
          },
        ),
        
        _buildControlButton(
          icon: Icons.remove,
          onPressed: () {
            final camera = _mapController.camera;
            if (camera.zoom > 3.0) {
              _mapController.move(camera.center, camera.zoom - 1);
            }
          },
        ),
        
        const SizedBox(height: 8),
        
        _buildControlButton(
          icon: Icons.my_location,
          onPressed: _centerOnUser,
          tooltip: 'Centrer sur ma position',
        ),
        
        // Bouton pour ajuster la vue sur la route
        if (_navigationRoute.isNotEmpty)
          _buildControlButton(
            icon: Icons.route,
            onPressed: _fitRouteInView,
            color: AppTheme.primaryColor,
            tooltip: 'Ajuster la vue sur l\'itinéraire',
          ),

                    // BOUTON FLOATING POUR SUPPRIMER LA ROUTE (affiché seulement si une route existe)
        if (_showClearRouteButton && _navigationRoute.isNotEmpty)
            Positioned(
              right: 16,
              bottom: MediaQuery.of(context).size.height / 2 - 25, // Centre vertical
              child: _buildClearRouteButton(),
            ),
      ],
    );
  }
  
  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color? color,
    String? tooltip,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: color ?? AppTheme.primaryColor),
        onPressed: onPressed,
        iconSize: 20,
        tooltip: tooltip,
      ),
    );
  }
  
  Widget _buildStatsCard() {
    final fonctionnels = _refrigerateurs.where((r) => r.statut == 'Fonctionnel').length;
    final enPanne = _refrigerateurs.where((r) => r.statut == 'En_panne').length;
    final maintenance = _refrigerateurs.where((r) => r.statut == 'Maintenance').length;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 Statistiques',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          Text(
            '${_refrigerateurs.length} réfrigérateurs',
            style: const TextStyle(fontSize: 11),
          ),
          
          if (_refrigerateurs.isNotEmpty)
            Column(
              children: [
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    _buildStatChip('✅', fonctionnels, Colors.green),
                    _buildStatChip('🔴', enPanne, Colors.red),
                    _buildStatChip('🟡', maintenance, Colors.orange),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }
  
  Widget _buildStatChip(String icon, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 10)),
          const SizedBox(width: 2),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilterIndicator(int filteredCount, int totalCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_alt, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            '$filteredCount/$totalCount',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
  
Widget _buildSelectedRefrigerateurCard() {
  if (_selectedRefrigerateur == null) return const SizedBox();
  
  final refrigerateur = _selectedRefrigerateur!;
  final client = HiveService.getClientById(refrigerateur.clientId);
  
  return RouteInfoCard(
    refrigerateur: refrigerateur,
    client: client,
    routeDistanceKm: _routeDistance, // Distance réelle de la route
    transportMode: _transportMode, // Mode de transport actuel
    isCalculatingDistance: _isCalculatingRoute, // NOUVEAU: état de calcul
    onNavigate: _navigateToRefrigerateur,
    onShowDetails: _showRefrigerateurDetails,
    onClose: () {
      // Quand on ferme la carte, on ne supprime pas la route
      // On garde seulement la route et le bouton flottant
      setState(() {
        _selectedRefrigerateur = null;
        _showMarkerAnimation = false;
        _markerAnimationRadius = 0.0;
        _markerAnimationTimer?.cancel();
      });
    },
    onTransportModeChanged: _changeTransportMode, // Callback pour changer le mode
  );
}
  
  void _changeMapType() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Type de carte'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _mapTypes.asMap().entries.map((entry) {
              return RadioListTile<int>(
                title: Text(entry.value),
                value: entry.key,
                groupValue: _selectedMapType,
                onChanged: (value) {
                  setState(() => _selectedMapType = value!);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
  
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrer'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CheckboxListTile(
                title: const Text('Fonctionnel'),
                value: _filters['Fonctionnel'],
                onChanged: (value) => setState(() => _filters['Fonctionnel'] = value ?? false),
                secondary: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              CheckboxListTile(
                title: const Text('En panne'),
                value: _filters['En_panne'],
                onChanged: (value) => setState(() => _filters['En_panne'] = value ?? false),
                secondary: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              CheckboxListTile(
                title: const Text('Maintenance'),
                value: _filters['Maintenance'],
                onChanged: (value) => setState(() => _filters['Maintenance'] = value ?? false),
                secondary: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}