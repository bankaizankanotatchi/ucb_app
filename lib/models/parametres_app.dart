import 'package:hive/hive.dart';

part 'parametres_app.g.dart';

@HiveType(typeId: 10)
class ParametresApp extends HiveObject {
  @HiveField(0)
  String langue; // 'fr', 'en'

  @HiveField(1)
  bool notifications;

  @HiveField(2)
  bool gpsAuto;

  @HiveField(3)
  bool modeHorsLigne;

  @HiveField(4)
  String derniereSession; // ID du technicien connecté

  @HiveField(5)
  DateTime derniereSynchro;

  @HiveField(6)
  String? tokenNotification;

  ParametresApp({
    this.langue = 'fr',
    this.notifications = true,
    this.gpsAuto = true,
    this.modeHorsLigne = false,
    this.derniereSession = '',
    required this.derniereSynchro,
    this.tokenNotification,
  });

  factory ParametresApp.fromJson(Map<String, dynamic> json) {
    return ParametresApp(
      langue: json['langue'] ?? 'fr',
      notifications: json['notifications'] ?? true,
      gpsAuto: json['gps_auto'] ?? true,
      modeHorsLigne: json['mode_hors_ligne'] ?? false,
      derniereSession: json['derniere_session'] ?? '',
      derniereSynchro: json['derniere_synchro'] != null
          ? DateTime.parse(json['derniere_synchro'])
          : DateTime.now(),
      tokenNotification: json['token_notification'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'langue': langue,
      'notifications': notifications,
      'gps_auto': gpsAuto,
      'mode_hors_ligne': modeHorsLigne,
      'derniere_session': derniereSession,
      'derniere_synchro': derniereSynchro.toIso8601String(),
      'token_notification': tokenNotification,
    };
  }
}