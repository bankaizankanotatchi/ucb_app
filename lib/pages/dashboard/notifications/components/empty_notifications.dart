import 'package:flutter/material.dart';
import 'package:ucb_app/constants/app_theme.dart';

class EmptyNotifications extends StatelessWidget {
  final bool showUnreadOnly;
  final String selectedFilter;
  final VoidCallback onResetFilters;

  const EmptyNotifications({
    super.key,
    required this.showUnreadOnly,
    required this.selectedFilter,
    required this.onResetFilters,
  });

  @override
  Widget build(BuildContext context) {
    final hasFilters = showUnreadOnly || selectedFilter != 'Toutes';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.notifications_off_outlined,
                  size: 64,
                  color: AppTheme.primaryColor.withOpacity(0.6),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Titre
            Text(
              hasFilters ? 'Aucune notification correspondante' : 'Aucune notification',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            // Description
            Text(
              hasFilters
                  ? 'Aucune notification ne correspond à vos filtres actuels.'
                  : 'Vous n\'avez pas encore de notifications.\nElles apparaîtront ici automatiquement.',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textLight,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 24),
            
            // Actions
            if (hasFilters)
              ElevatedButton.icon(
                onPressed: onResetFilters,
                icon: Icon(Icons.filter_alt_off, size: 20),
                label: Text('Réinitialiser les filtres'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            
            if (!hasFilters)
              OutlinedButton.icon(
                onPressed: () {
                  // TODO: Implémenter le rafraîchissement manuel
                },
                icon: Icon(Icons.refresh, size: 20),
                label: Text('Rafraîchir'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: BorderSide(color: AppTheme.primaryColor),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}