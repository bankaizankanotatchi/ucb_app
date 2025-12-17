import 'package:flutter/material.dart';
import 'package:ucb_app/constants/app_theme.dart';
import 'package:ucb_app/models/intervention.dart';

class RecentInterventionItemWidget extends StatelessWidget {
  final Intervention intervention;

  const RecentInterventionItemWidget({
    super.key,
    required this.intervention,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Planifiee':
        return Colors.blue;
      case 'En_cours':
        return Colors.orange;
      case 'Terminee':
        return Colors.green;
      case 'Urgent':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'Planifiee':
        return 'Planifiée';
      case 'En_cours':
        return 'En cours';
      case 'Terminee':
        return 'Terminée';
      case 'Urgent':
        return 'Urgent';
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: _getStatusColor(intervention.statut),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  intervention.code,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppTheme.primaryColor,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  intervention.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getStatusColor(intervention.statut).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getStatusLabel(intervention.statut),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _getStatusColor(intervention.statut),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.access_time, size: 12, color: AppTheme.textLight),
                    SizedBox(width: 4),
                    Text(
                      _formatDate(intervention.datePlanifiee),
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
        ],
      ),
    );
  }
}