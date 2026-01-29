import 'package:equatable/equatable.dart';

/// User entity representing the authenticated user.
class UserEntity extends Equatable {
  final String id;
  final String email;
  final String userType;
  final bool isVerified;
  final DateTime createdAt;

  const UserEntity({
    required this.id,
    required this.email,
    required this.userType,
    required this.isVerified,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, email, userType, isVerified, createdAt];

  UserEntity copyWith({
    String? id,
    String? email,
    String? userType,
    bool? isVerified,
    DateTime? createdAt,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      userType: userType ?? this.userType,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
