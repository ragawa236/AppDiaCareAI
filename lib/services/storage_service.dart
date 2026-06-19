import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// Service that wraps Firebase Storage for profile photo management.
///
/// Storage path: `profile_photos/{uid}/avatar.jpg`
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  static const String _profilePhotosPath = 'profile_photos';

  /// Uploads a profile photo from [imageFile] to Firebase Storage.
  ///
  /// Returns the public download URL of the uploaded photo.
  /// Throws [Exception] on failure.
  Future<String> uploadProfilePhoto({
    required String uid,
    required XFile imageFile,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final ref = _storage.ref('$_profilePhotosPath/$uid/avatar.jpg');

      UploadTask uploadTask;

      if (kIsWeb) {
        // On web, use bytes
        final bytes = await imageFile.readAsBytes();
        final metadata = SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {'uid': uid, 'uploadedAt': DateTime.now().toIso8601String()},
        );
        uploadTask = ref.putData(bytes, metadata);
      } else {
        // On mobile/desktop, use file path
        final file = File(imageFile.path);
        final metadata = SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {'uid': uid, 'uploadedAt': DateTime.now().toIso8601String()},
        );
        uploadTask = ref.putFile(file, metadata);
      }

      // Listen to upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        if (onProgress != null) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        }
        debugPrint(
            'StorageService: Upload progress — ${(snapshot.bytesTransferred / snapshot.totalBytes * 100).toStringAsFixed(1)}%');
      });

      // Await completion
      final snapshot = await uploadTask;

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      debugPrint('StorageService: Upload complete — $downloadUrl');
      return downloadUrl;
    } on FirebaseException catch (e) {
      debugPrint('StorageService: FirebaseException [${e.code}] — ${e.message}');
      throw Exception('Gagal mengunggah foto: ${e.message}');
    } catch (e) {
      debugPrint('StorageService: Unexpected error — $e');
      throw Exception('Gagal mengunggah foto. Silakan coba lagi.');
    }
  }

  /// Deletes the profile photo for [uid] from Firebase Storage.
  /// Silently ignores errors if file does not exist.
  Future<void> deleteProfilePhoto(String uid) async {
    try {
      final ref = _storage.ref('$_profilePhotosPath/$uid/avatar.jpg');
      await ref.delete();
      debugPrint('StorageService: Profile photo deleted for UID: $uid');
    } on FirebaseException catch (e) {
      // 'object-not-found' is expected if user never uploaded a photo.
      if (e.code != 'object-not-found') {
        debugPrint('StorageService: Delete error [${e.code}] — ${e.message}');
      }
    } catch (e) {
      debugPrint('StorageService: Unexpected delete error — $e');
    }
  }

  /// Checks if a profile photo already exists in Storage for [uid].
  Future<bool> profilePhotoExists(String uid) async {
    try {
      final ref = _storage.ref('$_profilePhotosPath/$uid/avatar.jpg');
      await ref.getDownloadURL(); // Throws if not found
      return true;
    } catch (_) {
      return false;
    }
  }
}
