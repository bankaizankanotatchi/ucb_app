import 'package:flutter/material.dart';
import 'package:ucb_app/constants/app_theme.dart';
import 'package:ucb_app/models/technicien.dart';
import 'package:ucb_app/models/intervention.dart';
import 'package:ucb_app/pages/dashboard/maps/map_screen.dart';
import 'package:ucb_app/pages/login_screen.dart';
import 'package:ucb_app/services/hive_service.dart';

class SidebarMenu extends StatelessWidget {
  final bool showSidebar;
  final Technicien technicien;
  final int currentPageIndex;
  final List<Intervention>? filteredInterventions;
  final String? selectedFilter;
  final String? searchQuery;
  final ValueChanged<int> onNavigationItemSelected;
  final VoidCallback onClose;

  const SidebarMenu({
    super.key,
    required this.showSidebar,
    required this.technicien,
    required this.currentPageIndex,
    this.filteredInterventions,
    this.selectedFilter,
    this.searchQuery,
    required this.onNavigationItemSelected,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      left: showSidebar ? 0 : -300,
      top: 0,
      bottom: 0,
      child: Container(
        width: 300,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(5, 0),
            ),
          ],
        ),
        child: Column(
          children: [
            // En-tête du sidebar
            _buildHeader(context),
            
            // Section d'informations du technicien
            _buildTechnicienInfo(),
            
            // Section des statistiques
            _buildStatsSection(),
            
            // Section des actions
            _buildActionButtons(context),
            
            // Pied de page
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          // Bouton fermer
          IconButton(
            onPressed: onClose,
            icon: const Icon(
              Icons.close,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          
          // Titre
          Text(
            'Menu',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicienInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppTheme.greyLight,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar et nom
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.secondaryColor,
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    '${technicien.prenom[0]}${technicien.nom[0]}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${technicien.prenom} ${technicien.nom}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      technicien.specialite,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Informations additionnelles
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              SizedBox(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Matricule',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textLight,
                      ),
                    ),
                    Text(
                      technicien.matricule,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),
              SizedBox(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Email',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textLight,
                      ),
                    ),
                    Text(
                      technicien.email,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    final stats = HiveService.getStatistiquesGlobales(technicien.id);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppTheme.greyLight,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Titre
          Row(
            children: [
              Icon(
                Icons.insights,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Statistiques rapides',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Grille de statistiques
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard(
                'En cours',
                '${stats['interventions_en_cours']}',
                Icons.schedule,
                AppTheme.secondaryColor,
              ),
              _buildStatCard(
                'Terminées',
                '${stats['interventions_terminees']}',
                Icons.check_circle,
                Colors.green,
              ),
              _buildStatCard(
                'Réfrigérateurs',
                '${stats['refrigerateurs_en_panne']}',
                Icons.kitchen,
                Colors.orange,
              ),
              _buildStatCard(
                'Notifications',
                '${stats['notifications_non_lues']}',
                Icons.notifications,
                Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                icon,
                size: 20,
                color: color,
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppTheme.greyLight,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Bouton Synchroniser
          ElevatedButton.icon(
           onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => MapScreen(technicien: technicien),
                ),
             );
                      
              onClose();
            },
            icon: const Icon(Icons.map_outlined, size: 20),
            label: const Text('Cartographie'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
         ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppTheme.greyLight,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Version
          Text(
            'V 1.0.0',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textLight,
            ),
          ),
          
          // Bouton déconnexion
          TextButton.icon(
            onPressed: () {
            _showLogoutConfirmationDialog(context);
          },
            icon: const Icon(
              Icons.logout,
              size: 16,
            ),
            label: const Text('Déconnexion'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }


// Ajoutez cette méthode pour afficher la boîte de dialogue de confirmation :
void _showLogoutConfirmationDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      title: Row(
        children: [
          Icon(
            Icons.logout,
            color: Colors.red,
            size: 24,
          ),
          SizedBox(width: 12),
          Text(
            'Déconnexion',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
        ],
      ),
      content: Text(
        'Êtes-vous sûr de vouloir vous déconnecter ?',
        style: TextStyle(
          fontSize: 16,
          color: AppTheme.textDark,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(
            'Annuler',
            style: TextStyle(
              color: AppTheme.textLight,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
           await HiveService.logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text('Déconnecter'),
        ),
      ],
    ),
  );
}

}