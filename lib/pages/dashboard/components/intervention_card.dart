import 'package:flutter/material.dart';
import 'package:ucb_app/constants/app_theme.dart';
import 'package:ucb_app/models/intervention.dart';
import 'package:intl/intl.dart';
import 'package:ucb_app/pages/dashboard/maps/intervention_detail_screen.dart';
import 'package:ucb_app/pages/dashboard/maps/intervention_map_screen.dart';

class InterventionCard extends StatelessWidget {
  final Intervention intervention;
  final VoidCallback onTap;

  const InterventionCard({
    super.key,
    required this.intervention,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final statusColors = {
      'Planifiee': Colors.blue,
      'En_cours': Colors.orange,
      'Terminee': Colors.green,
      'Annulee': Colors.grey,
    };

    final priorityColors = {
      1: Colors.red,    // Urgent
      2: Colors.orange, // Haute
      3: Colors.blue,   // Normale
    };

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec priorité
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: priorityColors[intervention.priorite]?.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    intervention.code,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: priorityColors[intervention.priorite],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      intervention.priorite == 1
                          ? 'URGENT'
                          : intervention.priorite == 2
                              ? 'HAUTE'
                              : 'NORMALE',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Contenu
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    intervention.description,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: AppTheme.textLight,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        dateFormat.format(intervention.datePlanifiee),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textLight,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColors[intervention.statut]?.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: statusColors[intervention.statut] ??
                                AppTheme.greyMedium,
                          ),
                        ),
                        child: Text(
                          intervention.statut == 'Planifiee'
                              ? 'Planifiée'
                              : intervention.statut == 'En_cours'
                                  ? 'En cours'
                                  : intervention.statut == 'Terminee'
                                      ? 'Terminée'
                                      : 'Annulée',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: statusColors[intervention.statut] ??
                                AppTheme.textLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.group,
                        size: 16,
                        color: AppTheme.textLight,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${intervention.technicienIds.length} technicien(s)',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textLight,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.kitchen,
                        size: 16,
                        color: AppTheme.textLight,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${intervention.refrigerateurIds.length} réfrigérateur(s)',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: AppTheme.greyLight,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => InterventionMapScreen(
                          intervention: intervention,
                        ),
                      ),
                    );
                      },
                      icon: const Icon(Icons.navigation, size: 16),
                      label: const Text('Y aller'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        side: BorderSide(color: AppTheme.primaryColor),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => InterventionDetailScreen(
                          intervention: intervention,
                        ),
                      ),
                    );
                      },
                      icon: const Icon(Icons.play_arrow, size: 16),
                      label: const Text('Démarrer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}