import 'package:dartz/dartz.dart';
import 'package:sewa_sathi/core/errors/failures.dart';
import 'package:sewa_sathi/core/usecases/usecase.dart';
import 'package:sewa_sathi/features/notice/domain/entities/filter_options_entity.dart';
import 'package:sewa_sathi/features/notice/domain/repositories/notice_repository.dart';

/// Use case to get filter options for notices.
class GetFilterOptionsUseCase
    implements UseCase<FilterOptionsEntity, NoParams> {
  final NoticeRepository repository;

  GetFilterOptionsUseCase(this.repository);

  @override
  Future<Either<Failure, FilterOptionsEntity>> call(NoParams params) async {
    return repository.getFilterOptions();
  }
}
