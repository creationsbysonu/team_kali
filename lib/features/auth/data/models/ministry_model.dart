import 'package:sewa_web/features/auth/domain/entities/ministry.dart';

/// MinistryModel - matches backend spec exactly
class MinistryModel extends Ministry {
  MinistryModel({
    required super.id,
    super.placeId,
    super.placeName,
    super.placeSlug,
    required super.name,
    required super.slug,
    super.description,
    required super.email,
    super.phone,
    super.address,
    super.website,
    super.logoUrl,
    required super.status,
    super.memberCount,
    super.isDeleted,
    super.deletedAt,
    required super.createdAt,
    required super.updatedAt,
  });

  factory MinistryModel.fromJson(Map<String, dynamic> json) {
    return MinistryModel(
      id: json['id'].toString(),
      placeId: json['place_id']?.toString() ?? json['place']?.toString(),
      placeName: json['place_name'] as String?,
      placeSlug: json['place_slug'] as String?,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String?,
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      website: json['website'] as String?,
      logoUrl: json['logo_url'] as String?,
      status: json['status'] as String? ?? 'pending',
      memberCount: json['member_count'] as int? ?? 0,
      isDeleted: json['is_deleted'] as bool? ?? false,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
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
      'place_id': placeId,
      'place_name': placeName,
      'place_slug': placeSlug,
      'name': name,
      'slug': slug,
      'description': description,
      'email': email,
      'phone': phone,
      'address': address,
      'website': website,
      'logo_url': logoUrl,
      'status': status,
      'member_count': memberCount,
      'is_deleted': isDeleted,
      'deleted_at': deletedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory MinistryModel.fromEntity(Ministry entity) {
    return MinistryModel(
      id: entity.id,
      placeId: entity.placeId,
      placeName: entity.placeName,
      placeSlug: entity.placeSlug,
      name: entity.name,
      slug: entity.slug,
      description: entity.description,
      email: entity.email,
      phone: entity.phone,
      address: entity.address,
      website: entity.website,
      logoUrl: entity.logoUrl,
      status: entity.status,
      memberCount: entity.memberCount,
      isDeleted: entity.isDeleted,
      deletedAt: entity.deletedAt,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
