import 'package:flutter/material.dart';
import 'package:ucb_app/constants/app_theme.dart';
import 'package:ucb_app/pages/dashboard/stats/widgets/distribution_item_widget.dart';


class StatsStatusDistribution extends StatelessWidget {
  final int plannedInterventions;
  final int inProgressInterventions;
  final int completedInterventions;
  final int totalInterventions;

  const StatsStatusDistribution({
    super.key,
    required this.plannedInterventions,
    required this.inProgressInterventions,
    required this.completedInterventions,
    required this.totalInterventions,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pie_chart, color: AppTheme.primaryColor, size: 24),
                SizedBox(width: 8),
                Text(
                  'Répartition des interventions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            DistributionItemWidget(
              status: 'Planifiées',
              count: plannedInterventions,
              total: totalInterventions,
              color: Colors.blue,
            ),
            DistributionItemWidget(
              status: 'En cours',
              count: inProgressInterventions,
              total: totalInterventions,
              color: Colors.orange,
            ),
            DistributionItemWidget(
              status: 'Terminées',
              count: completedInterventions,
              total: totalInterventions,
              color: Colors.green,
            ),
          ],
        ),
      ),
    );
  }
}