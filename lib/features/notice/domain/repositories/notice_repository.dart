import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:sewa_web/core/errors/failures.dart';
import 'package:sewa_web/features/notice/domain/entities/notice_entity.dart';

/// Parameters for filtering notices
class GetNoticesParams {
  final String? serviceId;
  final String? status;
  final bool? isActive;
  final String? search;
  final String? ordering;
  final int page;
  final int pageSize;

  const GetNoticesParams({
    this.serviceId,
    this.status,
    this.isActive,
    this.search,
    this.ordering,
    this.page = 1,
    this.pageSize = 20,
  });
}

/// Parameters for uploading a notice
/// Backend automatically determines:
/// - For Ministry Admin: Attaches ministry info from auth context
/// - For Staff Admin: Attaches service info (staff is linked to service)
class UploadNoticeParams {
  final String title;
  final Uint8List fileBytes;
  final String fileName;

  const UploadNoticeParams({
    required this.title,
    required this.fileBytes,
    required this.fileName,
  });
}

/// Parameters for updating a notice
class UpdateNoticeParams {
  final String noticeId;
  final String? title;
  final String? serviceId;
  final bool? isActive;

  const UpdateNoticeParams({
    required this.noticeId,
    this.title,
    this.serviceId,
    this.isActive,
  });
}

/// Notice Repository Interface
abstract class NoticeRepository {
  /// Get paginated list of notices with optional filters
  Future<Either<Failure, NoticeListResponse>> getNotices(
    GetNoticesParams params,
  );

  /// Get a single notice by ID
  Future<Either<Failure, NoticeEntity>> getNoticeById(String noticeId);

  /// Upload a new notice
  Future<Either<Failure, NoticeEntity>> uploadNotice(UploadNoticeParams params);

  /// Update notice metadata
  Future<Either<Failure, NoticeEntity>> updateNotice(UpdateNoticeParams params);

  /// Delete (soft-delete) a notice
  Future<Either<Failure, void>> deleteNotice(String noticeId);

  /// Get notice statistics
  Future<Either<Failure, NoticeStatsEntity>> getStats();

  /// Retry failed ingestion
  Future<Either<Failure, void>> retryIngestion(String noticeId);

  /// Get available services for categorization
  Future<Either<Failure, List<NoticeServiceEntity>>> getServices();
}
