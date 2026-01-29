import 'package:sewa_sathi/features/notice/domain/entities/notice_entity.dart';

/// Model for Notice with JSON serialization.
class NoticeModel extends NoticeEntity {
  const NoticeModel({
    required super.id,
    required super.title,
    super.ministry,
    super.ministryName,
    super.ministrySlug,
    super.service,
    super.serviceName,
    super.serviceSlug,
    required super.fileUrl,
    required super.fileType,
    required super.createdAt,
  });

  factory NoticeModel.fromJson(Map<String, dynamic> json) {
    return NoticeModel(
      id: json['id'].toString(),
      title: json['title'],
      ministry: json['ministry']?.toString(),
      ministryName: json['ministry_name'],
      ministrySlug: json['ministry_slug'],
      service: json['service']?.toString(),
      serviceName: json['service_name'],
      serviceSlug: json['service_slug'],
      fileUrl: json['file_url'],
      fileType: json['file_type'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'ministry': ministry,
      'ministry_name': ministryName,
      'ministry_slug': ministrySlug,
      'service': service,
      'service_name': serviceName,
      'service_slug': serviceSlug,
      'file_url': fileUrl,
      'file_type': fileType,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory NoticeModel.fromEntity(NoticeEntity entity) {
    return NoticeModel(
      id: entity.id,
      title: entity.title,
      ministry: entity.ministry,
      ministryName: entity.ministryName,
      ministrySlug: entity.ministrySlug,
      service: entity.service,
      serviceName: entity.serviceName,
      serviceSlug: entity.serviceSlug,
      fileUrl: entity.fileUrl,
      fileType: entity.fileType,
      createdAt: entity.createdAt,
    );
  }
}
