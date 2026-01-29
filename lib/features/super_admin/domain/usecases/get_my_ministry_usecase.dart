import 'package:dartz/dartz.dart';
import 'package:sewa_web/core/errors/failures.dart';
import 'package:sewa_web/core/usecases/usecase.dart';
import 'package:sewa_web/features/auth/domain/entities/ministry.dart';
import 'package:sewa_web/features/super_admin/domain/repositories/ministry_repository.dart';

/// Use case to get current ministry's own profile
/// For ministry staff users to view their ministry details
class GetMyMinistryUseCase implements UseCase<Ministry, NoParams> {
  final MinistryRepository repository;

  GetMyMinistryUseCase(this.repository);

  @override
  Future<Either<Failure, Ministry>> call(NoParams params) async {
    return await repository.getMyMinistry();
  }
}
