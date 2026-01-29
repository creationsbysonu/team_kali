import 'package:sewa_sathi/features/get_token/domain/entities/ministry_entity.dart';

/// Ministry model with JSON serialization.
class MinistryModel extends MinistryEntity {
  const MinistryModel({
    required super.id,
    required super.name,
    required super.slug,
    super.description,
    super.logoUrl,
    super.address,
    super.phone,
    super.servicesCount,
  });

  /// Create from JSON response.
  factory MinistryModel.fromJson(Map<String, dynamic> json) {
    return MinistryModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'],
      logoUrl: json['logo_url'],
      address: json['address'],
      phone: json['phone'],
      servicesCount: json['services_count'] ?? 0,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'logo_url': logoUrl,
      'address': address,
      'phone': phone,
      'services_count': servicesCount,
    };
  }

  /// Create from entity.
  factory MinistryModel.fromEntity(MinistryEntity entity) {
    return MinistryModel(
      id: entity.id,
      name: entity.name,
      slug: entity.slug,
      description: entity.description,
      logoUrl: entity.logoUrl,
      address: entity.address,
      phone: entity.phone,
      servicesCount: entity.servicesCount,
    );
  }
}
