import 'dart:async'; // Ajoutez cette importation en haut du fichier
import 'package:flutter/material.dart';
import 'package:ucb_app/constants/app_theme.dart';
import 'package:ucb_app/models/technicien.dart';
import 'package:ucb_app/models/intervention.dart';
import 'package:ucb_app/pages/dashboard/components/sidebar_menu.dart';
import 'package:ucb_app/pages/dashboard/components/intervention_card.dart';
import 'package:ucb_app/pages/dashboard/components/stats_card.dart';
import 'package:ucb_app/pages/dashboard/maps/intervention_detail_screen.dart';
import 'package:ucb_app/pages/dashboard/maps/intervention_map_screen.dart';
import 'package:ucb_app/pages/dashboard/notifications/notifications_screen.dart';
import 'package:ucb_app/pages/dashboard/stats/stats_screen.dart';
import 'package:ucb_app/services/hive_service.dart';

class HomeScreen extends StatefulWidget {
  final Technicien technicien;

  const HomeScreen({super.key, required this.technicien});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Intervention> _interventions = [];
  bool _showSidebar = false;
  int _currentPageIndex = 0;
  
  // Variables pour la recherche
  String _searchQuery = '';
  String _selectedFilter = 'Toutes';
  bool _isLoading = true;
  
  // Nouvelle variable pour le nombre de notifications non lues
  int _unreadNotificationsCount = 0;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadNotificationsCount();
    
    // Rafraîchir le compteur toutes les 30 secondes
    _startRefreshTimer();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startRefreshTimer() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadNotificationsCount();
      }
    });
  }

  void _loadData() async {
    setState(() {
      _isLoading = true;
    });

    // Simuler un chargement
    await Future.delayed(const Duration(milliseconds: 500));

    // Charger les interventions du technicien
    final interventions = HiveService.getInterventionsByTechnicien(widget.technicien.id);
    
    setState(() {
      _interventions = interventions;
      _isLoading = false;
    });
  }

  void _loadNotificationsCount() {
    final unreadNotifications = HiveService.getNotificationsNonLues();
    if (mounted) {
      setState(() {
        _unreadNotificationsCount = unreadNotifications.length;
      });
    }
  }

  void _onNavigationItemSelected(int index) {
    setState(() {
      _currentPageIndex = index;
      _showSidebar = false;
    });
  }

  void _updateSearchQuery(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _updateSelectedFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
  }

  List<Intervention> get _filteredInterventions {
    List<Intervention> filtered = _interventions;

    if (_selectedFilter != 'Toutes') {
      filtered = filtered.where((i) => i.statut == _selectedFilter).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((i) {
        return i.code.toLowerCase().contains(query) ||
               i.description.toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
  }

  void _refreshData() {
    _loadData();
  }

  void _showNotifications() async {
    // Naviguer vers l'écran des notifications
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NotificationsScreen(technicien: widget.technicien),
      ),
    );
    
    // Recharger le nombre de notifications après être revenu
    _loadNotificationsCount();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recharger les notifications quand l'écran redevient visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotificationsCount();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Contenu principal
          Column(
            children: [
              // AppBar personnalisé
              _buildAppBar(),

              // Corps de l'application
              Expanded(
                child: Container(
                  color: AppTheme.greyLight,
                  child: _currentPageIndex == 0
                      ? _buildHomeContent()
                      : _currentPageIndex == 1
                          ? StatsScreen(
                              technicien: widget.technicien,
                              interventions: _interventions,
                            )
                          : _buildPlaceholderScreen(),
                ),
              ),
            ],
          ),

          // Overlay flou quand le sidebar est ouvert
          if (_showSidebar)
            GestureDetector(
              onTap: () {
                setState(() {
                  _showSidebar = false;
                });
              },
              child: Container(
                color: Colors.black.withOpacity(0.4),
              ),
            ),

          // Sidebar menu
          SidebarMenu(
            showSidebar: _showSidebar,
            technicien: widget.technicien,
            currentPageIndex: _currentPageIndex,
            filteredInterventions: _filteredInterventions,
            selectedFilter: _selectedFilter,
            searchQuery: _searchQuery,
            onNavigationItemSelected: _onNavigationItemSelected,
            onClose: () {
              setState(() {
                _showSidebar = false;
              });
            },
          ),
        ],
      ),

    );
  }

  Widget _buildPlaceholderScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _currentPageIndex == 2 ? Icons.settings : Icons.help,
            size: 80,
            color: AppTheme.greyMedium,
          ),
          const SizedBox(height: 20),
          Text(
            _currentPageIndex == 2 ? 'Paramètres' : 'Aide & Support',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Page en cours de développement',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Menu button
              IconButton(
                onPressed: () {
                  setState(() {
                    _showSidebar = !_showSidebar;
                  });
                },
                icon: const Icon(Icons.menu, color: Colors.white),
              ),

              // Notifications avec badge dynamique
              Stack(
                children: [
                  IconButton(
                    onPressed: _showNotifications,
                    icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                  ),
                  // Badge rouge avec le nombre de notifications non lues
                  if (_unreadNotificationsCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          _unreadNotificationsCount > 9 ? '9+' : '$_unreadNotificationsCount',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: _unreadNotificationsCount > 9 ? 6 : 8,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Bienvenue
          Row(
            children: [
              Text(
                'Bonjour, ',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '${widget.technicien.prenom} ${widget.technicien.nom}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),
          Text(
            widget.technicien.specialite,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withOpacity(0.8),
            ),
          ),

          const SizedBox(height: 16),

          // Barre de recherche
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              onChanged: _updateSearchQuery,
              decoration: InputDecoration(
                hintText: 'Rechercher une intervention...',
                border: InputBorder.none,
                prefixIcon: const Icon(Icons.search, color: AppTheme.greyDark),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () => _updateSearchQuery(''),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Filtres rapides
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Toutes', _selectedFilter == 'Toutes'),
                _buildFilterChip('Planifiée', _selectedFilter == 'Planifiee'),
                _buildFilterChip('En cours', _selectedFilter == 'En_cours'),
                _buildFilterChip('Terminée', _selectedFilter == 'Terminee'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool selected) {
    return GestureDetector(
      onTap: () => _updateSelectedFilter(
        label == 'Toutes' ? 'Toutes' :
        label == 'Planifiée' ? 'Planifiee' :
        label == 'En cours' ? 'En_cours' :
        label == 'Terminée' ? 'Terminee' : 'Urgent'
      ),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppTheme.primaryColor : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppTheme.primaryColor : Colors.white,
            fontSize: 14,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppTheme.primaryColor,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        _refreshData();
      },
      color: AppTheme.primaryColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Interventions du jour
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Mes interventions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Badge(
                    label: Text(_filteredInterventions.length.toString()),
                    backgroundColor: AppTheme.primaryColor,
                    textColor: Colors.white,
                  ),
                ],
              ),
            ),

            // Liste des interventions
            if (_filteredInterventions.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.assignment_outlined,
                      size: 64,
                      color: AppTheme.greyMedium,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _interventions.isEmpty
                          ? 'Aucune intervention planifiée'
                          : 'Aucun résultat trouvé',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.textLight,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _interventions.isEmpty
                          ? 'Votre planning sera mis à jour prochainement'
                          : 'Essayez avec d\'autres critères de recherche',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.greyDark,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: _filteredInterventions.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final intervention = _filteredInterventions[index];
                  return InterventionCard(
                    intervention: intervention,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => InterventionDetailScreen(
                          intervention: intervention,
                        ),
                      ),
                    );
                  },
                   );
                },
              ),
          ],
        ),
      ),
    );
  }
}