import 'package:sewa_web/features/staff/domain/entities/staff_member.dart';

/// StaffModel - matches backend spec exactly
class StaffModel extends StaffMember {
  const StaffModel({
    required super.id,
    required super.name,
    required super.email,
    required super.contact,
    super.imageUrl,
    required super.service,
    required super.serviceName,
    required super.ministryName,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
  });

  factory StaffModel.fromJson(Map<String, dynamic> json) {
    return StaffModel(
      id: json['id'].toString(),
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      contact: json['contact'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      service: json['service']?.toString() ?? '',
      serviceName: json['service_name'] as String? ?? '',
      ministryName: json['ministry_name'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'contact': contact,
      'image_url': imageUrl,
      'service': service,
      'service_name': serviceName,
      'ministry_name': ministryName,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory StaffModel.fromEntity(StaffMember entity) {
    return StaffModel(
      id: entity.id,
      name: entity.name,
      email: entity.email,
      contact: entity.contact,
      imageUrl: entity.imageUrl,
      service: entity.service,
      serviceName: entity.serviceName,
      ministryName: entity.ministryName,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
