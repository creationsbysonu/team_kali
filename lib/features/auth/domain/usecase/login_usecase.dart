import 'package:dartz/dartz.dart';
import 'package:sewa_web/core/errors/failures.dart';
import 'package:sewa_web/core/usecases/usecase.dart';
import 'package:sewa_web/features/auth/domain/entities/auth_credentials.dart';
import 'package:sewa_web/features/auth/domain/entities/user_entity.dart';
import 'package:sewa_web/features/auth/domain/repositories/auth_repository.dart';

class LoginUseCase implements UseCase<UserEntity, AuthCredentials> {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(AuthCredentials params) async {
    // Validate credentials
    if (!params.hasValidEmail) {
      return const Left(
        ValidationFailure(message: "Please enter a valid email address"),
      );
    }

    if (params.password.isEmpty) {
      return const Left(ValidationFailure(message: "Password cannot be empty"));
    }
    return repository.loginWithEmailAndPassword(params);
  }
}
