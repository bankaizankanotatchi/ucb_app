import 'package:flutter/material.dart';
import 'package:ucb_app/constants/app_theme.dart';

class NotificationsAppBar extends StatelessWidget {
  final int unreadCount;
  final int todayCount;
  final int totalCount;
  final int interventionCount;
  final int urgentCount;
  final int systemCount;
  final String selectedFilter;
  final bool showUnreadOnly;
  final ValueChanged<String> onFilterChanged;
  final VoidCallback onToggleUnreadOnly;
  final VoidCallback onMarkAllAsRead;
  final VoidCallback onDeleteAllRead;

  const NotificationsAppBar({
    super.key,
    required this.unreadCount,
    required this.todayCount,
    required this.totalCount,
    required this.interventionCount,
    required this.urgentCount,
    required this.systemCount,
    required this.selectedFilter,
    required this.showUnreadOnly,
    required this.onFilterChanged,
    required this.onToggleUnreadOnly,
    required this.onMarkAllAsRead,
    required this.onDeleteAllRead,
  });

  @override
  Widget build(BuildContext context) {
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
          // En-tête avec bouton retour
          Row(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Text(
                'Notifications',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              
              // Badge notifications non lues
              if (unreadCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                  // Menu d'actions
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: Colors.white),
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (value) {
                  if (value == 'mark_all_read') {
                    onMarkAllAsRead();
                  } else if (value == 'delete_read') {
                    onDeleteAllRead();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'mark_all_read',
                    child: Row(
                      children: [
                        Icon(Icons.mark_email_read, color: AppTheme.primaryColor),
                        SizedBox(width: 12),
                        Text('Tout marquer comme lu'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete_read',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Supprimer les lues'),
                      ],
                    ),
                  ),
                ],
              ),
            
            ],
          ),

          const SizedBox(height: 16),

          // Statistiques rapides - AVEC LES VRAIES VALEURS
          Row(
            children: [
              _buildStatItem(
                icon: Icons.notifications_active,
                label: 'Non lues',
                value: unreadCount.toString(),
                color: Colors.red,
              ),
              const SizedBox(width: 16),
              _buildStatItem(
                icon: Icons.today,
                label: "Aujourd'hui",
                value: todayCount.toString(),
                color: Colors.blue,
              ),
              const SizedBox(width: 16),
              _buildStatItem(
                icon: Icons.all_inbox,
                label: 'Total',
                value: totalCount.toString(),
                color: Colors.green,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Filtres rapides
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Toutes', selectedFilter == 'Toutes'),
                _buildFilterChip('Intervention', selectedFilter == 'Intervention'),
                _buildFilterChip('Urgent', selectedFilter == 'Urgent'),
                _buildFilterChip('Système', selectedFilter == 'System'),
              ],
            ),
          ),],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 8),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStatItem(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool selected) {
    return GestureDetector(
      onTap: () => onFilterChanged(label == 'Toutes' ? 'Toutes' : label),
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
}