import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ucb_app/constants/app_theme.dart';
import 'package:ucb_app/models/refrigerateur.dart';
import 'package:ucb_app/models/client.dart';
import 'package:ucb_app/services/hive_service.dart';

class RefrigerateurDetailScreen extends StatefulWidget {
  final Refrigerateur refrigerateur;
  
  const RefrigerateurDetailScreen({super.key, required this.refrigerateur});
  
  @override
  State<RefrigerateurDetailScreen> createState() => _RefrigerateurDetailScreenState();
}

class _RefrigerateurDetailScreenState extends State<RefrigerateurDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  late Client? _client;
  
  @override
  void initState() {
    super.initState();
    _client = HiveService.getClientById(widget.refrigerateur.clientId);
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final refrigerateur = widget.refrigerateur;
    final hasPhotos = refrigerateur.aDesPhotos;
    final photoStats = refrigerateur.resumePhotos;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // AppBar avec effet de parallaxe
SliverAppBar(
  backgroundColor: AppTheme.primaryColor,
  expandedHeight: 250,
  pinned: true,
  flexibleSpace: LayoutBuilder(
    builder: (context, constraints) {
      // Hauteur actuelle de l'appbar
      double top = constraints.biggest.height;

      // L'appbar est réduite si sa hauteur <= toolbar + status bar
      bool isCollapsed = top <= kToolbarHeight + MediaQuery.of(context).padding.top;

      return FlexibleSpaceBar(
        centerTitle: true, // titre centré quand pinned
        titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        title: Text(
          refrigerateur.codeQR,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isCollapsed
                ? Colors.white // blanc quand scrolled
                : Colors.white.withOpacity(0.0), // transparent quand déployé
          ),
        ),
        background: Container(
          color: AppTheme.primaryColor.withOpacity(0.9),
          child: Stack(
            children: [
              // Image de fond (si disponible)
              if (refrigerateur.dernierePhoto != null)
                Image.file(
                  File(refrigerateur.dernierePhoto!), // CHANGÉ ICI
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              // Overlay dégradé
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      const Color.fromARGB(255, 5, 5, 5).withOpacity(0.5),
                      const Color.fromARGB(255, 43, 43, 43).withOpacity(0.3),
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
                        _buildStatusChip(refrigerateur.statut),
                        const SizedBox(width: 8),
                        _buildPhotoChip(refrigerateur.nombreTotalPhotos),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${refrigerateur.marque} ${refrigerateur.modele}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      refrigerateur.numeroSerie,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
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
),


          // Contenu principal
          SliverList(
            delegate: SliverChildListDelegate([
              // Informations principales
              _buildInfoSection(refrigerateur),
              
              // Section Photos (si disponibles)
              if (hasPhotos) _buildPhotosSection(refrigerateur),
              
              // Section Client
              if (_client != null) _buildClientSection(_client!),
              
              // Caractéristiques techniques
              if (refrigerateur.caracteristiques.isNotEmpty)
                _buildCaracteristiquesSection(refrigerateur),
              
              // Section Historique
              _buildHistoriqueSection(refrigerateur),
              
              
              const SizedBox(height: 40),
            ]),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatusChip(String statut) {
    Color backgroundColor;
    Color textColor;
    String label;
    
    switch (statut) {
      case 'Fonctionnel':
        backgroundColor = Colors.green;
        textColor = Colors.white;
        label = '✅ Fonctionnel';
        break;
      case 'En_panne':
        backgroundColor = Colors.red;
        textColor = Colors.white;
        label = '🔴 En panne';
        break;
      case 'Maintenance':
        backgroundColor = Colors.orange;
        textColor = Colors.white;
        label = '🟡 Maintenance';
        break;
      default:
        backgroundColor = Colors.grey;
        textColor = Colors.white;
        label = statut;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
  
  Widget _buildPhotoChip(int photoCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.photo, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            '$photoCount photos',
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
Widget _buildInfoSection(Refrigerateur refrigerateur) {
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
        
        // Grille d'informations avec Wrap
        Wrap(
          spacing: 16, // espace horizontal entre les cartes
          runSpacing: 16, // espace vertical entre les lignes
          children: [
            _buildInfoCard('QR Code', refrigerateur.codeQR, Icons.qr_code),
            _buildInfoCard('Série', refrigerateur.numeroSerie, Icons.confirmation_number),
            _buildInfoCard('Marque', refrigerateur.marque, Icons.business),
            _buildInfoCard('Modèle', refrigerateur.modele, Icons.devices),
            _buildInfoCard('Type', refrigerateur.type, Icons.category),
            _buildInfoCard('Adresse', refrigerateur.adresse, Icons.location_on),
          ].map((card) {
            return SizedBox(
              width: (MediaQuery.of(context).size.width - 56) / 2, // 2 colonnes
              child: card,
            );
          }).toList(),
        ),
        
        // Coordonnées GPS
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.greyLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.gps_fixed, color: AppTheme.primaryColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Coordonnées GPS',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${refrigerateur.latitude.toStringAsFixed(6)}, '
                      '${refrigerateur.longitude.toStringAsFixed(6)}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 20),
                onPressed: () => _copyCoordinates(refrigerateur),
                tooltip: 'Copier les coordonnées',
              ),
            ],
          ),
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
  
  Widget _buildPhotosSection(Refrigerateur refrigerateur) {
    final photoStats = refrigerateur.resumePhotos;
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '📸 Galerie photos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Statistiques des photos
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.greyLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildPhotoStat('Avant', photoStats['avant'] ?? 0),
                _buildPhotoStat('Pendant', photoStats['pendant'] ?? 0),
                _buildPhotoStat('Après', photoStats['apres'] ?? 0),
                _buildPhotoStat('Total', photoStats['total'] ?? 0),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Galerie par catégorie
          Column(
            children: [
              _buildPhotoCategory(
                'Avant réparation',
                refrigerateur.photosAvantReparation,
                Icons.photo_camera,
                Colors.blue,
              ),
              const SizedBox(height: 16),
              _buildPhotoCategory(
                'Pendant réparation',
                refrigerateur.photosPendantReparation,
                Icons.build,
                Colors.orange,
              ),
              const SizedBox(height: 16),
              _buildPhotoCategory(
                'Après réparation',
                refrigerateur.photosApresReparation,
                Icons.check_circle,
                Colors.green,
              ),
            ],
          ),
          
          // Dernière mise à jour photos
          if (refrigerateur.dateDernieresPhotos != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Dernières photos ajoutées le '
                        '${refrigerateur.dateDernieresPhotos!.day}/'
                        '${refrigerateur.dateDernieresPhotos!.month}/'
                        '${refrigerateur.dateDernieresPhotos!.year}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildPhotoStat(String label, int count) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: count > 0 ? AppTheme.primaryColor : Colors.grey,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: count > 0 ? AppTheme.primaryColor : Colors.grey,
          ),
        ),
      ],
    );
  }
  
// Remplacer la méthode _buildPhotoCategory :
Widget _buildPhotoCategory(String title, List<String> photos, IconData icon, Color color) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            '${photos.length} photo${photos.length > 1 ? 's' : ''}',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textLight,
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      
      if (photos.isEmpty)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.greyLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              'Aucune photo disponible',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        )
      else
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: photos.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _showPhotoDetail(photos[index]),
                child: Container(
                  width: 150,
                  margin: EdgeInsets.only(
                    right: index < photos.length - 1 ? 12 : 0,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey[200],
                    image: DecorationImage(
                      image: FileImage(File(photos[index])), // CHANGÉ ICI
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
    ],
  );
}

// Remplacer la méthode _showPhotoDetail :
void _showPhotoDetail(String photoPath) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(photoPath), // CHANGÉ ICI
                      width: double.infinity,
                      height: 300,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildClientSection(Client client) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '👤 Client',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(16),
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
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.business, color: AppTheme.primaryColor),
                  ),
                  title: Text(
                    client.nom,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    client.type,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textLight,
                    ),
                  ),
                ),
                
                const Divider(height: 20),
                
                // Informations de contact
                Column(
                  children: [
                    if (client.contact != null)
                      _buildContactInfo('Personne', client.contact!, Icons.person),
                    _buildContactInfo('Téléphone', client.telephone, Icons.phone),
                    if (client.email.isNotEmpty)
                      _buildContactInfo('Email', client.email, Icons.email),
                    _buildContactInfo('Adresse', client.adresse, Icons.location_on),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildContactInfo(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.textLight),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
Widget _buildCaracteristiquesSection(Refrigerateur refrigerateur) {
  return Padding(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '⚙️ Caractéristiques techniques',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        
        Wrap(
          spacing: 8, // espace horizontal entre les items
          runSpacing: 8, // espace vertical entre les lignes
          children: refrigerateur.caracteristiques.entries.map((entry) {
            return Container(
              width: (MediaQuery.of(context).size.width - 60) / 2, // 2 colonnes
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.greyLight, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.key,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    entry.value.toString(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    ),
  );
}

  Widget _buildHistoriqueSection(Refrigerateur refrigerateur) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📅 Historique',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.greyLight, width: 1),
            ),
            child: Column(
              children: [
                if (refrigerateur.dateInstallation != null)
                  _buildHistoryItem(
                    'Installation',
                    refrigerateur.dateInstallation!,
                    Icons.install_desktop,
                    Colors.green,
                  ),
                if (refrigerateur.dateDerniereMaintenance != null)
                  _buildHistoryItem(
                    'Dernière maintenance',
                    refrigerateur.dateDerniereMaintenance!,
                    Icons.build,
                    Colors.blue,
                  ),
                if (refrigerateur.dateDernieresPhotos != null)
                  _buildHistoryItem(
                    'Dernières photos',
                    refrigerateur.dateDernieresPhotos!,
                    Icons.photo_library,
                    Colors.purple,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHistoryItem(String label, DateTime date, IconData icon, Color color) {
    final formattedDate = '${date.day}/${date.month}/${date.year}';
    final timeAgo = _getTimeAgo(date);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$formattedDate • $timeAgo',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return 'Il y a $years an${years > 1 ? 's' : ''}';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return 'Il y a $months mois';
    } else if (difference.inDays > 0) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'Il y a ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'À l\'instant';
    }
  }
  
  // Méthodes d'actions
  void _showAllPhotos() {
    // TODO: Naviguer vers un écran dédié pour toutes les photos
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Galerie complète'),
        content: const Text('Cette fonctionnalité sera disponible prochainement.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _copyCoordinates(Refrigerateur refrigerateur) {
    final coordinates = '${refrigerateur.latitude}, ${refrigerateur.longitude}';
    // TODO: Implémenter la copie dans le presse-papier
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Coordonnées copiées: $coordinates'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  void _shareRefrigerateurInfo() {
    // TODO: Implémenter le partage
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonction de partage à venir'),
        duration: Duration(seconds: 2),
      ),
    );
  }
  
  void _createIntervention() {
    // TODO: Naviguer vers la création d'intervention
    Navigator.pop(context); // Fermer d'abord cette page
    // Puis naviguer vers l'écran de création d'intervention
  }
  
  void _openNavigation() {
    // TODO: Ouvrir l'application de navigation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ouverture de la navigation...'),
        duration: Duration(seconds: 2),
      ),
    );
  }
  
  void _printDetails() {
    // TODO: Implémenter l'impression
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Impression des détails...'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}