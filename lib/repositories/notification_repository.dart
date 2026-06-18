import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_settings.dart';

class NotificationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetch notification settings.
  Future<NotificationSettingsModel?> getNotificationSettings(String uid) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('notification_settings')
          .doc('settings')
          .get();
      if (!doc.exists || doc.data() == null) return null;
      return NotificationSettingsModel.fromJson(doc.data()!);
    } catch (e) {
      throw Exception('Gagal memuat pengaturan notifikasi: $e');
    }
  }

  /// Listen to real-time notification settings.
  Stream<NotificationSettingsModel?> getNotificationSettingsStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('notification_settings')
        .doc('settings')
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return NotificationSettingsModel.fromJson(doc.data()!);
    });
  }

  /// Save notification settings.
  Future<void> saveNotificationSettings(String uid, NotificationSettingsModel settings) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('notification_settings')
          .doc('settings')
          .set(settings.toJson(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Gagal menyimpan pengaturan notifikasi: $e');
    }
  }
}
