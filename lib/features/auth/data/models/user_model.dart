import 'package:sewa_web/features/auth/domain/entities/user_entity.dart';

/// Place Context Model - matches login response
/// { "id": "uuid", "name": "string", "slug": "string" }
class PlaceContextModel extends PlaceContext {
  const PlaceContextModel({
    required super.id,
    required super.name,
    required super.slug,
  });

  factory PlaceContextModel.fromJson(Map<String, dynamic> json) {
    return PlaceContextModel(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'slug': slug};
  }
}

/// Ministry Context Model - matches login response
/// { "id": "uuid", "name": "string", "slug": "string" }
class MinistryContextModel extends MinistryContext {
  const MinistryContextModel({
    required super.id,
    required super.name,
    required super.slug,
  });

  factory MinistryContextModel.fromJson(Map<String, dynamic> json) {
    return MinistryContextModel(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'slug': slug};
  }
}

/// Service Context Model - matches login response
/// { "id": "uuid", "name": "string", "slug": "string" }
class ServiceContextModel extends ServiceContext {
  const ServiceContextModel({
    required super.id,
    required super.name,
    required super.slug,
  });

  factory ServiceContextModel.fromJson(Map<String, dynamic> json) {
    return ServiceContextModel(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'slug': slug};
  }
}

/// User Model - matches backend spec exactly
/// Fields: id, email, user_type, is_verified, is_active, created_at
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    required super.userType,
    super.isVerified,
    super.isActive,
    super.createdAt,
    super.place,
    super.ministry,
    super.service,
  });

  /// Parse user from API response
  /// Note: place, ministry, service come from login response data level,
  /// not from inside the user object
  factory UserModel.fromJson(Map<String, dynamic> json) {
    final userTypeStr = json['user_type'] as String? ?? 'citizen';
    final userType = UserType.fromString(userTypeStr);

    return UserModel(
      id: json['id'].toString(),
      email: json['email'] ?? '',
      userType: userType,
      isVerified: json['is_verified'] ?? false,
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  /// Parse complete login response which includes user + context
  /// Login response structure for super admin/ministry admin:
  /// {
  ///   "user": { User fields },
  ///   "tokens": { AuthTokens },
  ///   "place": { id, name, slug },      // for admin/staff
  ///   "ministry": { id, name, slug },   // for admin/staff
  ///   "service": { id, name, slug }     // for staff only
  /// }
  /// Login response structure for staff:
  /// {
  ///   "staff": { id, service_name, staff_name, email, status, ... },
  ///   "tokens": { AuthTokens },
  ///   "place": { id, name, slug },
  ///   "ministry": { id, name, slug }
  /// }
  /// Login response structure for ministry admin:
  /// {
  ///   "ministry": { id, name, slug, email, status, ... },
  ///   "tokens": { AuthTokens },
  ///   "place": { id, name, slug }
  /// }
  factory UserModel.fromLoginResponse(Map<String, dynamic> data) {
    // Check if it's a staff login, ministry admin login, or user login response
    Map<String, dynamic> userJson;
    UserType userType;

    if (data.containsKey('staff')) {
      // Staff login response
      final staffJson = data['staff'] as Map<String, dynamic>;
      userType = UserType.staff;

      userJson = {
        'id': staffJson['id'],
        'email': staffJson['email'] ?? '',
        'user_type': 'staff',
        'is_verified': true,
        'is_active': staffJson['status'] == 'active',
      };
    } else if (data.containsKey('ministry') && !data.containsKey('user')) {
      // Ministry admin login response (ministry object at top level, no user key)
      final ministryJson = data['ministry'] as Map<String, dynamic>;
      userType = UserType.admin;

      userJson = {
        'id': ministryJson['id'],
        'email': ministryJson['email'] ?? '',
        'user_type': 'admin',
        'is_verified': true,
        'is_active': ministryJson['status'] == 'active',
      };
    } else {
      // Super admin login response
      userJson = data['user'] as Map<String, dynamic>;
      final userTypeStr = userJson['user_type'] as String? ?? 'citizen';
      userType = UserType.fromString(userTypeStr);
    }

    // Parse context from data level (not inside user)
    PlaceContextModel? place;
    if (data['place'] != null) {
      place = PlaceContextModel.fromJson(data['place'] as Map<String, dynamic>);
    }

    MinistryContextModel? ministry;
    if (data['ministry'] != null) {
      ministry = MinistryContextModel.fromJson(
        data['ministry'] as Map<String, dynamic>,
      );
    }

    ServiceContextModel? service;
    if (data.containsKey('staff')) {
      // For staff login, create service context from staff data
      final staffJson = data['staff'] as Map<String, dynamic>;
      service = ServiceContextModel(
        id: staffJson['id'].toString(),
        name: staffJson['service_name'] ?? '',
        slug: (staffJson['service_name'] ?? '').toLowerCase().replaceAll(
          ' ',
          '-',
        ),
      );
    } else if (data['service'] != null) {
      service = ServiceContextModel.fromJson(
        data['service'] as Map<String, dynamic>,
      );
    }

    return UserModel(
      id: userJson['id'].toString(),
      email: userJson['email'] ?? '',
      userType: userType,
      isVerified: userJson['is_verified'] ?? false,
      isActive: userJson['is_active'] ?? true,
      createdAt: userJson['created_at'] != null
          ? DateTime.tryParse(userJson['created_at'])
          : null,
      place: place,
      ministry: ministry,
      service: service,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'user_type': userType.value,
      'is_verified': isVerified,
      'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  /// For local storage - includes context
  Map<String, dynamic> toStorageJson() {
    return {
      'id': id,
      'email': email,
      'user_type': userType.value,
      'is_verified': isVerified,
      'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (place != null) 'place': (place as PlaceContextModel).toJson(),
      if (ministry != null)
        'ministry': (ministry as MinistryContextModel).toJson(),
      if (service != null) 'service': (service as ServiceContextModel).toJson(),
    };
  }

  /// From local storage
  factory UserModel.fromStorageJson(Map<String, dynamic> json) {
    final userTypeStr = json['user_type'] as String? ?? 'citizen';
    final userType = UserType.fromString(userTypeStr);

    PlaceContextModel? place;
    if (json['place'] != null) {
      place = PlaceContextModel.fromJson(json['place'] as Map<String, dynamic>);
    }

    MinistryContextModel? ministry;
    if (json['ministry'] != null) {
      ministry = MinistryContextModel.fromJson(
        json['ministry'] as Map<String, dynamic>,
      );
    }

    ServiceContextModel? service;
    if (json['service'] != null) {
      service = ServiceContextModel.fromJson(
        json['service'] as Map<String, dynamic>,
      );
    }

    return UserModel(
      id: json['id'].toString(),
      email: json['email'] ?? '',
      userType: userType,
      isVerified: json['is_verified'] ?? false,
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      place: place,
      ministry: ministry,
      service: service,
    );
  }

  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      email: entity.email,
      userType: entity.userType,
      isVerified: entity.isVerified,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      place: entity.place,
      ministry: entity.ministry,
      service: entity.service,
    );
  }
}
