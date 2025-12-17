import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:ucb_app/constants/app_theme.dart';
import 'package:ucb_app/models/intervention.dart';
import 'package:ucb_app/models/refrigerateur.dart';
import 'package:ucb_app/models/client.dart';
import 'package:ucb_app/pages/dashboard/maps/intervention_detail_screen.dart';
import 'package:ucb_app/pages/dashboard/maps/refrigerateur_detail_screen.dart';
import 'package:ucb_app/pages/dashboard/maps/widgets/route_info_card.dart';
import 'package:ucb_app/services/hive_service.dart';
import 'package:ucb_app/services/map_service.dart';
import 'package:url_launcher/url_launcher.dart';

class InterventionMapScreen extends StatefulWidget {
  final Intervention intervention;
  
  const InterventionMapScreen({
    super.key,
    required this.intervention,
  });
  
  @override
  State<InterventionMapScreen> createState() => _InterventionMapScreenState();
}

class _InterventionMapScreenState extends State<InterventionMapScreen> {
  // Services
  final MapService _mapService = MapService();
  
  // Données
  LatLng? _userPosition;
  List<Refrigerateur> _refrigerateurs = [];
  List<Client> _clients = [];
  Refrigerateur? _selectedRefrigerateur;
  Client? _selectedClient;
  
  // État UI
  bool _isLoading = true;
  double _mapZoom = 15.0;
  LatLng _mapCenter = const LatLng(4.0511, 9.7679);
  
  // Route entre technicien et réfrigérateur
  List<LatLng> _navigationRoute = [];
  double _routeDistance = 0.0;
  bool _isCalculatingRoute = false;
  String _transportMode = 'walking';
  Timer? _markerAnimationTimer;
  double _markerAnimationRadius = 0.0;
  bool _showMarkerAnimation = false;
  
  // État pour le bouton de suppression de route
  bool _showClearRouteButton = false;
  
  // Contrôleurs
  final MapController _mapController = MapController();
  
  @override
  void initState() {
    super.initState();
    _initializeMap();
  }
  
