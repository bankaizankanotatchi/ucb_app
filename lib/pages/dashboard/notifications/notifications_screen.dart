import 'package:flutter/material.dart';
import 'package:ucb_app/constants/app_theme.dart';
import 'package:ucb_app/models/notification.dart' as notif_model;
import 'package:ucb_app/models/technicien.dart';
import 'package:ucb_app/pages/dashboard/notifications/components/empty_notifications.dart';
import 'package:ucb_app/pages/dashboard/notifications/components/notification_card.dart';
import 'package:ucb_app/pages/dashboard/notifications/components/notifications_app_bar.dart';
import 'package:ucb_app/services/hive_service.dart';

class NotificationsScreen extends StatefulWidget {
  final Technicien technicien;

  const NotificationsScreen({super.key, required this.technicien});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<notif_model.NotificationTech> _notifications = [];
  bool _isLoading = true;
  String _selectedFilter = 'Toutes';
  bool _showUnreadOnly = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() {
    setState(() {
      _isLoading = true;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      final allNotifications = HiveService.getAllNotifications();
      
      setState(() {
        _notifications = allNotifications;
        _isLoading = false;
      });
    });
  }

  // Utilisation des nouvelles méthodes Hive
  List<notif_model.NotificationTech> get _unreadNotifications {
    return HiveService.getNotificationsNonLues();
  }

  List<notif_model.NotificationTech> get _todayNotifications {
    return HiveService.getNotificationsDuJour();
  }

  int _getInterventionNotificationsCount() {
    return HiveService.getNotificationsCountByType('Intervention');
  }

  int _getUrgentNotificationsCount() {
    return HiveService.getNotificationsCountByType('Urgent');
  }

  int _getSystemNotificationsCount() {
    return HiveService.getNotificationsCountByType('System');
  }

  void _markAllAsRead() async {
    if (_unreadNotifications.isEmpty) return;

    for (var notification in _unreadNotifications) {
      await HiveService.markNotificationAsRead(notification.id);
    }

    _loadNotifications();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('${_unreadNotifications.length} notification(s) marquée(s) comme lue(s)'),
          ],
        ),
        backgroundColor: AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _deleteAllRead() async {
    final readNotifications = _notifications.where((n) => n.lue).toList();
    
    if (readNotifications.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Aucune notification lue à supprimer'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.red),
            SizedBox(width: 12),
            Text('Supprimer les notifications'),
          ],
        ),
        content: Text('Voulez-vous supprimer ${readNotifications.length} notification(s) lue(s) ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: TextStyle(color: AppTheme.textLight)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // TODO: Implémenter la suppression des notifications
              // Pour l'instant, on simule
              await Future.delayed(Duration(milliseconds: 500));
              
              _loadNotifications();
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text('${readNotifications.length} notification(s) supprimée(s)'),
                    ],
                  ),
                  backgroundColor: AppTheme.primaryColor,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _onNotificationTap(notif_model.NotificationTech notification) async {
    // Marquer comme lue
    if (!notification.lue) {
      await HiveService.markNotificationAsRead(notification.id);
      _loadNotifications();
    }

    // Navigation selon le type de notification
    switch (notification.type) {
      case 'Intervention':
        // TODO: Naviguer vers l'intervention
        break;
      case 'Urgent':
        // TODO: Naviguer vers l'intervention urgente
        break;
      case 'System':
        // TODO: Afficher les détails système
        break;
      default:
        // Afficher les détails de la notification
        _showNotificationDetails(notification);
    }
  }

  void _showNotificationDetails(notif_model.NotificationTech notification) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => NotificationDetailsSheet(notification: notification),
    );
  }

  void _updateFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
  }

  void _toggleUnreadOnly() {
    setState(() {
      _showUnreadOnly = !_showUnreadOnly;
    });
  }

  List<notif_model.NotificationTech> get _filteredNotifications {
    var filtered = _notifications;

    // Filtre par type
    if (_selectedFilter != 'Toutes') {
      filtered = filtered.where((n) => n.type == _selectedFilter).toList();
    }

    // Filtre non lues seulement
    if (_showUnreadOnly) {
      filtered = filtered.where((n) => !n.lue).toList();
    }

    // Trier par date (les plus récentes en premier)
    filtered.sort((a, b) => b.date.compareTo(a.date));

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    // Calcul des vraies valeurs avec les nouvelles méthodes
    final todayCount = _todayNotifications.length;
    final totalCount = _notifications.length;
    final unreadCount = _unreadNotifications.length;
    final interventionCount = _getInterventionNotificationsCount();
    final urgentCount = _getUrgentNotificationsCount();
    final systemCount = _getSystemNotificationsCount();

    return Scaffold(
      backgroundColor: AppTheme.greyLight,
      body: Column(
        children: [
          // AppBar personnalisé avec les vraies valeurs
          NotificationsAppBar(
            unreadCount: unreadCount,
            todayCount: todayCount, // Ajoutez ce paramètre
            totalCount: totalCount, // Ajoutez ce paramètre
            interventionCount: interventionCount, // Ajoutez ce paramètre
            urgentCount: urgentCount, // Ajoutez ce paramètre
            systemCount: systemCount, // Ajoutez ce paramètre
            onFilterChanged: _updateFilter,
            selectedFilter: _selectedFilter,
            showUnreadOnly: _showUnreadOnly,
            onToggleUnreadOnly: _toggleUnreadOnly,
            onMarkAllAsRead: _markAllAsRead,
            onDeleteAllRead: _deleteAllRead,
          ),

          // Indicateurs rapides
          if (_isLoading)
            Expanded(
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              ),
            )
          else if (_filteredNotifications.isEmpty)
            Expanded(
              child: EmptyNotifications(
                showUnreadOnly: _showUnreadOnly,
                selectedFilter: _selectedFilter,
                onResetFilters: () {
                  setState(() {
                    _selectedFilter = 'Toutes';
                    _showUnreadOnly = false;
                  });
                },
              ),
            )
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  _loadNotifications();
                },
                color: AppTheme.primaryColor,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  itemCount: _filteredNotifications.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final notification = _filteredNotifications[index];
                    return NotificationCard(
                      notification: notification,
                      onTap: () => _onNotificationTap(notification),
                      onLongPress: () => _showNotificationDetails(notification),
                    );
                  },
                ),
              ),
            ),
        ],
      ),


    );
  }
}

