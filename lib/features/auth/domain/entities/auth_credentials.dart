import 'package:equatable/equatable.dart';

/// Login type based on user role
enum LoginType {
  superAdmin, // Email + Password only
  admin, // Email + Password + place_slug + ministry_slug
  staff, // Email + Password + place_slug + ministry_slug + service_slug
}

class AuthCredentials extends Equatable {
  final String email;
  final String password;
  final String? placeSlug; // For admin & staff login
  final String? ministrySlug; // For admin & staff login
  final String? serviceSlug; // For staff login only

  const AuthCredentials({
    required this.email,
    required this.password,
    this.placeSlug,
    this.ministrySlug,
    this.serviceSlug,
  });

  @override
  List<Object?> get props => [
    email,
    password,
    placeSlug,
    ministrySlug,
    serviceSlug,
  ];

  /// Determine login type based on provided slugs
  LoginType get loginType {
    if (serviceSlug != null && serviceSlug!.isNotEmpty) {
      return LoginType.staff;
    } else if (ministrySlug != null && ministrySlug!.isNotEmpty) {
      return LoginType.admin;
    }
    return LoginType.superAdmin;
  }

  /// Check if this is a super admin login
  bool get isSuperAdminLogin => loginType == LoginType.superAdmin;

  /// Check if this is a ministry admin login
  bool get isAdminLogin => loginType == LoginType.admin;

  /// Check if this is a staff login
  bool get isStaffLogin => loginType == LoginType.staff;

  bool get hasValidEmail => email.contains('@') && email.contains('.');
  bool get hasValidPassword => password.isNotEmpty && password.length >= 6;

  AuthCredentials copyWith({
    String? email,
    String? password,
    String? placeSlug,
    String? ministrySlug,
    String? serviceSlug,
  }) {
    return AuthCredentials(
      email: email ?? this.email,
      password: password ?? this.password,
      placeSlug: placeSlug ?? this.placeSlug,
      ministrySlug: ministrySlug ?? this.ministrySlug,
      serviceSlug: serviceSlug ?? this.serviceSlug,
    );
  }
}
