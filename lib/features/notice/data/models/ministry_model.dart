import 'package:sewa_sathi/features/notice/domain/entities/ministry_entity.dart';

/// Model for Ministry with JSON serialization.
class MinistryModel extends MinistryEntity {
  const MinistryModel({
    required super.id,
    required super.name,
    required super.slug,
    super.logoUrl,
    super.noticeCount,
  });

  factory MinistryModel.fromJson(Map<String, dynamic> json) {
    return MinistryModel(
      id: json['id'].toString(),
      name: json['name'],
      slug: json['slug'],
      logoUrl: json['logo_url'],
      noticeCount: json['notice_count'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'logo_url': logoUrl,
      'notice_count': noticeCount,
    };
  }

  factory MinistryModel.fromEntity(MinistryEntity entity) {
    return MinistryModel(
      id: entity.id,
      name: entity.name,
      slug: entity.slug,
      logoUrl: entity.logoUrl,
      noticeCount: entity.noticeCount,
    );
  }
}
