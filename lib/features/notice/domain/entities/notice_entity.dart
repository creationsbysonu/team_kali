import 'package:equatable/equatable.dart';

/// Ingestion status for RAG processing
enum IngestionStatus {
  pending('pending'),
  processing('processing'),
  completed('completed'),
  failed('failed');

  final String value;
  const IngestionStatus(this.value);

  static IngestionStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'pending':
        return IngestionStatus.pending;
      case 'processing':
        return IngestionStatus.processing;
      case 'completed':
        return IngestionStatus.completed;
      case 'failed':
        return IngestionStatus.failed;
      default:
        return IngestionStatus.pending;
    }
  }

  String get displayName {
    switch (this) {
      case IngestionStatus.pending:
        return 'Pending';
      case IngestionStatus.processing:
        return 'Processing';
      case IngestionStatus.completed:
        return 'Completed';
      case IngestionStatus.failed:
        return 'Failed';
    }
  }
}

/// Ministry info embedded in notice
class NoticeMinistryEntity extends Equatable {
  final String id;
  final String name;
  final String slug;
  final String? logoUrl;

  const NoticeMinistryEntity({
    required this.id,
    required this.name,
    required this.slug,
    this.logoUrl,
  });

  @override
  List<Object?> get props => [id, name, slug, logoUrl];
}

/// Service info embedded in notice
class NoticeServiceEntity extends Equatable {
  final String id;
  final String name;
  final String slug;

  const NoticeServiceEntity({
    required this.id,
    required this.name,
    required this.slug,
  });

  @override
  List<Object?> get props => [id, name, slug];
}

/// Notice Entity - Core domain model
class NoticeEntity extends Equatable {
  final String id;
  final String title;
  final NoticeMinistryEntity ministry;
  final NoticeServiceEntity? service;
  final String fileUrl;
  final String fileType;
  final String? createdByEmail;
  final bool isActive;
  final IngestionStatus ingestionStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NoticeEntity({
    required this.id,
    required this.title,
    required this.ministry,
    this.service,
    required this.fileUrl,
    required this.fileType,
    this.createdByEmail,
    this.isActive = true,
    this.ingestionStatus = IngestionStatus.pending,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    title,
    ministry,
    service,
    fileUrl,
    fileType,
    createdByEmail,
    isActive,
    ingestionStatus,
    createdAt,
    updatedAt,
  ];

  /// Get file extension for display
  String get fileExtension => fileType.toUpperCase();

  /// Check if notice is a PDF
  bool get isPdf => fileType.toLowerCase() == 'pdf';

  /// Check if notice is an image
  bool get isImage => ['png', 'jpg', 'jpeg'].contains(fileType.toLowerCase());

  /// Check if ingestion is in progress
  bool get isIngesting =>
      ingestionStatus == IngestionStatus.pending ||
      ingestionStatus == IngestionStatus.processing;

  /// Check if ingestion failed
  bool get hasIngestionFailed => ingestionStatus == IngestionStatus.failed;

  NoticeEntity copyWith({
    String? id,
    String? title,
    NoticeMinistryEntity? ministry,
    NoticeServiceEntity? service,
    String? fileUrl,
    String? fileType,
    String? createdByEmail,
    bool? isActive,
    IngestionStatus? ingestionStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NoticeEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      ministry: ministry ?? this.ministry,
      service: service ?? this.service,
      fileUrl: fileUrl ?? this.fileUrl,
      fileType: fileType ?? this.fileType,
      createdByEmail: createdByEmail ?? this.createdByEmail,
      isActive: isActive ?? this.isActive,
      ingestionStatus: ingestionStatus ?? this.ingestionStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Notice Statistics Entity
class NoticeStatsEntity extends Equatable {
  final int totalNotices;
  final int activeNotices;
  final int pendingIngestion;
  final int failedIngestion;
  final List<ServiceNoticeCount> byService;

  const NoticeStatsEntity({
    required this.totalNotices,
    required this.activeNotices,
    required this.pendingIngestion,
    required this.failedIngestion,
    required this.byService,
  });

  @override
  List<Object?> get props => [
    totalNotices,
    activeNotices,
    pendingIngestion,
    failedIngestion,
    byService,
  ];
}

/// Service notice count for statistics
class ServiceNoticeCount extends Equatable {
  final String? serviceId;
  final String? serviceName;
  final int count;

  const ServiceNoticeCount({
    this.serviceId,
    this.serviceName,
    required this.count,
  });

  @override
  List<Object?> get props => [serviceId, serviceName, count];
}

/// Paginated notice list response
class NoticeListResponse extends Equatable {
  final int count;
  final String? next;
  final String? previous;
  final List<NoticeEntity> results;

  const NoticeListResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  bool get hasMore => next != null;

  @override
  List<Object?> get props => [count, next, previous, results];
}
