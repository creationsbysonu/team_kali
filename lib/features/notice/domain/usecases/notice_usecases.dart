import 'package:dartz/dartz.dart';
import 'package:sewa_web/core/errors/failures.dart';
import 'package:sewa_web/core/usecases/usecase.dart';
import 'package:sewa_web/features/notice/domain/entities/notice_entity.dart';
import 'package:sewa_web/features/notice/domain/repositories/notice_repository.dart';

/// Get notices with pagination and filters
class GetNoticesUseCase
    implements UseCase<NoticeListResponse, GetNoticesParams> {
  final NoticeRepository repository;

  GetNoticesUseCase(this.repository);

  @override
  Future<Either<Failure, NoticeListResponse>> call(
    GetNoticesParams params,
  ) async {
    return repository.getNotices(params);
  }
}

/// Get notice by ID
class GetNoticeByIdUseCase implements UseCase<NoticeEntity, String> {
  final NoticeRepository repository;

  GetNoticeByIdUseCase(this.repository);

  @override
  Future<Either<Failure, NoticeEntity>> call(String noticeId) async {
    return repository.getNoticeById(noticeId);
  }
}

/// Upload a new notice
class UploadNoticeUseCase implements UseCase<NoticeEntity, UploadNoticeParams> {
  final NoticeRepository repository;

  UploadNoticeUseCase(this.repository);

  @override
  Future<Either<Failure, NoticeEntity>> call(UploadNoticeParams params) async {
    // Validate title
    if (params.title.trim().isEmpty) {
      return const Left(ValidationFailure(message: 'Title is required'));
    }

    if (params.title.length > 500) {
      return const Left(
        ValidationFailure(message: 'Title cannot exceed 500 characters'),
      );
    }

    // Validate file
    if (params.fileBytes.isEmpty) {
      return const Left(ValidationFailure(message: 'File is required'));
    }

    // Validate file size (10MB max)
    const maxSize = 10 * 1024 * 1024; // 10MB in bytes
    if (params.fileBytes.length > maxSize) {
      return const Left(
        ValidationFailure(message: 'File size cannot exceed 10 MB'),
      );
    }

    // Validate file extension
    final extension = params.fileName.split('.').last.toLowerCase();
    const allowedExtensions = ['pdf', 'png', 'jpg', 'jpeg'];
    if (!allowedExtensions.contains(extension)) {
      return Left(
        ValidationFailure(
          message:
              'File type "$extension" is not allowed. Allowed types: ${allowedExtensions.join(", ")}',
        ),
      );
    }

    return repository.uploadNotice(params);
  }
}

/// Update notice metadata
class UpdateNoticeUseCase implements UseCase<NoticeEntity, UpdateNoticeParams> {
  final NoticeRepository repository;

  UpdateNoticeUseCase(this.repository);

  @override
  Future<Either<Failure, NoticeEntity>> call(UpdateNoticeParams params) async {
    // Validate title if provided
    if (params.title != null && params.title!.trim().isEmpty) {
      return const Left(ValidationFailure(message: 'Title cannot be empty'));
    }

    if (params.title != null && params.title!.length > 500) {
      return const Left(
        ValidationFailure(message: 'Title cannot exceed 500 characters'),
      );
    }

    return repository.updateNotice(params);
  }
}

/// Delete a notice
class DeleteNoticeUseCase implements UseCase<void, String> {
  final NoticeRepository repository;

  DeleteNoticeUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String noticeId) async {
    return repository.deleteNotice(noticeId);
  }
}

/// Get notice statistics
class GetNoticeStatsUseCase implements UseCase<NoticeStatsEntity, NoParams> {
  final NoticeRepository repository;

  GetNoticeStatsUseCase(this.repository);

  @override
  Future<Either<Failure, NoticeStatsEntity>> call(NoParams params) async {
    return repository.getStats();
  }
}

/// Retry failed ingestion
class RetryIngestionUseCase implements UseCase<void, String> {
  final NoticeRepository repository;

  RetryIngestionUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String noticeId) async {
    return repository.retryIngestion(noticeId);
  }
}

/// Get available services
class GetNoticeServicesUseCase
    implements UseCase<List<NoticeServiceEntity>, NoParams> {
  final NoticeRepository repository;

  GetNoticeServicesUseCase(this.repository);

  @override
  Future<Either<Failure, List<NoticeServiceEntity>>> call(
    NoParams params,
  ) async {
    return repository.getServices();
  }
}
