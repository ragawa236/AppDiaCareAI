import 'package:flutter/foundation.dart';

@immutable
class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final String gender;
  final int age;
  final String createdAt;
  final String lastLogin;
  /// Firebase Storage download URL for the user's profile photo.
  final String photoUrl;
  /// FCM registration token for the current device.
  final String fcmToken;

  const UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.gender,
    required this.age,
    required this.createdAt,
    required this.lastLogin,
    this.photoUrl = '',
    this.fcmToken = '',
  });

  /// Factory constructor to create [UserModel] from a map.
  factory UserModel.fromJson(Map<dynamic, dynamic> json) {
    return UserModel(
      uid: json['uid']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      gender: json['gender']?.toString() ?? '',
      age: (json['age'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt']?.toString() ?? '',
      lastLogin: json['lastLogin']?.toString() ?? '',
      photoUrl: json['photoUrl']?.toString() ?? '',
      fcmToken: json['fcmToken']?.toString() ?? '',
    );
  }

  /// Convert [UserModel] to JSON map for database writes.
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'gender': gender,
      'age': age,
      'createdAt': createdAt,
      'lastLogin': lastLogin,
      'photoUrl': photoUrl,
      'fcmToken': fcmToken,
    };
  }

  /// Create an empty/initial instance of [UserModel].
  factory UserModel.empty() {
    return const UserModel(
      uid: '',
      fullName: '',
      email: '',
      gender: '',
      age: 0,
      createdAt: '',
      lastLogin: '',
      photoUrl: '',
      fcmToken: '',
    );
  }

  /// Creates a copy of this [UserModel] but with the given fields replaced with the new values.
  UserModel copyWith({
    String? uid,
    String? fullName,
    String? email,
    String? gender,
    int? age,
    String? createdAt,
    String? lastLogin,
    String? photoUrl,
    String? fcmToken,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      photoUrl: photoUrl ?? this.photoUrl,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, fullName: $fullName, email: $email, gender: $gender, age: $age, createdAt: $createdAt, lastLogin: $lastLogin, photoUrl: $photoUrl)';
  }
}

