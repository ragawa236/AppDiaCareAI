import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/privacy_settings.dart';

class PrivacyRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetch privacy settings once.
  Future<PrivacySettingsModel?> getPrivacySettings(String uid) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('privacy_settings')
          .doc('settings')
          .get();
      if (!doc.exists || doc.data() == null) return null;
      return PrivacySettingsModel.fromJson(doc.data()!);
    } catch (e) {
      throw Exception('Gagal memuat pengaturan privasi: $e');
    }
  }

  /// Listen to real-time privacy settings changes.
  Stream<PrivacySettingsModel?> getPrivacySettingsStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('privacy_settings')
        .doc('settings')
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return PrivacySettingsModel.fromJson(doc.data()!);
    });
  }

  /// Save privacy settings.
  Future<void> savePrivacySettings(String uid, PrivacySettingsModel settings) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('privacy_settings')
          .doc('settings')
          .set(settings.toJson(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Gagal menyimpan pengaturan privasi: $e');
    }
  }
}
