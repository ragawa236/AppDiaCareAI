import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/health_record.dart';
import '../models/activity_log.dart';

class DatabaseService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  // Path constants
  static const String _usersNode = 'users';
  static const String _historyNode = 'health_history';
  static const String _logsNode = 'activity_logs';

  /// Save/create user profile node in RTDB.
  Future<void> createUserProfile(String uid, UserModel user) async {
    try {
      await _db.ref('$_usersNode/$uid').set(user.toJson());
      debugPrint('DatabaseService: User profile created for UID: $uid');
    } catch (e) {
      debugPrint('DatabaseService: createUserProfile error: $e');
      throw Exception('Gagal menyimpan profil pengguna.');
    }
  }

  /// Update individual fields in user profile.
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _db.ref('$_usersNode/$uid').update(data);
      debugPrint('DatabaseService: User profile updated for UID: $uid');
    } catch (e) {
      debugPrint('DatabaseService: updateUserProfile error: $e');
      throw Exception('Gagal memperbarui profil pengguna.');
    }
  }

  /// Fetch user profile once.
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final snapshot = await _db.ref('$_usersNode/$uid').get();
      if (!snapshot.exists || snapshot.value == null) return null;
      
      final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
      return UserModel.fromJson(data);
    } catch (e) {
      debugPrint('DatabaseService: getUserProfile error: $e');
      throw Exception('Gagal mengambil data profil.');
    }
  }

  /// Listen to user profile changes in real-time.
  Stream<UserModel?> getUserProfileStream(String uid) {
    return _db.ref('$_usersNode/$uid').onValue.map((event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists || snapshot.value == null) return null;
      
      final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
      return UserModel.fromJson(data);
    });
  }

  // ================= HEALTH RECORDS CRUD =================

  /// Add a new health record under users/$uid/health_history.
  Future<void> createHealthRecord(String uid, HealthRecord record) async {
    try {
      final ref = _db.ref('$_usersNode/$uid/$_historyNode').push();
      final recordWithId = record.copyWith(recordId: ref.key);
      await ref.set(recordWithId.toJson());
      debugPrint('DatabaseService: Health record added with ID: ${ref.key}');
    } catch (e) {
      debugPrint('DatabaseService: createHealthRecord error: $e');
      throw Exception('Gagal menambahkan catatan kesehatan.');
    }
  }

  /// Update an existing health record.
  Future<void> updateHealthRecord(String uid, HealthRecord record) async {
    try {
      await _db
          .ref('$_usersNode/$uid/$_historyNode/${record.recordId}')
          .update(record.toJson());
      debugPrint('DatabaseService: Health record updated: ${record.recordId}');
    } catch (e) {
      debugPrint('DatabaseService: updateHealthRecord error: $e');
      throw Exception('Gagal memperbarui catatan kesehatan.');
    }
  }

  /// Delete a health record.
  Future<void> deleteHealthRecord(String uid, String recordId) async {
    try {
      await _db.ref('$_usersNode/$uid/$_historyNode/$recordId').remove();
      debugPrint('DatabaseService: Health record deleted: $recordId');
    } catch (e) {
      debugPrint('DatabaseService: deleteHealthRecord error: $e');
      throw Exception('Gagal menghapus catatan kesehatan.');
    }
  }

  /// Real-time stream of health records sorted by timestamp descending.
  Stream<List<HealthRecord>> getHealthRecordsStream(String uid) {
    return _db.ref('$_usersNode/$uid/$_historyNode').onValue.map((event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists || snapshot.value == null) return [];

      final Map<dynamic, dynamic> recordsMap = snapshot.value as Map<dynamic, dynamic>;
      final List<HealthRecord> list = [];
      
      recordsMap.forEach((key, value) {
        if (value is Map) {
          list.add(HealthRecord.fromJson(value));
        }
      });

      // Sort by timestamp descending (newest first)
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    });
  }

  // ================= ACTIVITY LOGGING =================

  /// Log a user activity under users/$uid/activity_logs.
  Future<void> logActivity(String uid, ActivityLog log) async {
    try {
      final ref = _db.ref('$_usersNode/$uid/$_logsNode').push();
      final logWithId = ActivityLog(
        logId: ref.key ?? '',
        action: log.action,
        description: log.description,
        device: log.device,
        platform: log.platform,
        timestamp: DateTime.now().toIso8601String(),
      );
      await ref.set(logWithId.toJson());
    } catch (e) {
      debugPrint('DatabaseService: logActivity error: $e');
      // Non-fatal error, do not block main workflow if logging fails
    }
  }

  /// Stream of recent activity logs (limited to last 20 entries).
  Stream<List<ActivityLog>> getActivityLogsStream(String uid) {
    return _db
        .ref('$_usersNode/$uid/$_logsNode')
        .limitToLast(20)
        .onValue
        .map((event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists || snapshot.value == null) return [];

      final Map<dynamic, dynamic> logsMap = snapshot.value as Map<dynamic, dynamic>;
      final List<ActivityLog> list = [];

      logsMap.forEach((key, value) {
        if (value is Map) {
          list.add(ActivityLog.fromJson(value));
        }
      });

      // Sort newest first
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    });
  }
}
