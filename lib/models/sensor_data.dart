import 'package:flutter/foundation.dart';

@immutable
class SensorData {
  final double temperature;
  final double humidity;
  final double glucose;
  final String timestamp;

  const SensorData({
    required this.temperature,
    required this.humidity,
    required this.glucose,
    required this.timestamp,
  });

  /// Factory constructor to create [SensorData] from a JSON map.
  /// Handles numeric conversions safely (int/double).
  factory SensorData.fromJson(Map<dynamic, dynamic> json) {
    return SensorData(
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.0,
      humidity: (json['humidity'] as num?)?.toDouble() ?? 0.0,
      glucose: (json['glucose'] as num?)?.toDouble() ?? 0.0,
      timestamp: json['timestamp']?.toString() ?? '',
    );
  }

  /// Create an empty/initial instance of [SensorData].
  factory SensorData.initial() {
    return const SensorData(
      temperature: 0.0,
      humidity: 0.0,
      glucose: 0.0,
      timestamp: '',
    );
  }

  /// Convert [SensorData] to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'humidity': humidity,
      'glucose': glucose,
      'timestamp': timestamp,
    };
  }

  /// Creates a copy of this [SensorData] but with the given fields replaced with the new values.
  SensorData copyWith({
    double? temperature,
    double? humidity,
    double? glucose,
    String? timestamp,
  }) {
    return SensorData(
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      glucose: glucose ?? this.glucose,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Helper getter to determine glucose risk level.
  String get glucoseStatus {
    if (glucose == 0) return 'Tidak Ada Data';
    if (glucose < 70) return 'Rendah (Hipoglikemia)';
    if (glucose <= 140) return 'Normal (Optimal)';
    if (glucose <= 200) return 'Tinggi (Prediabetes)';
    return 'Sangat Tinggi (Diabetes)';
  }

  /// Check if values are within a safe range.
  bool get isTemperatureSafe => temperature >= 35.0 && temperature <= 37.5;
  bool get isHumiditySafe => humidity >= 30.0 && humidity <= 60.0;
  bool get isGlucoseSafe => glucose >= 70.0 && glucose <= 140.0;

  @override
  String toString() {
    return 'SensorData(temperature: $temperature, humidity: $humidity, glucose: $glucose, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is SensorData &&
      other.temperature == temperature &&
      other.humidity == humidity &&
      other.glucose == glucose &&
      other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return temperature.hashCode ^
      humidity.hashCode ^
      glucose.hashCode ^
      timestamp.hashCode;
  }
}
