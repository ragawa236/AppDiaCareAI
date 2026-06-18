import 'package:flutter/material.dart';
import '../repositories/support_repository.dart';

class SupportProvider extends ChangeNotifier {
  final SupportRepository _repository;

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  SupportProvider({SupportRepository? repository})
      : _repository = repository ?? SupportRepository();

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  Future<bool> submitTicket({
    required String userId,
    required String subject,
    required String message,
  }) async {
    if (subject.trim().isEmpty || message.trim().isEmpty) {
      _errorMessage = 'Subjek dan pesan tidak boleh kosong.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _repository.submitTicket(
        userId: userId,
        subject: subject.trim(),
        message: message.trim(),
      );
      _successMessage = 'Laporan masalah berhasil dikirim. Tim kami akan segera merespons.';
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
