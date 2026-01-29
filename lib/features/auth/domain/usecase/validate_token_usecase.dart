import 'package:dartz/dartz.dart';
import 'package:sewa_web/core/errors/failures.dart';
import 'package:sewa_web/core/usecases/usecase.dart';
import 'package:sewa_web/features/auth/domain/repositories/auth_repository.dart';

class ValidateTokenUseCase implements UseCase<bool, NoParams> {
  final AuthRepository repository;

  ValidateTokenUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(NoParams params) {
    return repository.validateToken();
  }
}
