import 'package:flutter/foundation.dart';

@immutable
class ActivityLog {
  final String logId;
  final String action;
  final String description;
  final String device;
  final String platform;
  final String timestamp;

  const ActivityLog({
    required this.logId,
    required this.action,
    required this.description,
    required this.device,
    required this.platform,
    required this.timestamp,
  });

  /// Factory constructor to parse [ActivityLog] from map data.
  factory ActivityLog.fromJson(Map<dynamic, dynamic> json) {
    return ActivityLog(
      logId: json['logId']?.toString() ?? '',
      action: json['action']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      device: json['device']?.toString() ?? 'Unknown Device',
      platform: json['platform']?.toString() ?? 'Unknown Platform',
      timestamp: json['timestamp']?.toString() ?? '',
    );
  }

  /// Convert to JSON map for database writes.
  Map<String, dynamic> toJson() {
    return {
      'logId': logId,
      'action': action,
      'description': description,
      'device': device,
      'platform': platform,
      'timestamp': timestamp,
    };
  }
}
