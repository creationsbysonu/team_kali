import 'package:sewa_sathi/features/notice/data/models/ministry_model.dart';
import 'package:sewa_sathi/features/notice/domain/entities/service_entity.dart';

/// Model for Service with JSON serialization.
class ServiceModel extends ServiceEntity {
  const ServiceModel({
    required super.id,
    required super.name,
    required super.slug,
    super.shortDescription,
    super.ministry,
    super.ministryId,
    super.noticeCount,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'].toString(),
      name: json['name'],
      slug: json['slug'],
      shortDescription: json['short_description'],
      ministry: json['ministry'] != null && json['ministry'] is Map
          ? MinistryModel.fromJson(json['ministry'])
          : null,
      ministryId: json['ministry_id']?.toString(),
      noticeCount: json['notice_count'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'short_description': shortDescription,
      'ministry': ministry != null
          ? MinistryModel.fromEntity(ministry!).toJson()
          : null,
      'ministry_id': ministryId,
      'notice_count': noticeCount,
    };
  }

  factory ServiceModel.fromEntity(ServiceEntity entity) {
    return ServiceModel(
      id: entity.id,
      name: entity.name,
      slug: entity.slug,
      shortDescription: entity.shortDescription,
      ministry: entity.ministry,
      ministryId: entity.ministryId,
      noticeCount: entity.noticeCount,
    );
  }
}
