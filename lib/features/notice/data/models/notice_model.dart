import 'package:sewa_web/features/notice/domain/entities/notice_entity.dart';

/// Ministry Model for Notice
class NoticeMinistryModel extends NoticeMinistryEntity {
  const NoticeMinistryModel({
    required super.id,
    required super.name,
    required super.slug,
    super.logoUrl,
  });

  factory NoticeMinistryModel.fromJson(Map<String, dynamic> json) {
    return NoticeMinistryModel(
      id: json['id'].toString(),
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      logoUrl: json['logo_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'slug': slug, 'logo_url': logoUrl};
  }
}

/// Service Model for Notice
class NoticeServiceModel extends NoticeServiceEntity {
  const NoticeServiceModel({
    required super.id,
    required super.name,
    required super.slug,
  });

  factory NoticeServiceModel.fromJson(Map<String, dynamic> json) {
    return NoticeServiceModel(
      id: json['id'].toString(),
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'slug': slug};
  }
}

/// Notice Model
class NoticeModel extends NoticeEntity {
  const NoticeModel({
    required super.id,
    required super.title,
    required NoticeMinistryModel super.ministry,
    NoticeServiceModel? super.service,
    required super.fileUrl,
    required super.fileType,
    super.createdByEmail,
    super.isActive,
    super.ingestionStatus,
    required super.createdAt,
    required super.updatedAt,
  });

  factory NoticeModel.fromJson(Map<String, dynamic> json) {
    // Handle ministry - could be a Map object or just an ID string
    NoticeMinistryModel ministry;
    final ministryData = json['ministry'];
    if (ministryData is Map<String, dynamic>) {
      ministry = NoticeMinistryModel.fromJson(ministryData);
    } else {
      // Ministry is just an ID string - create minimal model
      ministry = NoticeMinistryModel(
        id: ministryData?.toString() ?? '',
        name: '',
        slug: '',
      );
    }

    // Handle service - could be a Map object, just an ID string, or null
    NoticeServiceModel? service;
    final serviceData = json['service'];
    if (serviceData is Map<String, dynamic>) {
      service = NoticeServiceModel.fromJson(serviceData);
    } else if (serviceData != null) {
      // Service is just an ID string - create minimal model
      service = NoticeServiceModel(
        id: serviceData.toString(),
        name: '',
        slug: '',
      );
    }

    return NoticeModel(
      id: json['id'].toString(),
      title: json['title'] as String? ?? '',
      ministry: ministry,
      service: service,
      fileUrl: json['file_url'] as String? ?? '',
      fileType: json['file_type'] as String? ?? 'pdf',
      createdByEmail: json['created_by_email'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      ingestionStatus: IngestionStatus.fromString(
        json['ingestion_status'] as String?,
      ),
      createdAt: DateTime.parse(
        json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'ministry': (ministry as NoticeMinistryModel).toJson(),
      'service': service != null
          ? (service as NoticeServiceModel).toJson()
          : null,
      'file_url': fileUrl,
      'file_type': fileType,
      'created_by_email': createdByEmail,
      'is_active': isActive,
      'ingestion_status': ingestionStatus.value,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory NoticeModel.fromEntity(NoticeEntity entity) {
    return NoticeModel(
      id: entity.id,
      title: entity.title,
      ministry: NoticeMinistryModel(
        id: entity.ministry.id,
        name: entity.ministry.name,
        slug: entity.ministry.slug,
        logoUrl: entity.ministry.logoUrl,
      ),
      service: entity.service != null
          ? NoticeServiceModel(
              id: entity.service!.id,
              name: entity.service!.name,
              slug: entity.service!.slug,
            )
          : null,
      fileUrl: entity.fileUrl,
      fileType: entity.fileType,
      createdByEmail: entity.createdByEmail,
      isActive: entity.isActive,
      ingestionStatus: entity.ingestionStatus,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}

/// Service Notice Count Model
class ServiceNoticeCountModel extends ServiceNoticeCount {
  const ServiceNoticeCountModel({
    super.serviceId,
    super.serviceName,
    required super.count,
  });

  factory ServiceNoticeCountModel.fromJson(Map<String, dynamic> json) {
    return ServiceNoticeCountModel(
      serviceId: json['service__id']?.toString(),
      serviceName: json['service__name'] as String?,
      count: json['count'] as int? ?? 0,
    );
  }
}

/// Notice Stats Model
class NoticeStatsModel extends NoticeStatsEntity {
  const NoticeStatsModel({
    required super.totalNotices,
    required super.activeNotices,
    required super.pendingIngestion,
    required super.failedIngestion,
    required super.byService,
  });

  factory NoticeStatsModel.fromJson(Map<String, dynamic> json) {
    return NoticeStatsModel(
      totalNotices: json['total_notices'] as int? ?? 0,
      activeNotices: json['active_notices'] as int? ?? 0,
      pendingIngestion: json['pending_ingestion'] as int? ?? 0,
      failedIngestion: json['failed_ingestion'] as int? ?? 0,
      byService:
          (json['by_service'] as List<dynamic>?)
              ?.map(
                (e) =>
                    ServiceNoticeCountModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }
}

/// Notice List Response Model
class NoticeListResponseModel extends NoticeListResponse {
  const NoticeListResponseModel({
    required super.count,
    super.next,
    super.previous,
    required super.results,
  });

  factory NoticeListResponseModel.fromJson(Map<String, dynamic> json) {
    // Handle response format: could be paginated or direct list
    // Paginated: { "data": { "count": N, "results": [...] } } or { "count": N, "results": [...] }
    // Direct list: { "data": [...] } or { "success": true, "data": [...] }

    dynamic rawData = json['data'] ?? json;

    // If data is a list directly, wrap it
    if (rawData is List) {
      return NoticeListResponseModel(
        count: rawData.length,
        next: null,
        previous: null,
        results: rawData
            .map((e) => NoticeModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    }

    // Otherwise, it's a paginated response map
    final data = rawData as Map<String, dynamic>;
    return NoticeListResponseModel(
      count: data['count'] as int? ?? 0,
      next: data['next'] as String?,
      previous: data['previous'] as String?,
      results:
          (data['results'] as List<dynamic>?)
              ?.map((e) => NoticeModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