  @override
  void dispose() {
    _mapService.dispose();
    _mapController.dispose();
    _markerAnimationTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    setState(() => _isLoading = true);
    
    try {
      await _mapService.initialize();
      
      // 1. Obtenir position du technicien
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
      
      // 2. Charger les réfrigérateurs concernés par l'intervention
      _loadRefrigerateursIntervention();
      
      // 3. Charger les clients concernés
      _loadClientsIntervention();
      
      // 4. Ajuster le centre de la carte
      _adjustMapCenter();
      
    } catch (e) {
      print('❌ Erreur initialisation carte: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  void _loadRefrigerateursIntervention() {
    final refrigerateurIds = widget.intervention.refrigerateurIds;
    final tousRefrigerateurs = HiveService.getAllRefrigerateurs();
    
    setState(() {
      _refrigerateurs = tousRefrigerateurs
          .where((r) => refrigerateurIds.contains(r.id))
          .toList();
    });
    
    print('🧊 Réfrigérateurs de l\'intervention: ${_refrigerateurs.length}');
  }
  
  void _loadClientsIntervention() {
    final clientIds = <String>{};
    
    for (final refrigerateur in _refrigerateurs) {
      clientIds.add(refrigerateur.clientId);
    }
    
    final tousClients = HiveService.getAllClients();
    
    setState(() {
      _clients = tousClients
          .where((c) => clientIds.contains(c.id))
          .toList();
    });
    
    print('👥 Clients de l\'intervention: ${_clients.length}');
    
    // TRACER LA ROUTE PAR DÉFAUT DU TECHNICIEN AU CLIENT
    if (_clients.isNotEmpty && _userPosition != null) {
      // Sélectionner automatiquement le premier client
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _selectClient(_clients.first);
        }
      });
    }
  }
  
  void _adjustMapCenter() {
    if (_refrigerateurs.isEmpty && _clients.isEmpty) {
      return; // Garder le centre par défaut
    }
    
    // Créer une liste de tous les points à afficher
    final List<LatLng> allPoints = [];
    
    // Ajouter la position du technicien
    if (_userPosition != null) {
      allPoints.add(_userPosition!);
    }
    
    // Ajouter les positions des réfrigérateurs
    for (final refrigerateur in _refrigerateurs) {
      allPoints.add(LatLng(refrigerateur.latitude, refrigerateur.longitude));
    }
    
    // Ajouter les positions des clients (s'ils sont différents des réfrigérateurs)
    for (final client in _clients) {
      allPoints.add(LatLng(client.latitude, client.longitude));
    }
    
    if (allPoints.isEmpty) return;
    
    // Calculer le point médian
    final latitudes = allPoints.map((p) => p.latitude).toList();
    final longitudes = allPoints.map((p) => p.longitude).toList();
    
    final avgLat = latitudes.reduce((a, b) => a + b) / latitudes.length;
    final avgLng = longitudes.reduce((a, b) => a + b) / longitudes.length;
    
    setState(() {
      _mapCenter = LatLng(avgLat, avgLng);
      _mapZoom = allPoints.length > 1 ? 14.0 : 16.0; // Plus de zoom si un seul point
    });
    
    // Centrer la carte sur la vue d'ensemble
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (allPoints.length > 1) {
        _fitAllInView(allPoints);
      } else {
        _mapController.move(_mapCenter, _mapZoom);
      }
    });
  }
  
  void _fitAllInView(List<LatLng> points) {
    if (points.length < 2) return;
    
    final bounds = LatLngBounds.fromPoints(points);
    
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(80),
      ),
    );
  }
  
  void _selectRefrigerateur(Refrigerateur refrigerateur) {
    // Arrêter l'animation précédente
    _markerAnimationTimer?.cancel();
    
    setState(() {
      _selectedRefrigerateur = refrigerateur;
      _selectedClient = null;
      _navigationRoute = [];
      _routeDistance = 0.0;
      _isCalculatingRoute = true;
      _showMarkerAnimation = true;
      _markerAnimationRadius = 0.0;
      _showClearRouteButton = true;
    });
    
    // Démarrer l'animation
    _startMarkerAnimation();
    
    if (_userPosition != null) {
      _calculateNavigationRoute(refrigerateur);
    }
  }
  
  void _selectClient(Client client) {
    // Arrêter l'animation précédente
    _markerAnimationTimer?.cancel();
    
    setState(() {
      _selectedClient = client;
      _selectedRefrigerateur = null;
      _navigationRoute = [];
      _routeDistance = 0.0;
      _isCalculatingRoute = true;
      _showMarkerAnimation = true;
      _markerAnimationRadius = 0.0;
      _showClearRouteButton = true;
    });
    
    // Démarrer l'animation (centrée sur le client)
    _startMarkerAnimation();
    
    if (_userPosition != null) {
      // Calculer la route vers le client
      _calculateRouteToClient(client);
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
      
      final routePoints = await _mapService.calculateRoute(
        start: _userPosition!,
        end: LatLng(refrigerateur.latitude, refrigerateur.longitude),
        profile: _getRouteProfile(),
      );
      
      if (routePoints.isNotEmpty) {
        final routeDistance = MapService.calculateRouteDistance(routePoints);
        
        setState(() {
          _navigationRoute = routePoints;
          _routeDistance = routeDistance;
          _isCalculatingRoute = false;
        });
      }
    } catch (e) {
      print('❌ Erreur calcul route: $e');
      _setStraightLineRouteToRefrigerateur(refrigerateur);
      setState(() => _isCalculatingRoute = false);
    }
  }
  
  Future<void> _calculateRouteToClient(Client client) async {
    if (_userPosition == null) return;
    
    try {
      setState(() => _isCalculatingRoute = true);
      
      final routePoints = await _mapService.calculateRoute(
        start: _userPosition!,
        end: LatLng(client.latitude, client.longitude),
        profile: _getRouteProfile(),
      );
      
      if (routePoints.isNotEmpty) {
        final routeDistance = MapService.calculateRouteDistance(routePoints);
        
        setState(() {
          _navigationRoute = routePoints;
          _routeDistance = routeDistance;
          _isCalculatingRoute = false;
        });
      }
    } catch (e) {
      print('❌ Erreur calcul route vers client: $e');
      _setStraightLineRouteToClient(client);
      setState(() => _isCalculatingRoute = false);
    }
  }
  
  String _getRouteProfile() {
    switch (_transportMode) {
      case 'walking': return 'foot-walking';
      case 'bike': return 'cycling-regular';
      case 'car': return 'driving-car';
      case 'motorcycle': return 'driving-car';
      default: return 'foot-walking';
    }
  }
  
  void _setStraightLineRouteToRefrigerateur(Refrigerateur refrigerateur) {
    if (_userPosition != null) {
      setState(() {
        _navigationRoute = [
          _userPosition!,
          LatLng(refrigerateur.latitude, refrigerateur.longitude)
        ];
        _routeDistance = MapService.calculateDistance(
          _userPosition!.latitude,
          _userPosition!.longitude,
          refrigerateur.latitude,
          refrigerateur.longitude,
        );
      });
    }
  }
  
  void _setStraightLineRouteToClient(Client client) {
    if (_userPosition != null) {
      setState(() {
        _navigationRoute = [
          _userPosition!,
          LatLng(client.latitude, client.longitude)
        ];
        _routeDistance = MapService.calculateDistance(
          _userPosition!.latitude,
          _userPosition!.longitude,
          client.latitude,
          client.longitude,
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
      _selectedClient = null;
      _routeDistance = 0.0;
      _showMarkerAnimation = false;
      _markerAnimationRadius = 0.0;
      _showClearRouteButton = false;
    });
  }
  
  void _centerOnUser() {
    if (_userPosition != null) {
      _mapController.move(_userPosition!, 15.0);
    }
  }
  
  void _navigateToDestination() async {
    LatLng? destination;
    String? destinationName;
    
    if (_selectedRefrigerateur != null) {
      destination = LatLng(_selectedRefrigerateur!.latitude, _selectedRefrigerateur!.longitude);
      destinationName = _selectedRefrigerateur!.codeQR;
    } else if (_selectedClient != null) {
      destination = LatLng(_selectedClient!.latitude, _selectedClient!.longitude);
      destinationName = _selectedClient!.nom;
    }
    
    if (destination == null || _userPosition == null || destinationName == null) return;
    
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=${_userPosition!.latitude},${_userPosition!.longitude}'
      '&destination=${destination.latitude},${destination.longitude}'
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
  
  void _changeTransportMode(String newMode) {
    setState(() {
      _transportMode = newMode;
    });
    
  }
  
  Color _getRefrigerateurMarkerColor(Refrigerateur refrigerateur) {
    switch (refrigerateur.statut) {
      case 'Fonctionnel': return Colors.green;
      case 'En_panne': return Colors.red;
      case 'Maintenance': return Colors.orange;
      default: return Colors.grey;
    }
  }
  
  @override
  Widget build(BuildContext context) {
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
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.ucb.refrigerateur_app',
              ),
              
              // Route de navigation (AFFICHÉE PAR DÉFAUT SI LE CLIENT EST SÉLECTIONNÉ)
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
              
              // HALO ANIMÉ pour le marqueur sélectionné
              if ((_selectedRefrigerateur != null || _selectedClient != null) 
                  && _showMarkerAnimation && _markerAnimationRadius > 0)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: _selectedRefrigerateur != null
                          ? LatLng(_selectedRefrigerateur!.latitude, _selectedRefrigerateur!.longitude)
                          : LatLng(_selectedClient!.latitude, _selectedClient!.longitude),
                      color: Colors.blue.withOpacity(0.2),
                      borderColor: Colors.blue.withOpacity(0.5),
                      borderStrokeWidth: 2,
                      radius: _markerAnimationRadius,
                      useRadiusInMeter: false,
                    ),
                  ],
                ),
              
              // MARQUEURS DES CLIENTS (en violet)
              MarkerLayer(
                markers: _clients.map((client) {
                  final isSelected = _selectedClient?.id == client.id;
                  
                  return Marker(
                    point: LatLng(client.latitude, client.longitude),
                    width: isSelected ? 50 : 40,
                    height: isSelected ? 50 : 40,
                    child: GestureDetector(
                      onTap: () => _selectClient(client),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.purple,
                          borderRadius: BorderRadius.circular(isSelected ? 25 : 20),
                          border: Border.all(
                            color: Colors.white,
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
                            Icons.business,
                            color: Colors.white,
                            size: isSelected ? 24 : 20,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              
              // MARQUEURS DES RÉFRIGÉRATEURS (selon statut)
              MarkerLayer(
                markers: _refrigerateurs.map((refrigerateur) {
                  final isSelected = _selectedRefrigerateur?.id == refrigerateur.id;
                  
                  return Marker(
                    point: LatLng(refrigerateur.latitude, refrigerateur.longitude),
                    width: isSelected ? 45 : 35,
                    height: isSelected ? 45 : 35,
                    child: GestureDetector(
                      onTap: () => _selectRefrigerateur(refrigerateur),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _getRefrigerateurMarkerColor(refrigerateur),
                          borderRadius: BorderRadius.circular(isSelected ? 30 : 25),
                          border: Border.all(
                            color: Colors.white,
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
                      ),
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
          
          // Carte de destination sélectionnée
          if (_selectedRefrigerateur != null || _selectedClient != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: _buildSelectedDestinationCard(),
            ),
          
          // Statistiques de l'intervention
          Positioned(
            top: MediaQuery.of(context).padding.top + 90,
            left: 16,
            child: _buildInterventionStatsCard(),
          ),
          
          
        ],
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.intervention.code,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  widget.intervention.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
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

          // Bouton pour supprimer la route
          if (_showClearRouteButton && _navigationRoute.isNotEmpty)
            Positioned(
              right: 16,
              bottom: MediaQuery.of(context).size.height / 2 - 25,
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
  
  Widget _buildInterventionStatsCard() {
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
          Text(
            '📍 ${widget.intervention.code}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          Text(
            '${_refrigerateurs.length} réfrigérateurs',
            style: const TextStyle(fontSize: 11),
          ),
          Text(
            '${_clients.length} clients',
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
  
  Widget _buildSelectedDestinationCard() {
    if (_selectedRefrigerateur != null) {
      final refrigerateur = _selectedRefrigerateur!;
      final client = HiveService.getClientById(refrigerateur.clientId);
      
      return RouteInfoCard(
        refrigerateur: refrigerateur,
        client: client,
        routeDistanceKm: _routeDistance,
        transportMode: _transportMode,
        isCalculatingDistance: _isCalculatingRoute,
        onNavigate: _navigateToDestination,
        onShowDetails: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RefrigerateurDetailScreen(
                refrigerateur: _selectedRefrigerateur!,
              ),
            ),
          );
        },
        onClose: () {
          setState(() {
            _selectedRefrigerateur = null;
            _showMarkerAnimation = false;
            _markerAnimationRadius = 0.0;
            _markerAnimationTimer?.cancel();
          });
        },
        onTransportModeChanged: _changeTransportMode,
      );
    } else if (_selectedClient != null) {
      final client = _selectedClient!;
      
      return RouteInfoCard(
        client: client,
        routeDistanceKm: _routeDistance,
        transportMode: _transportMode,
        isCalculatingDistance: _isCalculatingRoute,
        onNavigate: _navigateToDestination,
        onShowDetails: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InterventionDetailScreen(
                intervention: widget.intervention,
              ),
            ),
          );
        },
        onClose: () {
          setState(() {
            _selectedClient = null;
            _showMarkerAnimation = false;
            _markerAnimationRadius = 0.0;
            _markerAnimationTimer?.cancel();
          });
        },
        onTransportModeChanged: _changeTransportMode,
      );
    }
    
    return const SizedBox();
  }
  
  IconData _getTransportIcon() {
    switch (_transportMode) {
      case 'walking': return Icons.directions_walk;
      case 'car': return Icons.directions_car;
      case 'motorcycle': return Icons.motorcycle;
      default: return Icons.directions;
    }
  }
  
  Widget _buildTransportSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mode de transport:',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textLight,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildTransportChip('walking', 'À pied'),
            _buildTransportChip('car', 'Voiture'),
            _buildTransportChip('motorcycle', 'Moto'),
          ],
        ),
      ],
    );
  }
  
  Widget _buildTransportChip(String mode, String label) {
    final isSelected = _transportMode == mode;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          _changeTransportMode(mode);
        }
      },
      selectedColor: AppTheme.primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
      ),
    );
  }
}