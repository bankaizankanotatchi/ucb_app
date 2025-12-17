import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:ucb_app/constants/app_theme.dart';
import 'package:ucb_app/models/refrigerateur.dart';
import 'package:ucb_app/pages/dashboard/maps/widgets/refrigerateur_marker.dart';

class MapWidget extends StatefulWidget {
  final MapController mapController;
  final LatLng? userPosition;
  final List<Refrigerateur> refrigerateurs;
  final List<Refrigerateur> selectedRoute;
  final Refrigerateur? selectedRefrigerateur;
  final Function(Refrigerateur) onRefrigerateurSelected;
  final Function(LatLng, double) onMapMoved;
  
  const MapWidget({
    super.key,
    required this.mapController,
    this.userPosition,
    required this.refrigerateurs,
    required this.selectedRoute,
    this.selectedRefrigerateur,
    required this.onRefrigerateurSelected,
    required this.onMapMoved,
  });
  
  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: widget.mapController,
      options: MapOptions(
        initialCenter: widget.userPosition ?? const LatLng(4.0511, 9.7679),
        initialZoom: 13.0,
        maxZoom: 18.0,
        minZoom: 10.0,
        interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all,
          ),

        onPositionChanged: (position, hasGesture) {
          if (hasGesture) {
            widget.onMapMoved(position.center!, position.zoom!);
          }
        },
      ),

      
      children: [
        // Tuiles OpenStreetMap
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.ucb_app',
          tileProvider: NetworkTileProvider(),
          // Fallback pour hors-ligne
          fallbackUrl: 'https://tiles.stadiamaps.com/tiles/alidade_smooth/{z}/{x}/{y}{r}.png',
        ),

      RichAttributionWidget(
        attributions: const [
          TextSourceAttribution('OpenStreetMap contributors'),
        ],
      ),
        
        // Marqueur utilisateur
        if (widget.userPosition != null)
          MarkerLayer(
            markers: [
              Marker(
                point: widget.userPosition!,
                width: 40,
                height: 40,
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person_pin_circle,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ],
          ),
        
        // Cluster de marqueurs pour les réfrigérateurs
        MarkerClusterLayerWidget(
          options: MarkerClusterLayerOptions(
            maxClusterRadius: 120,
            size: const Size(40, 40),
            markers: widget.refrigerateurs.map((refrigerateur) {
              return Marker(
                point: LatLng(refrigerateur.latitude, refrigerateur.longitude),
                width: 35,
                height: 35,
                child: RefrigerateurMarker(
                  refrigerateur: refrigerateur,
                  isSelected: widget.selectedRefrigerateur?.id == refrigerateur.id,
                  onTap: () => widget.onRefrigerateurSelected(refrigerateur),
                ),
              );
            }).toList(),
            polygonOptions: const PolygonOptions(
              borderColor: AppTheme.primaryColor,
              color: Colors.black12,
              borderStrokeWidth: 3,
            ),
            builder: (context, markers) {
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: AppTheme.primaryColor,
                ),
                child: Center(
                  child: Text(
                    markers.length.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        
        // Itinéraire sélectionné
        if (widget.selectedRoute.isNotEmpty)
          PolylineLayer(
            polylines: [
              for (int i = 0; i < widget.selectedRoute.length - 1; i++)
                Polyline(
                  points: [
                    LatLng(
                      widget.selectedRoute[i].latitude,
                      widget.selectedRoute[i].longitude,
                    ),
                    LatLng(
                      widget.selectedRoute[i + 1].latitude,
                      widget.selectedRoute[i + 1].longitude,
                    ),
                  ],
                  color: AppTheme.primaryColor.withOpacity(0.7),
                  strokeWidth: 3,
                  borderStrokeWidth: 1,
                  borderColor: Colors.white,
                ),
            ],
          ),
        
        // Ligne vers le réfrigérateur sélectionné
        if (widget.selectedRefrigerateur != null && widget.userPosition != null)
          PolylineLayer(
            polylines: [
              Polyline(
                points: [
                  widget.userPosition!,
                  LatLng(
                    widget.selectedRefrigerateur!.latitude,
                    widget.selectedRefrigerateur!.longitude,
                  ),
                ],
                color: Colors.red.withOpacity(0.7),
                strokeWidth: 2,
                borderStrokeWidth: 1,
                borderColor: Colors.white,
                strokeCap: StrokeCap.round,
                pattern: StrokePattern.dotted()

              ),
            ],
          ),
      ],
    );
  }
}