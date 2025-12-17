import 'package:flutter/material.dart';
import 'package:ucb_app/constants/app_theme.dart';
import 'package:ucb_app/models/intervention.dart';
import 'package:ucb_app/pages/dashboard/stats/widgets/recent_intervention_item_widget.dart';

class StatsRecentInterventions extends StatelessWidget {
  final List<Intervention> recentInterventions;

  const StatsRecentInterventions({
    super.key,
    required this.recentInterventions,
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
                Icon(Icons.history, color: AppTheme.primaryColor, size: 24),
                SizedBox(width: 8),
                Text(
                  'Interventions récentes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            ...recentInterventions.map((intervention) => RecentInterventionItemWidget(intervention: intervention)),
            if (recentInterventions.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'Aucune intervention dans cette période',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textLight),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}