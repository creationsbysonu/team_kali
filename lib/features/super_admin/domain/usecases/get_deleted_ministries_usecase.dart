import 'package:dartz/dartz.dart';
import 'package:sewa_web/core/errors/failures.dart';
import 'package:sewa_web/core/usecases/usecase.dart';
import 'package:sewa_web/features/auth/domain/entities/ministry.dart';
import 'package:sewa_web/features/super_admin/domain/repositories/ministry_repository.dart';

/// Fetch list of soft-deleted ministries (Super Admin only)
class GetDeletedMinistriesUseCase implements UseCase<List<Ministry>, NoParams> {
  final MinistryRepository repository;

  GetDeletedMinistriesUseCase(this.repository);

  @override
  Future<Either<Failure, List<Ministry>>> call(NoParams params) {
    return repository.getDeletedMinistries();
  }
}
