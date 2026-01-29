import 'package:dartz/dartz.dart';
import 'package:sewa_sathi/core/errors/failures.dart';
import 'package:sewa_sathi/core/usecases/usecase.dart';
import 'package:sewa_sathi/features/profile/domain/entities/profile_entity.dart';
import 'package:sewa_sathi/features/profile/domain/repositories/profile_repository.dart';

/// Use case to check the profile status of the current user.
///
/// Returns [ProfileEntity] if profile is complete, null if incomplete.
class CheckProfileStatusUseCase implements UseCase<ProfileEntity?, NoParams> {
  final ProfileRepository repository;

  CheckProfileStatusUseCase(this.repository);

  @override
  Future<Either<Failure, ProfileEntity?>> call(NoParams params) async {
    return await repository.checkProfileStatus();
  }
}
