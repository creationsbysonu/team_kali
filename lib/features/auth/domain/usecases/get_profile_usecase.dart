import 'package:dartz/dartz.dart';
import 'package:sewa_sathi/core/errors/failures.dart';
import 'package:sewa_sathi/core/usecases/usecase.dart';
import 'package:sewa_sathi/features/auth/domain/entities/user_entity.dart';
import 'package:sewa_sathi/features/auth/domain/repositories/auth_repository.dart';

/// Use case for getting the current user's profile.
class GetProfileUseCase implements UseCase<UserEntity, NoParams> {
  final AuthRepository repository;

  GetProfileUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(NoParams params) {
    return repository.getProfile();
  }
}
