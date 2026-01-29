import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:sewa_sathi/core/errors/failures.dart';
import 'package:sewa_sathi/core/usecases/usecase.dart';
import 'package:sewa_sathi/features/notice/domain/entities/notice_list_response_entity.dart';
import 'package:sewa_sathi/features/notice/domain/repositories/notice_repository.dart';

/// Use case to get list of notices with filters and pagination.
class GetNoticesUseCase
    implements UseCase<NoticeListResponseEntity, NoticeParams> {
  final NoticeRepository repository;

  GetNoticesUseCase(this.repository);

  @override
  Future<Either<Failure, NoticeListResponseEntity>> call(
    NoticeParams params,
  ) async {
    return repository.getNotices(
      ministryId: params.ministryId,
      serviceId: params.serviceId,
      fileType: params.fileType,
      search: params.search,
      limit: params.limit,
      offset: params.offset,
    );
  }
}

/// Parameters for getting notices.
class NoticeParams extends Equatable {
  final String? ministryId;
  final String? serviceId;
  final String? fileType;
  final String? search;
  final int limit;
  final int offset;

  const NoticeParams({
    this.ministryId,
    this.serviceId,
    this.fileType,
    this.search,
    this.limit = 20,
    this.offset = 0,
  });

  NoticeParams copyWith({
    String? ministryId,
    String? serviceId,
    String? fileType,
    String? search,
    int? limit,
    int? offset,
    bool clearMinistry = false,
    bool clearService = false,
    bool clearFileType = false,
    bool clearSearch = false,
  }) {
    return NoticeParams(
      ministryId: clearMinistry ? null : (ministryId ?? this.ministryId),
      serviceId: clearService ? null : (serviceId ?? this.serviceId),
      fileType: clearFileType ? null : (fileType ?? this.fileType),
      search: clearSearch ? null : (search ?? this.search),
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }

  bool get hasFilters =>
      ministryId != null ||
      serviceId != null ||
      fileType != null ||
      (search != null && search!.isNotEmpty);

  @override
  List<Object?> get props => [
    ministryId,
    serviceId,
    fileType,
    search,
    limit,
    offset,
  ];
}
