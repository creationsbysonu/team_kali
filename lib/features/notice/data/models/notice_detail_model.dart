import 'package:sewa_sathi/features/notice/data/models/ministry_model.dart';
import 'package:sewa_sathi/features/notice/data/models/service_model.dart';
import 'package:sewa_sathi/features/notice/domain/entities/notice_detail_entity.dart';

/// Model for Notice Detail with JSON serialization.
class NoticeDetailModel extends NoticeDetailEntity {
  const NoticeDetailModel({
    required super.id,
    required super.title,
    super.ministry,
    super.service,
    required super.fileUrl,
    required super.fileType,
    super.ingestionStatus,
    required super.createdAt,
    required super.updatedAt,
  });

  factory NoticeDetailModel.fromJson(Map<String, dynamic> json) {
    return NoticeDetailModel(
      id: json['id'].toString(),
      title: json['title'],
      ministry: json['ministry'] != null
          ? MinistryModel.fromJson(json['ministry'])
          : null,
      service: json['service'] != null
          ? ServiceModel.fromJson(json['service'])
          : null,
      fileUrl: json['file_url'],
      fileType: json['file_type'],
      ingestionStatus: json['ingestion_status'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'ministry': ministry != null
          ? MinistryModel.fromEntity(ministry!).toJson()
          : null,
      'service': service != null
          ? ServiceModel.fromEntity(service!).toJson()
          : null,
      'file_url': fileUrl,
      'file_type': fileType,
      'ingestion_status': ingestionStatus,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory NoticeDetailModel.fromEntity(NoticeDetailEntity entity) {
    return NoticeDetailModel(
      id: entity.id,
      title: entity.title,
      ministry: entity.ministry,
      service: entity.service,
      fileUrl: entity.fileUrl,
      fileType: entity.fileType,
      ingestionStatus: entity.ingestionStatus,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
