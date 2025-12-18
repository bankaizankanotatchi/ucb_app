import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ucb_app/constants/app_theme.dart';
import 'package:ucb_app/models/intervention.dart';
import 'package:ucb_app/models/refrigerateur.dart';
import 'package:ucb_app/models/client.dart';
import 'package:ucb_app/models/rapport_intervention.dart';
import 'package:ucb_app/models/checklist.dart';
import 'package:ucb_app/pages/dashboard/maps/qr_scan_frigo_screen.dart';
import 'package:ucb_app/pages/dashboard/maps/refrigerateur_detail_screen.dart';
import 'package:ucb_app/services/hive_service.dart';

class InterventionDetailScreen extends StatefulWidget {
  final Intervention intervention;
  
  const InterventionDetailScreen({
    super.key,
    required this.intervention,
  });
  
  @override
  State<InterventionDetailScreen> createState() => _InterventionDetailScreenState();
}

class _InterventionDetailScreenState extends State<InterventionDetailScreen> {
  late Intervention _intervention;
  List<Refrigerateur> _refrigerateurs = [];
  List<Client> _clients = [];
  RapportIntervention? _rapport;
  Checklist? _checklist;
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  
  @override
  void initState() {
    super.initState();
    _intervention = widget.intervention;
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Recharger l'intervention depuis Hive
      final updatedIntervention = HiveService.getInterventionById(_intervention.id);
      if (updatedIntervention != null) {
        _intervention = updatedIntervention;
      }
      // Charger les réfrigérateurs
      final refrigerateurIds = _intervention.refrigerateurIds;
      final tousRefrigerateurs = HiveService.getAllRefrigerateurs();
      _refrigerateurs = tousRefrigerateurs
          .where((r) => refrigerateurIds.contains(r.id))
          .toList();
      
      // Charger les clients
      final clientIds = _refrigerateurs.map((r) => r.clientId).toSet();
      final tousClients = HiveService.getAllClients();
      _clients = tousClients
          .where((c) => clientIds.contains(c.id))
          .toList();
      
      // Charger le rapport
      _rapport = HiveService.getRapportByIntervention(_intervention.id);
      
      // Charger la checklist
      _checklist = HiveService.getChecklistByIntervention(_intervention.id);
      
    } catch (e) {
      print('❌ Erreur chargement données: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Planifiee': return Colors.blue;
      case 'En_cours': return Colors.orange;
      case 'Terminee': return Colors.green;
      case 'Urgent': return Colors.red;
      default: return Colors.grey;
    }
  }
  
