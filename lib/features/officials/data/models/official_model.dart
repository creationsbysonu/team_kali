import 'package:sewa_web/features/officials/domain/entities/official.dart';

/// Official Model - extends entity and adds JSON serialization
class OfficialModel extends Official {
  const OfficialModel({
    required super.id,
    required super.ministryId,
    required super.ministryName,
    required super.name,
    required super.role,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
  });

  /// Create model from JSON
  factory OfficialModel.fromJson(Map<String, dynamic> json) {
    return OfficialModel(
      id: json['id']?.toString() ?? '',
      ministryId: json['ministry']?.toString() ?? '',
      ministryName: json['ministry_name']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  /// Convert model to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ministry': ministryId,
      'name': name,
      'role': role,
      'is_active': isActive,
    };
  }

  /// Create model from entity
  factory OfficialModel.fromEntity(Official entity) {
    return OfficialModel(
      id: entity.id,
      ministryId: entity.ministryId,
      ministryName: entity.ministryName,
      name: entity.name,
      role: entity.role,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
