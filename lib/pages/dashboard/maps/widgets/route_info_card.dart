import 'package:flutter/material.dart';
import 'package:ucb_app/constants/app_theme.dart';
import 'package:ucb_app/models/refrigerateur.dart';
import 'package:ucb_app/models/client.dart';
import 'package:ucb_app/services/map_service.dart';

class RouteInfoCard extends StatelessWidget {
  final Refrigerateur? refrigerateur;
  final Client? client;
  final double routeDistanceKm;
  final VoidCallback onNavigate;
  final VoidCallback onShowDetails;
  final VoidCallback onClose;
  final String transportMode;
  final Function(String)? onTransportModeChanged;
  final bool isCalculatingDistance;
  
  const RouteInfoCard({
    super.key,
    this.refrigerateur,
    this.client,
    required this.routeDistanceKm,
    required this.onNavigate,
    required this.onShowDetails,
    required this.onClose,
    this.transportMode = 'walking',
    this.onTransportModeChanged,
    this.isCalculatingDistance = false,
  });
  
  @override
  Widget build(BuildContext context) {
    // Calcul du temps en fonction du mode de transport
    final estimatedTime = MapService.calculateEstimatedTime(
      routeDistanceKm,
      transportMode: transportMode,
    );
    
    // Vitesse moyenne selon le mode de transport
    String getSpeedInfo() {
      switch (transportMode) {
        case 'walking': return '5 km/h (à pied)';
        case 'car': return '40 km/h (voiture)';
        case 'motorcycle': return '50 km/h (moto)';
        default: return '40 km/h (voiture)';
      }
    }
    
    // Déterminer si c'est un réfrigérateur ou un client
    final bool isRefrigerateur = refrigerateur != null;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isRefrigerateur)
                      _buildRefrigerateurHeader()
                    else
                      _buildClientHeader(),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: onClose,
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Informations de distance et temps
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.greyLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                // Distance et temps estimé
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Colonne Destination
                    Column(
                      children: [
                        Icon(
                          isRefrigerateur ? Icons.kitchen : Icons.business,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isRefrigerateur ? 'type' : 'Secteur',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppTheme.textLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isRefrigerateur 
                            ? refrigerateur!.type
                            : client!.type,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    
                    // Colonne Distance route
                    Column(
                      children: [
                        const Icon(Icons.alt_route, color: AppTheme.primaryColor, size: 20),
                        const SizedBox(height: 4),
                        const Text(
                          'Distance route',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.textLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        if (isCalculatingDistance)
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                              ),
                            ),
                          )
                        else
                          Text(
                            '${routeDistanceKm.toStringAsFixed(2)} km',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                    
                    // Colonne Temps estimé
                    Column(
                      children: [
                        const Icon(Icons.timer, color: AppTheme.primaryColor, size: 20),
                        const SizedBox(height: 4),
                        const Text(
                          'Temps estimé',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.textLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isCalculatingDistance ? '...' : '$estimatedTime min',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Mode de transport et vitesse
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getTransportIcon(),
                      size: 14,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Vitesse: ${getSpeedInfo()}',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.textLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Sélecteur de mode de transport (si callback fourni)
          if (onTransportModeChanged != null) 
            _buildTransportSelector(),
          
          const SizedBox(height: 12),
          
          // Boutons d'action (SEULEMENT LE BOUTON "DÉTAILS")
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onShowDetails,
                  icon: const Icon(Icons.info_outline, size: 20),
                  label: const Text('Détails'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildRefrigerateurHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          refrigerateur!.codeQR,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        if (client != null)
          Text(
            client!.nom,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textLight,
            ),
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }
  
  Widget _buildClientHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          client!.nom,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          client!.adresse,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textLight,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        ),
      ],
    );
  }
  
  Color _getStatusColor(String statut) {
    switch (statut) {
      case 'Fonctionnel': return Colors.green;
      case 'En_panne': return Colors.red;
      case 'Maintenance': return Colors.orange;
      default: return Colors.grey;
    }
  }
  
  String _getStatusText(String statut) {
    switch (statut) {
      case 'Fonctionnel': return '✅ Fonctionnel';
      case 'En_panne': return '🔴 En panne';
      case 'Maintenance': return '🟡 Maintenance';
      default: return statut;
    }
  }
  
  IconData _getTransportIcon() {
    switch (transportMode) {
      case 'walking': return Icons.directions_walk;
      case 'bike': return Icons.directions_bike;
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
    final isSelected = transportMode == mode;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected && onTransportModeChanged != null) {
          onTransportModeChanged!(mode);
        }
      },
      selectedColor: AppTheme.primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
      ),
    );
  }
}