  String _getStatusText(String status) {
    switch (status) {
      case 'Planifiee': return 'Planifiée';
      case 'En_cours': return 'En cours';
      case 'Terminee': return 'Terminée';
      case 'Urgent': return 'Urgente';
      default: return status;
    }
  }
  
  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Planifiee': return Icons.schedule;
      case 'En_cours': return Icons.play_arrow;
      case 'Terminee': return Icons.check_circle;
      case 'Urgent': return Icons.warning;
      default: return Icons.help;
    }
  }
  
  Widget _buildStatusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getStatusIcon(status), size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            _getStatusText(status),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _updateInterventionStatus(String newStatus) async {
    try {
      HiveService.updateInterventionStatus(_intervention.id, newStatus);
      setState(() {
        _intervention.statut = newStatus;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Statut mis à jour: ${_getStatusText(newStatus)}'),
          backgroundColor: _getStatusColor(newStatus),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de la mise à jour'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _showStatusUpdateDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Mettre à jour le statut',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ...['Planifiee', 'En_cours', 'Terminee'].map((status) {
                return ListTile(
                  leading: Icon(_getStatusIcon(status), color: _getStatusColor(status)),
                  title: Text(_getStatusText(status)),
                  trailing: _intervention.statut == status 
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    _updateInterventionStatus(status);
                  },
                );
              }),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // ==================== MÉTHODES POUR LES PHOTOS CLIENT ====================

  /// Obtenir le premier client (ou celui dont on veut afficher les photos)
  Client? _getFirstClient() {
    return _clients.isNotEmpty ? _clients.first : null;
  }

  /// Obtenir la dernière photo du client
  String? _getLastClientPhoto() {
    final client = _getFirstClient();
    if (client == null || client.photos.isEmpty) return null;
    return client.photos.last;
  }

  /// Ajouter une photo au client
  Future<void> _addPhotoToClient() async {
    final client = _getFirstClient();
    if (client == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucun client trouvé'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Prendre une photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choisir depuis la galerie'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final XFile? pickedFile = await _imagePicker.pickImage(source: source);
      if (pickedFile != null) {
        final imagePath = pickedFile.path;
        
        final success = await HiveService.addPhotoToClient(
          clientId: client.id,
          cheminPhoto: imagePath,
        );

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo ajoutée avec succès'),
              backgroundColor: Colors.green,
            ),
          );
          // Recharger les données
          _loadData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de l\'ajout de la photo'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Afficher toutes les photos du client
  void _showClientPhotos() {
    final client = _getFirstClient();
    if (client == null || client.photos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucune photo disponible'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Photos du client',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${client.photos.length} photo(s)',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: GridView.builder(
                      controller: scrollController,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: client.photos.length,
                      itemBuilder: (context, index) {
                        final photoPath = client.photos[index];
                        return GestureDetector(
                          onTap: () => _showFullScreenImage(photoPath),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              File(photoPath),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[200],
                                  child: const Icon(
                                    Icons.photo,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _addPhotoToClient();
                    },
                    icon: const Icon(Icons.add_a_photo),
                    label: const Text('Ajouter une photo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Afficher une photo en plein écran
  void _showFullScreenImage(String imagePath) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    color: Colors.black87,
                    child: Center(
                      child: InteractiveViewer(
                        maxScale: 5.0,
                        child: Image.file(
                          File(imagePath),
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[800],
                              child: const Center(
                                child: Icon(
                                  Icons.photo,
                                  color: Colors.grey,
                                  size: 50,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Positioned(
                bottom: 40,
                right: 20,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _deletePhotoConfirmation(imagePath);
                  },
                  icon: const Icon(Icons.delete),
                  label: const Text('Supprimer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Confirmation de suppression d'une photo
  Future<void> _deletePhotoConfirmation(String photoPath) async {
    final client = _getFirstClient();
    if (client == null) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Supprimer la photo'),
          content: const Text('Êtes-vous sûr de vouloir supprimer cette photo ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _deletePhoto(photoPath);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );
  }

  /// Supprimer une photo
  Future<void> _deletePhoto(String photoPath) async {
    final client = _getFirstClient();
    if (client == null) return;

    final success = await HiveService.deletePhotoFromClient(
      clientId: client.id,
      cheminPhoto: photoPath,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo supprimée avec succès'),
          backgroundColor: Colors.green,
        ),
      );
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de la suppression'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ==================== BUILD WIDGET ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: _intervention.statut != 'Terminee' && _refrigerateurs.isNotEmpty
        ? FloatingActionButton.extended(
            onPressed: _startInterventionForAll,
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Commencer'),
          )
        : null,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // AppBar avec effet de parallaxe et photo client
          SliverAppBar(
            backgroundColor: AppTheme.primaryColor,
            expandedHeight: 220,
            pinned: true,
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                final top = constraints.biggest.height;
                final isCollapsed = top <= kToolbarHeight + MediaQuery.of(context).padding.top;

                return FlexibleSpaceBar(
                  centerTitle: true,
                  titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  title: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: isCollapsed ? 1.0 : 0.0,
                    child: Text(
                      _intervention.code,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  background: Container(
                    color: AppTheme.primaryColor.withOpacity(0.9),
                    child: Stack(
                      children: [
                        // Overlay avec la dernière photo du client
                        if (_getLastClientPhoto() != null)
                          Container(
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: FileImage(File(_getLastClientPhoto()!)),
                                fit: BoxFit.cover,
                                colorFilter: ColorFilter.mode(
                                  Colors.black.withOpacity(0.3),
                                  BlendMode.darken,
                                ),
                              ),
                            ),
                          ),

                        // Overlay dégradé pour lisibilité
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(0.7),
                                Colors.transparent,
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),

                        // Contenu en bas
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  _buildStatusChip(_intervention.statut),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _intervention.priorite == 1 
                                          ? Colors.red 
                                          : _intervention.priorite == 2
                                              ? Colors.orange
                                              : Colors.blue,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'Priorité: ${_intervention.priorite}',
                                      style: const TextStyle(
                                        fontSize: 12, 
                                        color: Colors.white
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _intervention.description,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Type: ${_intervention.type}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Bouton pour ajouter des photos (en haut à droite)
                        Positioned(
                          top: 20,
                          right: 20,
                          child: Row(
                            children: [
                              // Bouton pour afficher toutes les photos
                              if (_getFirstClient() != null && 
                                  HiveService.clientHasPhotos(_getFirstClient()!.id))
                                IconButton(
                                  icon: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.photo_library,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  onPressed: _showClientPhotos,
                                ),
                              
                              // Bouton pour ajouter une photo
                              IconButton(
                                icon: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.add_a_photo,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                onPressed: _addPhotoToClient,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: _showStatusUpdateDialog,
              ),
            ],
          ),

          // Contenu principal
          SliverList(
            delegate: SliverChildListDelegate([
              if (_isLoading)
                Container(
                  padding: const EdgeInsets.all(40),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                    ),
                  ),
                )
              else
                Column(
                  children: [
                    // Informations générales
                    _buildInfoSection(),
                    
                    // Clients concernés (avec photos)
                    if (_clients.isNotEmpty) _buildClientsSection(),
                    
                    // Réfrigérateurs concernés
                    if (_refrigerateurs.isNotEmpty) _buildRefrigerateursSection(),
                    
                    // Rapport d'intervention
                    if (_rapport != null) _buildRapportSection(_rapport!),
                    
                    // Checklist
                    if (_checklist != null) _buildChecklistSection(_checklist!),
                    
                    const SizedBox(height: 40),
                  ],
                ),
            ]),
          ),
        ],
      ),
    );
  }

  // ==================== AUTRES MÉTHODES (inchangées) ====================
  
  Widget _buildInfoSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📋 Informations générales',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildInfoCard('Type', _intervention.type, Icons.category),
              _buildInfoCard('Priorité', '${_intervention.priorite}', Icons.priority_high),
              _buildInfoCard('Planifiée', 
                  _intervention.datePlanifiee.toLocal().toString().split(' ')[0], 
                  Icons.calendar_today),
              if (_intervention.dateDebut != null)
                _buildInfoCard('Début', 
                    _intervention.dateDebut!.toLocal().toString().split(' ')[0], 
                    Icons.play_arrow),
              if (_intervention.dateFin != null)
                _buildInfoCard('Fin', 
                    _intervention.dateFin!.toLocal().toString().split(' ')[0], 
                    Icons.check_circle),
              _buildInfoCard('Réfrigérateurs', '${_refrigerateurs.length}', Icons.kitchen),
            ].map((card) {
              return SizedBox(
                width: (MediaQuery.of(context).size.width - 56) / 2,
                child: card,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.greyLight, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildClientsSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '👤 Clients concernés',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          
          ..._clients.map((client) {
            final photoCount = HiveService.countClientPhotos(client.id);
            final hasPhotos = photoCount > 0;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.greyLight, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.business, color: AppTheme.primaryColor),
                        ),
                        if (hasPhotos)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                photoCount.toString(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    title: Text(
                      client.nom,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      '${client.type} - ${client.adresse}',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textLight,
                      ),
                    ),
                  ),
                  
                  if (hasPhotos && client.photos.isNotEmpty)
                    Container(
                      height: 100,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: client.photos.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () => _showFullScreenImage(client.photos[index]),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(client.photos[index]),
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 100,
                                    height: 100,
                                    color: Colors.grey[200],
                                    child: const Icon(
                                      Icons.photo,
                                      color: Colors.grey,
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  /// Afficher les photos d'un client spécifique
  void _showClientPhotosForClient(Client client) {
    if (client.photos.isEmpty) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Photos de ${client.nom}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${client.photos.length} photo(s)',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: GridView.builder(
                      controller: scrollController,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: client.photos.length,
                      itemBuilder: (context, index) {
                        final photoPath = client.photos[index];
                        return GestureDetector(
                          onTap: () => _showFullScreenImage(photoPath),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              File(photoPath),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[200],
                                  child: const Icon(
                                    Icons.photo,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            Navigator.pop(context);
                            await _addPhotoToSpecificClient(client);
                          },
                          icon: const Icon(Icons.add_a_photo),
                          label: const Text('Ajouter une photo'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (client.photos.isNotEmpty)
                        ElevatedButton.icon(
                          onPressed: () async {
                            Navigator.pop(context);
                            await _clearAllPhotosForClient(client);
                          },
                          icon: const Icon(Icons.delete_sweep),
                          label: const Text('Tout supprimer'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Ajouter une photo à un client spécifique
  Future<void> _addPhotoToSpecificClient(Client client) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Prendre une photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choisir depuis la galerie'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final XFile? pickedFile = await _imagePicker.pickImage(source: source);
      if (pickedFile != null) {
        final imagePath = pickedFile.path;
        
        final success = await HiveService.addPhotoToClient(
          clientId: client.id,
          cheminPhoto: imagePath,
        );

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo ajoutée avec succès'),
              backgroundColor: Colors.green,
            ),
          );
          _loadData();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Vider toutes les photos d'un client
  Future<void> _clearAllPhotosForClient(Client client) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Supprimer toutes les photos'),
          content: Text('Êtes-vous sûr de vouloir supprimer les ${client.photos.length} photos de ${client.nom} ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final success = await HiveService.clearAllClientPhotos(client.id);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Toutes les photos ont été supprimées'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadData();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );
  }

  // ==================== AUTRES MÉTHODES (inchangées) ====================

  void _startInterventionForRefrigerateur(Refrigerateur refrigerateur) async {
    if (_intervention.statut == 'Planifiee') {
      await _updateInterventionStatus('En_cours');
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QrScanInterventionScreen(
          intervention: _intervention,
        ),
      ),
    ).then((value) {
      if (value == true) {
        _loadData();
      }
    });
  }

  void _startInterventionForAll() async {
    if (_intervention.statut == 'Planifiee') {
      await _updateInterventionStatus('En_cours');
    }
    
    if (_refrigerateurs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucun réfrigérateur à traiter'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    final premierRefrigerateur = _refrigerateurs.firstWhere(
      (r) => r.photosApresReparation.isEmpty,
      orElse: () => _refrigerateurs.first,
    );
    
    _startInterventionForRefrigerateur(premierRefrigerateur);
  }
  
  Widget _buildRefrigerateursSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '❄️ Réfrigérateurs concernés',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          ..._refrigerateurs.map((refrigerateur) {
            final client = HiveService.getClientById(refrigerateur.clientId);
            
            Color getStatusColor() {
              switch (refrigerateur.statut) {
                case 'Fonctionnel': return Colors.green;
                case 'En_panne': return Colors.red;
                case 'Maintenance': return Colors.orange;
                default: return Colors.grey;
              }
            }
            
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RefrigerateurDetailScreen(
                      refrigerateur: refrigerateur,
                    ),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.greyLight, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: getStatusColor().withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.kitchen, color: getStatusColor()),
                      ),
                      title: Text(
                        refrigerateur.codeQR,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${refrigerateur.marque} ${refrigerateur.modele}'),
                          if (client != null) Text(client.nom),
                        ],
                      ),
                      trailing: const Icon(Icons.chevron_right, color: AppTheme.greyDark),
                    ),
                    
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: getStatusColor(),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              refrigerateur.statut,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 18),
                            onPressed: () => _showRefrigerateurStatusDialog(refrigerateur),
                          ),
                          IconButton(
                            icon: const Icon(Icons.tune, size: 18),
                            onPressed: () => _showRefrigerateurCaracteristiquesDialog(refrigerateur),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  void _showRefrigerateurStatusDialog(Refrigerateur refrigerateur) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Changer le statut',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ...['Fonctionnel', 'En_panne', 'Maintenance'].map((status) {
                Color getColor(String s) {
                  switch (s) {
                    case 'Fonctionnel': return Colors.green;
                    case 'En_panne': return Colors.red;
                    case 'Maintenance': return Colors.orange;
                    default: return Colors.grey;
                  }
                }
                
                return ListTile(
                  leading: Icon(Icons.circle, color: getColor(status)),
                  title: Text(status),
                  trailing: refrigerateur.statut == status 
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    _updateRefrigerateurStatus(refrigerateur.id, status);
                  },
                );
              }),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
  
  void _showRefrigerateurCaracteristiquesDialog(Refrigerateur refrigerateur) {
    final TextEditingController keyController = TextEditingController();
    final TextEditingController valueController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Modifier les caractéristiques',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                
                if (refrigerateur.caracteristiques.isNotEmpty) ...[
                  const Text(
                    'Caractéristiques actuelles:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ...refrigerateur.caracteristiques.entries.map((entry) {
                    return ListTile(
                      title: Text(entry.key),
                      subtitle: Text(entry.value.toString()),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          // TODO: Implémenter la suppression
                        },
                      ),
                    );
                  }).toList(),
                  const Divider(),
                ],
                
                TextField(
                  controller: keyController,
                  decoration: const InputDecoration(
                    labelText: 'Nom de la caractéristique',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: valueController,
                  decoration: const InputDecoration(
                    labelText: 'Valeur',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (keyController.text.isNotEmpty && valueController.text.isNotEmpty) {
                            final newCaracteristiques = Map<String, dynamic>.from(
                              refrigerateur.caracteristiques
                            );
                            newCaracteristiques[keyController.text] = valueController.text;
                            
                            _updateRefrigerateurCaracteristiques(
                              refrigerateur.id, 
                              newCaracteristiques
                            );
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Ajouter/Mettre à jour'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Future<void> _updateRefrigerateurStatus(String refrigerateurId, String newStatus) async {
    try {
      HiveService.updateRefrigerateurStatus(refrigerateurId, newStatus);
      
      setState(() {
        final index = _refrigerateurs.indexWhere((r) => r.id == refrigerateurId);
        if (index != -1) {
          _refrigerateurs[index].statut = newStatus;
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Statut mis à jour: $newStatus'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de la mise à jour'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _updateRefrigerateurCaracteristiques(
    String refrigerateurId, 
    Map<String, dynamic> caracteristiques
  ) async {
    try {
      HiveService.updateRefrigerateurCaracteristique(refrigerateurId, caracteristiques);
      
      setState(() {
        final index = _refrigerateurs.indexWhere((r) => r.id == refrigerateurId);
        if (index != -1) {
          _refrigerateurs[index].caracteristiques = caracteristiques;
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Caractéristiques mises à jour'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de la mise à jour'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Widget _buildRapportSection(RapportIntervention rapport) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📄 Rapport d\'intervention',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.greyLight, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRapportInfo('Problème diagnostiqué', rapport.problemeDiagnostique),
                const SizedBox(height: 12),
                _buildRapportInfo('Actions réalisées', rapport.actionsRealisees),
                const SizedBox(height: 12),
                _buildRapportInfo('Temps passé', '${rapport.tempsPasse} heures'),
                
                if (rapport.piecesUtilisees.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildRapportInfo('Pièces utilisées', rapport.piecesUtilisees.join(', ')),
                ],
                
                if (rapport.observations != null && rapport.observations!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildRapportInfo('Observations', rapport.observations!),
                ],
                
                if (rapport.clientSatisfait != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.sentiment_satisfied, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Client satisfait: ${rapport.clientSatisfait! ? 'Oui' : 'Non'}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRapportInfo(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textLight,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: const TextStyle(
            fontSize: 16,
          ),
        ),
      ],
    );
  }
  
  Widget _buildChecklistSection(Checklist checklist) {
    final itemsVerifies = checklist.items.where((item) => item.verifie).length;
    final totalItems = checklist.items.length;
    final percentage = totalItems > 0 ? (itemsVerifies / totalItems * 100).toInt() : 0;
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '✅ Checklist',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: checklist.complete ? Colors.green : Colors.orange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$percentage% ($itemsVerifies/$totalItems)',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.greyLight, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: totalItems > 0 ? itemsVerifies / totalItems : 0,
                    backgroundColor: AppTheme.greyLight,
                    color: checklist.complete ? Colors.green : Colors.orange,
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 16),
                
                ...checklist.items.map((item) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: item.verifie ? Colors.green.withOpacity(0.05) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: item.verifie ? Colors.green.withOpacity(0.2) : AppTheme.greyLight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              item.verifie ? Icons.check_circle : Icons.radio_button_unchecked,
                              color: item.verifie ? Colors.green : AppTheme.greyDark,
                            ),
                             const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.description,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: item.obligatoire ? FontWeight.w600 : FontWeight.normal,
                                  color: item.verifie ? Colors.green : Colors.black,
                                ),
                              ),
                              if (item.observation != null && item.observation!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    item.observation!,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textLight,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                       
                          ],
                        ),
                        SizedBox(height: 8),
                        if (item.obligatoire)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Obligatoire',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}