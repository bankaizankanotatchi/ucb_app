import 'package:flutter/material.dart';
import 'package:ucb_app/constants/app_theme.dart';
import 'package:ucb_app/pages/dashboard/stats/widgets/stat_card_widget.dart';

class StatsGrid extends StatelessWidget {
  final int totalInterventions;
  final int plannedInterventions;
  final int inProgressInterventions;
  final int completedInterventions;
  final int urgentInterventions;

  const StatsGrid({
    super.key,
    required this.totalInterventions,
    required this.plannedInterventions,
    required this.inProgressInterventions,
    required this.completedInterventions,
    required this.urgentInterventions,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 1,
      mainAxisSpacing: 1,
      padding: EdgeInsets.zero,
      children: [
        StatCardWidget(
          title: 'Total',
          value: totalInterventions.toString(),
          icon: Icons.assignment,
          color: AppTheme.primaryColor,
        ),
        StatCardWidget(
          title: 'Planifiées',
          value: plannedInterventions.toString(),
          icon: Icons.calendar_today,
          color: Colors.blue,
        ),
        StatCardWidget(
          title: 'En cours',
          value: inProgressInterventions.toString(),
          icon: Icons.schedule,
          color: Colors.orange,
        ),
        StatCardWidget(
          title: 'Terminées',
          value: completedInterventions.toString(),
          icon: Icons.check_circle,
          color: Colors.green,
        ),
        StatCardWidget(
          title: 'Urgentes',
          value: urgentInterventions.toString(),
          icon: Icons.warning,
          color: Colors.red,
        ),
        StatCardWidget(
          title: 'En attente',
          value: (totalInterventions - completedInterventions).toString(),
          icon: Icons.pending,
          color: Colors.purple,
        ),
      ],
    );
  }
}