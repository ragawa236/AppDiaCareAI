import 'package:cloud_firestore/cloud_firestore.dart';

class PrivacySettingsModel {
  final bool shareAnalytics;
  final bool shareDoctor;
  final bool storeHistory;
  final DateTime updatedAt;

  PrivacySettingsModel({
    required this.shareAnalytics,
    required this.shareDoctor,
    required this.storeHistory,
    required this.updatedAt,
  });

  factory PrivacySettingsModel.fromJson(Map<String, dynamic> json) {
    return PrivacySettingsModel(
      shareAnalytics: json['shareAnalytics'] as bool? ?? false,
      shareDoctor: json['shareDoctor'] as bool? ?? false,
      storeHistory: json['storeHistory'] as bool? ?? true,
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'shareAnalytics': shareAnalytics,
      'shareDoctor': shareDoctor,
      'storeHistory': storeHistory,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory PrivacySettingsModel.defaultSettings() {
    return PrivacySettingsModel(
      shareAnalytics: false,
      shareDoctor: false,
      storeHistory: true,
      updatedAt: DateTime.now(),
    );
  }

  PrivacySettingsModel copyWith({
    bool? shareAnalytics,
    bool? shareDoctor,
    bool? storeHistory,
    DateTime? updatedAt,
  }) {
    return PrivacySettingsModel(
      shareAnalytics: shareAnalytics ?? this.shareAnalytics,
      shareDoctor: shareDoctor ?? this.shareDoctor,
      storeHistory: storeHistory ?? this.storeHistory,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
