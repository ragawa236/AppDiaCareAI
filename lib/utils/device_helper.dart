import 'package:flutter/foundation.dart';

class DeviceHelper {
  /// Detect operating platform.
  static String get platformName {
    if (kIsWeb) return 'Web Browser';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'Android';
      case TargetPlatform.iOS:
        return 'iOS';
      case TargetPlatform.windows:
        return 'Windows';
      case TargetPlatform.macOS:
        return 'macOS';
      case TargetPlatform.linux:
        return 'Linux';
      default:
        return 'Unknown';
    }
  }

  /// Returns a clean descriptive name for the hardware device.
  static String get deviceName {
    if (kIsWeb) return 'Browser Window';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'Android Device/Emulator';
      case TargetPlatform.iOS:
        return 'iPhone/iPad Simulator';
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
        return 'Personal Desktop Computer';
      default:
        return 'Mobile Device';
    }
  }
}
