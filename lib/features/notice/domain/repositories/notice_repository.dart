import 'package:dartz/dartz.dart';
import 'package:sewa_sathi/core/errors/failures.dart';
import 'package:sewa_sathi/features/notice/domain/entities/filter_options_entity.dart';
import 'package:sewa_sathi/features/notice/domain/entities/notice_detail_entity.dart';
import 'package:sewa_sathi/features/notice/domain/entities/notice_list_response_entity.dart';

/// Abstract repository for notice operations.
abstract class NoticeRepository {
  /// Get paginated list of notices with optional filters.
  Future<Either<Failure, NoticeListResponseEntity>> getNotices({
    String? ministryId,
    String? serviceId,
    String? fileType,
    String? search,
    int limit = 20,
    int offset = 0,
  });

  /// Get detailed information about a specific notice.
  Future<Either<Failure, NoticeDetailEntity>> getNoticeDetail(String noticeId);

  /// Get filter options for ministries, services, and file types.
  Future<Either<Failure, FilterOptionsEntity>> getFilterOptions();
}
