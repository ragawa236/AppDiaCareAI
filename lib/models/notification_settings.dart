import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationSettingsModel {
  final bool dailyReminder;
  final bool medicineReminder;
  final bool glucoseReminder;
  final bool riskPredictionNotification;
  final String reminderTime;
  final DateTime updatedAt;

  NotificationSettingsModel({
    required this.dailyReminder,
    required this.medicineReminder,
    required this.glucoseReminder,
    required this.riskPredictionNotification,
    required this.reminderTime,
    required this.updatedAt,
  });

  factory NotificationSettingsModel.fromJson(Map<String, dynamic> json) {
    return NotificationSettingsModel(
      dailyReminder: json['dailyReminder'] as bool? ?? false,
      medicineReminder: json['medicineReminder'] as bool? ?? false,
      glucoseReminder: json['glucoseReminder'] as bool? ?? false,
      riskPredictionNotification: json['riskPredictionNotification'] as bool? ?? false,
      reminderTime: json['reminderTime'] as String? ?? '08:00',
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dailyReminder': dailyReminder,
      'medicineReminder': medicineReminder,
      'glucoseReminder': glucoseReminder,
      'riskPredictionNotification': riskPredictionNotification,
      'reminderTime': reminderTime,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory NotificationSettingsModel.defaultSettings() {
    return NotificationSettingsModel(
      dailyReminder: true,
      medicineReminder: false,
      glucoseReminder: false,
      riskPredictionNotification: true,
      reminderTime: '08:00',
      updatedAt: DateTime.now(),
    );
  }

  NotificationSettingsModel copyWith({
    bool? dailyReminder,
    bool? medicineReminder,
    bool? glucoseReminder,
    bool? riskPredictionNotification,
    String? reminderTime,
    DateTime? updatedAt,
  }) {
    return NotificationSettingsModel(
      dailyReminder: dailyReminder ?? this.dailyReminder,
      medicineReminder: medicineReminder ?? this.medicineReminder,
      glucoseReminder: glucoseReminder ?? this.glucoseReminder,
      riskPredictionNotification: riskPredictionNotification ?? this.riskPredictionNotification,
      reminderTime: reminderTime ?? this.reminderTime,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
