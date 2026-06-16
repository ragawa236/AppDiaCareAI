import '../models/user_model.dart';
import '../models/health_record.dart';
import '../models/activity_log.dart';
import '../services/database_service.dart';
import '../utils/device_helper.dart';

class DatabaseRepository {
  final DatabaseService _dbService;

  DatabaseRepository({DatabaseService? dbService})
      : _dbService = dbService ?? DatabaseService();

  /// Listens to user profile data.
  Stream<UserModel?> getUserProfileStream(String uid) {
    return _dbService.getUserProfileStream(uid);
  }

  /// Updates user profile details.
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await _dbService.updateUserProfile(uid, data);
  }

  // ================= HEALTH RECORDS CRUD =================

  /// Creates a health record and logs the action.
  Future<void> addHealthRecord(String uid, HealthRecord record) async {
    await _dbService.createHealthRecord(uid, record);
    await logActivity(
      uid: uid,
      action: 'Tambah Data Kesehatan',
      description: 'Menambahkan metrik baru: Glukosa ${record.glucoseLevel} mg/dL, TD ${record.bloodPressure}.',
    );
  }

  /// Updates a health record and logs the action.
  Future<void> editHealthRecord(String uid, HealthRecord record) async {
    await _dbService.updateHealthRecord(uid, record);
    await logActivity(
      uid: uid,
      action: 'Ubah Data Kesehatan',
      description: 'Mengubah metrik kesehatan ID: ${record.recordId}.',
    );
  }

  /// Deletes a health record and logs the action.
  Future<void> removeHealthRecord(String uid, String recordId) async {
    await _dbService.deleteHealthRecord(uid, recordId);
    await logActivity(
      uid: uid,
      action: 'Hapus Data Kesehatan',
      description: 'Menghapus metrik kesehatan ID: $recordId.',
    );
  }

  /// Listens to the health records stream.
  Stream<List<HealthRecord>> getHealthHistoryStream(String uid) {
    return _dbService.getHealthRecordsStream(uid);
  }

  // ================= LOGS AND AUDITS =================

  /// Helper log activity that auto-fills device and platform.
  Future<void> logActivity({
    required String uid,
    required String action,
    required String description,
  }) async {
    final activityLog = ActivityLog(
      logId: '',
      action: action,
      description: description,
      device: DeviceHelper.deviceName,
      platform: DeviceHelper.platformName,
      timestamp: DateTime.now().toIso8601String(),
    );
    await _dbService.logActivity(uid, activityLog);
  }

  /// Listens to the activity logs.
  Stream<List<ActivityLog>> getActivityLogsStream(String uid) {
    return _dbService.getActivityLogsStream(uid);
  }
}
