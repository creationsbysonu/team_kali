import 'package:equatable/equatable.dart';

/// User types for role-based access control
/// Hierarchy: super_admin > admin (ministry) > staff > citizen
enum UserType {
  superAdmin('super_admin'),
  admin('admin'), // Ministry Admin
  staff('staff'),
  citizen('citizen');

  final String value;
  const UserType(this.value);

  static UserType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'super_admin':
        return UserType.superAdmin;
      case 'admin':
        return UserType.admin;
      case 'staff':
        return UserType.staff;
      case 'citizen':
        return UserType.citizen;
      default:
        return UserType.citizen;
    }
  }
}

/// Place context - returned in login response for admin/staff
/// Matches: { "id": "uuid", "name": "string", "slug": "string" }
class PlaceContext extends Equatable {
  final String id;
  final String name;
  final String slug;

  const PlaceContext({
    required this.id,
    required this.name,
    required this.slug,
  });

  @override
  List<Object?> get props => [id, name, slug];
}

/// Ministry context - returned in login response for admin/staff
/// Matches: { "id": "uuid", "name": "string", "slug": "string" }
class MinistryContext extends Equatable {
  final String id;
  final String name;
  final String slug;

  const MinistryContext({
    required this.id,
    required this.name,
    required this.slug,
  });

  @override
  List<Object?> get props => [id, name, slug];
}

/// Service context - returned in login response for staff
/// Matches: { "id": "uuid", "name": "string", "slug": "string" }
class ServiceContext extends Equatable {
  final String id;
  final String name;
  final String slug;

  const ServiceContext({
    required this.id,
    required this.name,
    required this.slug,
  });

  @override
  List<Object?> get props => [id, name, slug];
}

/// User Entity for Sewa Sathi System
/// Matches backend User model exactly:
/// - id (UUID)
/// - email (String)
/// - user_type (citizen/staff/admin/super_admin)
/// - is_verified (bool)
/// - is_active (bool)
/// - created_at (ISO8601)
class UserEntity extends Equatable {
  final String id;
  final String email;
  final UserType userType;
  final bool isVerified;
  final bool isActive;
  final DateTime? createdAt;

  // Context from login response (NOT inside user object)
  final PlaceContext? place;
  final MinistryContext? ministry;
  final ServiceContext? service;

  const UserEntity({
    required this.id,
    required this.email,
    required this.userType,
    this.isVerified = false,
    this.isActive = true,
    this.createdAt,
    this.place,
    this.ministry,
    this.service,
  });

  @override
  List<Object?> get props => [
    id,
    email,
    userType,
    isVerified,
    isActive,
    createdAt,
    place,
    ministry,
    service,
  ];

  /// Display name - uses email prefix
  String get displayName => email.split('@')[0];

  /// Full name alias for compatibility
  String? get fullName => null;

  /// Profile picture - not in backend spec, always null
  String? get profilePictureUrl => null;

  /// Check if user is super admin
  bool get isSuperAdmin => userType == UserType.superAdmin;

  /// Check if user is ministry admin
  bool get isAdmin => userType == UserType.admin;

  /// Check if user is staff
  bool get isStaff => userType == UserType.staff;

  /// Check if user is citizen
  bool get isCitizen => userType == UserType.citizen;

  UserEntity copyWith({
    String? id,
    String? email,
    UserType? userType,
    bool? isVerified,
    bool? isActive,
    DateTime? createdAt,
    PlaceContext? place,
    MinistryContext? ministry,
    ServiceContext? service,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      userType: userType ?? this.userType,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      place: place ?? this.place,
      ministry: ministry ?? this.ministry,
      service: service ?? this.service,
    );
  }
}
