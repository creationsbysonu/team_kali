import 'package:dartz/dartz.dart';
import 'package:sewa_web/core/errors/failures.dart';
import 'package:sewa_web/core/usecases/usecase.dart';
import 'package:sewa_web/features/queue_management/domain/entities/queue_configuration.dart';
import 'package:sewa_web/features/queue_management/domain/repositories/queue_config_repository.dart';

class GetConfigByServiceParams {
  final String staffServiceId;

  const GetConfigByServiceParams({required this.staffServiceId});
}

class GetConfigByServiceUseCase
    implements UseCase<QueueConfiguration?, GetConfigByServiceParams> {
  final QueueConfigRepository repository;

  GetConfigByServiceUseCase(this.repository);

  @override
  Future<Either<Failure, QueueConfiguration?>> call(
    GetConfigByServiceParams params,
  ) async {
    if (params.staffServiceId.isEmpty) {
      return const Left(
        ValidationFailure(message: 'Staff Service ID is required'),
      );
    }

    return await repository.getConfigByService(params.staffServiceId);
  }
}
