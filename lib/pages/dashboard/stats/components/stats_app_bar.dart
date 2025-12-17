import 'package:flutter/material.dart';
import 'package:ucb_app/constants/app_theme.dart';

class StatsAppBar extends StatelessWidget {
  final String selectedPeriod;
  final String periodLabel;
  final bool isCustomPeriod;
  final VoidCallback onResetPeriod;
  final Function(String) onPeriodSelected;

  const StatsAppBar({
    super.key,
    required this.selectedPeriod,
    required this.periodLabel,
    required this.isCustomPeriod,
    required this.onResetPeriod,
    required this.onPeriodSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: EdgeInsets.all(12),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor.withOpacity(0.1),
                AppTheme.secondaryColor.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isCustomPeriod ? Icons.date_range : Icons.calendar_today,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Période active',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      periodLabel,
                      style: TextStyle(
                        fontSize: 15,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (isCustomPeriod)
                IconButton(
                  icon: Icon(Icons.close, size: 20, color: AppTheme.primaryColor),
                  onPressed: onResetPeriod,
                  tooltip: 'Réinitialiser',
                ),
            ],
          ),
        ),
        
        // Sélecteur de période
        Container(
          height: 50,
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildPeriodButton('today', 'Aujourd\'hui'),
              _buildPeriodButton('week', 'Semaine'),
              _buildPeriodButton('month', 'Mois'),
              _buildPeriodButton('year', 'Année'),
              _buildPeriodButton('custom', 'Personnalisée'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodButton(String period, String label) {
    final isSelected = selectedPeriod == period;
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4),
      child: ElevatedButton(
        onPressed: () => onPeriodSelected(period),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? AppTheme.primaryColor : Colors.white,
          foregroundColor: isSelected ? Colors.white : AppTheme.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: isSelected ? AppTheme.primaryColor : AppTheme.greyMedium,
            ),
          ),
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        child: Text(label),
      ),
    );
  }
}