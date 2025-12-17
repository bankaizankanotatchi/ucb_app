import 'package:flutter/material.dart';
import 'package:ucb_app/constants/app_theme.dart';
import 'package:ucb_app/models/technicien.dart';
import 'package:ucb_app/models/intervention.dart';
import 'package:ucb_app/pages/dashboard/stats/components/custom_date_range_dialog.dart';
import 'package:ucb_app/pages/dashboard/stats/components/stats_app_bar.dart';
import 'package:ucb_app/pages/dashboard/stats/components/stats_empty_state.dart';
import 'package:ucb_app/pages/dashboard/stats/components/stats_grid.dart';
import 'package:ucb_app/pages/dashboard/stats/components/stats_recent_interventions.dart';
import 'package:ucb_app/pages/dashboard/stats/components/stats_status_distribution.dart';
import 'package:ucb_app/services/hive_service.dart';

class StatsScreen extends StatefulWidget {
  final Technicien technicien;
  final List<Intervention> interventions;
  final String initialPeriod;
  final Function(String)? onPeriodChanged;

  const StatsScreen({
    super.key,
    required this.technicien,
    required this.interventions,
    this.initialPeriod = 'month',
    this.onPeriodChanged,
  });

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late String _selectedPeriod;
  List<Intervention> _filteredInterventions = [];
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  @override
  void initState() {
    super.initState();
    _selectedPeriod = widget.initialPeriod;
    _loadInterventions();
  }
void _loadInterventions() {
  _applyPeriodFilter(_selectedPeriod);
}


void _applyPeriodFilter(String period) {
  final interventions = widget.interventions;

  if (period == 'custom') {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showCustomDateRangeDialog();
    });
    return;
  }

  final now = DateTime.now();
  DateTime startDate;
  DateTime endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);

  switch (period) {
    case 'today':
      startDate = DateTime(now.year, now.month, now.day);
      break;
    case 'week':
      startDate = now.subtract(Duration(days: now.weekday - 1));
      startDate = DateTime(startDate.year, startDate.month, startDate.day);
      break;
    case 'month':
      startDate = DateTime(now.year, now.month, 1);
      break;
    case 'year':
      startDate = DateTime(now.year, 1, 1);
      break;
    default:
      startDate = DateTime(now.year, now.month, 1);
  }

  final filtered = interventions.where((intervention) {
    final date = intervention.datePlanifiee;
    return date.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
           date.isBefore(endDate.add(const Duration(seconds: 1)));
  }).toList();

  setState(() {
    _selectedPeriod = period;
    _filteredInterventions = filtered;
  });

  widget.onPeriodChanged?.call(period);
}

  void _showCustomDateRangeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CustomDateRangeDialog(
        initialStartDate: _customStartDate,
        initialEndDate: _customEndDate,
        onDateRangeApplied: _applyCustomDateRange,
      ),
    );
  }

  void _applyCustomDateRange(DateTime startDate, DateTime endDate) {
    setState(() {
      _customStartDate = startDate;
      _customEndDate = endDate;
      _selectedPeriod = 'custom';
    });

    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    final filtered = widget.interventions.where((intervention) {
      final interventionDate = intervention.datePlanifiee;
      return interventionDate.isAfter(start.subtract(const Duration(seconds: 1))) &&
             interventionDate.isBefore(end.add(const Duration(seconds: 1)));
    }).toList();

    setState(() {
      _filteredInterventions = filtered;
    });

    widget.onPeriodChanged?.call('custom');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Période: ${_formatDate(startDate)} - ${_formatDate(endDate)} (${filtered.length} interventions)',
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
  }

  String _getPeriodLabel() {
    switch (_selectedPeriod) {
      case 'today':
        return 'Aujourd\'hui';
      case 'week':
        return 'Cette semaine';
      case 'month':
        return 'Ce mois';
      case 'year':
        return 'Cette année';
      case 'custom':
        if (_customStartDate != null && _customEndDate != null) {
          return '${_formatDate(_customStartDate!)} - ${_formatDate(_customEndDate!)}';
        }
        return 'Période personnalisée';
      default:
        return 'Ce mois';
    }
  }

  // Méthodes de calcul des statistiques
  int _getTotalInterventions() => _filteredInterventions.length;

  int _getInterventionsByStatus(String status) {
    return _filteredInterventions.where((intervention) => _normalizeStatus(intervention.statut) == status).length;
  }

  String _normalizeStatus(String status) {
    switch (status) {
      case 'Planifiee':
        return 'Planifiée';
      case 'En_cours':
        return 'En cours';
      case 'Terminee':
        return 'Terminée';
      default:
        return status;
    }
  }

  int _getUrgentInterventions() {
    return _filteredInterventions.where((intervention) => intervention.priorite == 1).length;
  }

  void _resetToDefaultPeriod() {
    setState(() {
      _selectedPeriod = 'month';
      _customStartDate = null;
      _customEndDate = null;
    });
    _loadInterventions();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.greyLight,
      body: Column(
        children: [
          StatsAppBar(
            selectedPeriod: _selectedPeriod,
            periodLabel: _getPeriodLabel(),
            isCustomPeriod: _selectedPeriod == 'custom',
            onResetPeriod: _resetToDefaultPeriod,
            onPeriodSelected: _applyPeriodFilter,
          ),

          Expanded(
            child: _filteredInterventions.isEmpty
                ? StatsEmptyState(onResetPeriod: _resetToDefaultPeriod)
                : ListView(
                    padding: EdgeInsets.only(left: 8, right: 8, bottom: 8, top: 0),
                    children: [
                      StatsGrid(
                        totalInterventions: _getTotalInterventions(),
                        plannedInterventions: _getInterventionsByStatus('Planifiée'),
                        inProgressInterventions: _getInterventionsByStatus('En cours'),
                        completedInterventions: _getInterventionsByStatus('Terminée'),
                        urgentInterventions: _getUrgentInterventions(),
                      ),
                      SizedBox(height: 20),
                      StatsStatusDistribution(
                        plannedInterventions: _getInterventionsByStatus('Planifiée'),
                        inProgressInterventions: _getInterventionsByStatus('En cours'),
                        completedInterventions: _getInterventionsByStatus('Terminée'),
                        totalInterventions: _getTotalInterventions(),
                      ),
                      SizedBox(height: 20),
                      StatsRecentInterventions(
                        recentInterventions: List<Intervention>.from(_filteredInterventions)
                          ..sort((a, b) => b.datePlanifiee.compareTo(a.datePlanifiee))
                          ..take(5).toList(),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}