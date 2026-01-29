import 'package:sewa_sathi/features/auth/domain/entities/user_entity.dart';

/// Model class for User with JSON serialization.
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    required super.userType,
    required super.isVerified,
    required super.createdAt,
  });

  /// Create UserModel from JSON response.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      email: json['email'] ?? '',
      userType: json['user_type'] ?? 'citizen',
      isVerified: json['is_verified'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  /// Convert to JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'user_type': userType,
      'is_verified': isVerified,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create UserModel from UserEntity.
  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      email: entity.email,
      userType: entity.userType,
      isVerified: entity.isVerified,
      createdAt: entity.createdAt,
    );
  }
}
