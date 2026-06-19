import 'dart:async';
import 'package:flutter/material.dart';
import '../models/notification_settings.dart';
import '../repositories/notification_repository.dart';
import '../services/fcm_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationRepository _repository;
  
  NotificationSettingsModel? _settings;
  bool _isLoading = false;
  String? _errorMessage;
  String? _activeUid;
  StreamSubscription<NotificationSettingsModel?>? _settingsSubscription;

  NotificationProvider({NotificationRepository? repository})
      : _repository = repository ?? NotificationRepository();

  // Getters
  NotificationSettingsModel? get settings => _settings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void initialize(String uid) {
    if (_activeUid == uid) return;
    _activeUid = uid;
    _setLoading(true);

    _settingsSubscription?.cancel();
    _settingsSubscription = _repository.getNotificationSettingsStream(uid).listen((data) async {
      if (data == null) {
        // Create default settings if none exist
        _settings = NotificationSettingsModel.defaultSettings();
        await saveSettings(_settings!);
      } else {
        _settings = data;
        // Sync local scheduled notifications
        await FcmService.instance.updateScheduledNotifications(_settings!);
      }
      _setLoading(false);
      notifyListeners();
    }, onError: (err) {
      _errorMessage = err.toString();
      _setLoading(false);
      notifyListeners();
    });
  }

  void clear() {
    _activeUid = null;
    _settings = null;
    _settingsSubscription?.cancel();
    _settingsSubscription = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<bool> saveSettings(NotificationSettingsModel newSettings) async {
    if (_activeUid == null) return false;
    try {
      await _repository.saveNotificationSettings(
        _activeUid!, 
        newSettings.copyWith(updatedAt: DateTime.now()),
      );

      // Sync FCM topic subscriptions to match the new preferences.
      await FcmService.instance.syncTopics(
        dailyReminder: newSettings.dailyReminder,
        medicineReminder: newSettings.medicineReminder,
        glucoseReminder: newSettings.glucoseReminder,
        riskPrediction: newSettings.riskPredictionNotification,
      );

      // Sync local scheduled notifications
      await FcmService.instance.updateScheduledNotifications(newSettings);

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
