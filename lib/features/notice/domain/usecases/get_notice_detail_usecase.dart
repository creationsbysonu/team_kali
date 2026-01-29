import 'package:dartz/dartz.dart';
import 'package:sewa_sathi/core/errors/failures.dart';
import 'package:sewa_sathi/core/usecases/usecase.dart';
import 'package:sewa_sathi/features/notice/domain/entities/notice_detail_entity.dart';
import 'package:sewa_sathi/features/notice/domain/repositories/notice_repository.dart';

/// Use case to get detailed information about a specific notice.
class GetNoticeDetailUseCase implements UseCase<NoticeDetailEntity, String> {
  final NoticeRepository repository;

  GetNoticeDetailUseCase(this.repository);

  @override
  Future<Either<Failure, NoticeDetailEntity>> call(String noticeId) async {
    if (noticeId.isEmpty) {
      return const Left(
        ValidationFailure(message: 'Notice ID cannot be empty'),
      );
    }

    return repository.getNoticeDetail(noticeId);
  }
}
