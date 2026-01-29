import 'package:dartz/dartz.dart';
import 'package:sewa_sathi/core/errors/failures.dart';
import 'package:sewa_sathi/core/usecases/usecase.dart';
import 'package:sewa_sathi/features/auth/domain/entities/user_entity.dart';
import 'package:sewa_sathi/features/auth/domain/repositories/auth_repository.dart';

/// Use case for checking authentication status on app startup.
class CheckAuthStatusUseCase implements UseCase<UserEntity?, NoParams> {
  final AuthRepository repository;

  CheckAuthStatusUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity?>> call(NoParams params) async {
    // First check if user is authenticated
    final isAuthResult = await repository.isAuthenticated();

    return isAuthResult.fold((failure) => Left(failure), (
      isAuthenticated,
    ) async {
      if (!isAuthenticated) {
        return const Right(null);
      }

      // Try to get cached user first
      final cachedResult = await repository.getCachedUser();
      return cachedResult.fold((failure) => Left(failure), (cachedUser) async {
        if (cachedUser != null) {
          return Right(cachedUser);
        }

        // If no cached user, fetch from server
        final profileResult = await repository.getProfile();
        return profileResult.fold(
          (failure) => const Right(null),
          (user) => Right(user),
        );
      });
    });
  }
}
