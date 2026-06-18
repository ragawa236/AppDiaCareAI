import 'package:cloud_firestore/cloud_firestore.dart';

class SupportRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Submit a new support ticket to 'support_tickets' collection.
  Future<void> submitTicket({
    required String userId,
    required String subject,
    required String message,
  }) async {
    try {
      await _firestore.collection('support_tickets').add({
        'userId': userId,
        'subject': subject,
        'message': message,
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Gagal mengirim laporan masalah: $e');
    }
  }
}
