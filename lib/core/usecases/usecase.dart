import 'package:dartz/dartz.dart';
import 'package:sewa_sathi/core/errors/failures.dart';

/// Base UseCase interface following Clean Architecture.
/// Type = Return type, Params = Input parameters type.
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// Use this class when a use case doesn't require any parameters.
class NoParams {
  const NoParams();
}
