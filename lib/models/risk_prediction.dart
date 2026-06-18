class RiskPredictionModel {
  final String predictionId;
  final double riskPercentage;
  final double metabolicScore;
  final String riskLevel;
  final String timestamp;
  final double age;
  final double bmi;
  final double hba1c;
  final double glucose;
  final String gender;
  final bool hypertension;
  final bool heartDisease;
  final String smokingHistory;

  RiskPredictionModel({
    required this.predictionId,
    required this.riskPercentage,
    required this.metabolicScore,
    required this.riskLevel,
    required this.timestamp,
    required this.age,
    required this.bmi,
    required this.hba1c,
    required this.glucose,
    required this.gender,
    required this.hypertension,
    required this.heartDisease,
    required this.smokingHistory,
  });

  factory RiskPredictionModel.fromJson(Map<dynamic, dynamic> json) {
    return RiskPredictionModel(
      predictionId: json['predictionId']?.toString() ?? '',
      riskPercentage: (json['riskPercentage'] as num?)?.toDouble() ?? 0.0,
      metabolicScore: (json['metabolicScore'] as num?)?.toDouble() ?? 100.0,
      riskLevel: json['riskLevel']?.toString() ?? '',
      timestamp: json['timestamp']?.toString() ?? '',
      age: (json['age'] as num?)?.toDouble() ?? 0.0,
      bmi: (json['bmi'] as num?)?.toDouble() ?? 0.0,
      hba1c: (json['hba1c'] as num?)?.toDouble() ?? 0.0,
      glucose: (json['glucose'] as num?)?.toDouble() ?? 0.0,
      gender: json['gender']?.toString() ?? '',
      hypertension: json['hypertension'] as bool? ?? false,
      heartDisease: json['heartDisease'] as bool? ?? false,
      smokingHistory: json['smokingHistory']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'predictionId': predictionId,
      'riskPercentage': riskPercentage,
      'metabolicScore': metabolicScore,
      'riskLevel': riskLevel,
      'timestamp': timestamp,
      'age': age,
      'bmi': bmi,
      'hba1c': hba1c,
      'glucose': glucose,
      'gender': gender,
      'hypertension': hypertension,
      'heartDisease': heartDisease,
      'smokingHistory': smokingHistory,
    };
  }
}
