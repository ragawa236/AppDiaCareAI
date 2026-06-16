import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // GoogleSignIn hanya digunakan di Android/iOS.
  // Di Web, kita pakai Firebase signInWithPopup langsung (tidak perlu clientId).
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Exposes the stream of active authentication state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Gets the current logged-in Firebase user, if any.
  User? get currentUser => _auth.currentUser;

  /// Creates a new user account with email and password.
  Future<UserCredential> signUp(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthService: signUp error [${e.code}] - ${e.message}');
      throw _parseAuthException(e);
    } catch (e) {
      throw Exception('Registrasi gagal. Silakan coba kembali.');
    }
  }

  /// Logs in a user using email and password.
  Future<UserCredential> signIn(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthService: signIn error [${e.code}] - ${e.message}');
      throw _parseAuthException(e);
    } catch (e) {
      throw Exception('Login gagal. Silakan coba kembali.');
    }
  }

  /// Logs in a user using Google Sign-In.
  /// - Di Web: menggunakan signInWithPopup (tidak memerlukan clientId terpisah).
  /// - Di Android/iOS: menggunakan GoogleSignIn package + credential.
  Future<UserCredential> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // ── WEB: Gunakan signInWithPopup via Firebase Auth langsung ──
        final googleProvider = GoogleAuthProvider();
        // Minta akses profil & email
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        return await _auth.signInWithPopup(googleProvider);
      } else {
        // ── ANDROID / iOS: Gunakan GoogleSignIn package ──
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          throw Exception('Login Google dibatalkan oleh pengguna.');
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        return await _auth.signInWithCredential(credential);
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthService: signInWithGoogle error [${e.code}] - ${e.message}');
      throw _parseAuthException(e);
    } catch (e) {
      if (e.toString().contains('Login Google dibatalkan')) {
        rethrow;
      }
      throw Exception('Login Google gagal. Silakan coba kembali.');
    }
  }

  /// Signs out the currently authenticated user from Firebase and Google.
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
    } catch (e) {
      throw Exception('Gagal melakukan logout: $e');
    }
  }

  /// Sends an account verification email.
  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } on FirebaseAuthException catch (e) {
      throw _parseAuthException(e);
    } catch (e) {
      throw Exception('Gagal mengirim email verifikasi.');
    }
  }

  /// Reloads the current user profile from Firebase to fetch updated states.
  Future<void> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
    } catch (e) {
      throw Exception('Gagal memuat ulang status pengguna.');
    }
  }

  /// Sends a password reset verification email.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _parseAuthException(e);
    } catch (e) {
      throw Exception('Gagal mengirim email reset password.');
    }
  }

  /// Formats Firebase Authentication errors to clean localized Indonesian messages.
  Exception _parseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return Exception('Email sudah terdaftar. Silakan gunakan email lain.');
      case 'invalid-email':
        return Exception('Format email tidak valid.');
      case 'weak-password':
        return Exception('Password terlalu lemah. Gunakan minimal 6 karakter.');
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return Exception('Email atau password salah.');
      case 'user-disabled':
        return Exception('Akun ini telah dinonaktifkan.');
      case 'too-many-requests':
        return Exception('Terlalu banyak percobaan masuk. Coba beberapa saat lagi.');
      default:
        return Exception(e.message ?? 'Terjadi kesalahan autentikasi.');
    }
  }
}
