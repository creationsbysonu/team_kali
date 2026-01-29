import 'package:sewa_sathi/features/chat/domain/entities/source_entity.dart';

/// Model class for Source with JSON serialization.
/// Maps to backend response format with ministry and service information.
class SourceModel extends SourceEntity {
  const SourceModel({
    required super.noticeId,
    super.ministryName,
    super.serviceName,
    super.excerpt,
  });

  /// Create SourceModel from JSON response.
  ///
  /// Backend format:
  /// ```json
  /// {
  ///   "notice_id": "uuid-string",
  ///   "ministry_name": "Ministry of Foreign Affairs",
  ///   "service_name": "Passport Services",
  ///   "excerpt": "Required documents..."
  /// }
  /// ```
  factory SourceModel.fromJson(Map<String, dynamic> json) {
    return SourceModel(
      noticeId: json['notice_id']?.toString() ?? '',
      ministryName: json['ministry_name'] as String?,
      serviceName: json['service_name'] as String?,
      excerpt: json['excerpt'] as String?,
    );
  }

  /// Convert SourceModel to JSON.
  Map<String, dynamic> toJson() {
    return {
      'notice_id': noticeId,
      if (ministryName != null) 'ministry_name': ministryName,
      if (serviceName != null) 'service_name': serviceName,
      if (excerpt != null) 'excerpt': excerpt,
    };
  }

  /// Create SourceModel from entity.
  factory SourceModel.fromEntity(SourceEntity entity) {
    return SourceModel(
      noticeId: entity.noticeId,
      ministryName: entity.ministryName,
      serviceName: entity.serviceName,
      excerpt: entity.excerpt,
    );
  }
}
