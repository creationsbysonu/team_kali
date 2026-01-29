import 'package:sewa_web/features/ministry/domain/entities/staff_service_entity.dart';

/// StaffService Model - Data layer representation
/// Extends entity and adds JSON serialization
class StaffServiceModel extends StaffService {
  const StaffServiceModel({
    required super.id,
    required super.serviceName,
    super.serviceLogo,
    required super.staffName,
    super.staffImage,
    required super.email,
    required super.status,
    required super.createdAt,
    required super.updatedAt,
  });

  /// Create model from JSON (backend response)
  /// Backend sends: service_logo_url, staff_image_url (not service_logo, staff_image)
  factory StaffServiceModel.fromJson(Map<String, dynamic> json) {
    return StaffServiceModel(
      id: json['id']?.toString() ?? '',
      serviceName: json['service_name']?.toString() ?? '',
      // Backend sends "service_logo_url" (Cloudinary URL)
      serviceLogo: json['service_logo_url']?.toString(),
      staffName: json['staff_name']?.toString() ?? '',
      // Backend sends "staff_image_url" (Cloudinary URL)
      staffImage: json['staff_image_url']?.toString(),
      email: json['email']?.toString() ?? '',
      status: json['status']?.toString() ?? 'paused',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  /// Convert model to JSON (for API requests)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'service_name': serviceName,
      'service_logo': serviceLogo,
      'staff_name': staffName,
      'staff_image': staffImage,
      'email': email,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create model from entity
  factory StaffServiceModel.fromEntity(StaffService entity) {
    return StaffServiceModel(
      id: entity.id,
      serviceName: entity.serviceName,
      serviceLogo: entity.serviceLogo,
      staffName: entity.staffName,
      staffImage: entity.staffImage,
      email: entity.email,
      status: entity.status,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