// Widget pour les détails de la notification
class NotificationDetailsSheet extends StatelessWidget {
  final notif_model.NotificationTech notification;

  const NotificationDetailsSheet({super.key, required this.notification});

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return 'À l\'instant';
    if (difference.inHours < 1) return 'Il y a ${difference.inMinutes} min';
    if (difference.inDays < 1) return 'Il y a ${difference.inHours} h';
    if (difference.inDays == 1) return 'Hier';
    if (difference.inDays < 7) return 'Il y a ${difference.inDays} jours';
    
    return '${date.day}/${date.month}/${date.year}';
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'Intervention':
        return Icons.assignment;
      case 'Urgent':
        return Icons.warning;
      case 'System':
        return Icons.settings;
      default:
        return Icons.notifications;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Intervention':
        return Colors.blue;
      case 'Urgent':
        return Colors.red;
      case 'System':
        return Colors.orange;
      default:
        return AppTheme.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Poignée de tirage
          Container(
            margin: EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // En-tête
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getTypeColor(notification.type).withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _getTypeColor(notification.type).withOpacity(0.3),
                    ),
                  ),
                  child: Icon(
                    _getTypeIcon(notification.type),
                    color: _getTypeColor(notification.type),
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.titre,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: AppTheme.textLight,
                          ),
                          SizedBox(width: 4),
                          Text(
                            _formatDate(notification.date),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textLight,
                            ),
                          ),
                          SizedBox(width: 12),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getTypeColor(notification.type).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              notification.type,
                              style: TextStyle(
                                fontSize: 12,
                                color: _getTypeColor(notification.type),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Séparateur
          Divider(thickness: 1, height: 20),

          // Contenu
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Message',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textLight,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  notification.message,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textDark,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // TODO: Supprimer cette notification
                    },
                    icon: Icon(Icons.delete_outline, size: 18),
                    label: Text('Supprimer'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // TODO: Action selon le type de notification
                    },
                    icon: notification.type == 'Intervention' 
                        ? Icon(Icons.visibility, size: 18)
                        : Icon(Icons.check, size: 18),
                    label: Text(
                      notification.type == 'Intervention' 
                          ? 'Voir l\'intervention'
                          : 'Marquer comme traité',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}