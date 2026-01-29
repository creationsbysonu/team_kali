import 'package:dartz/dartz.dart';
import 'package:sewa_web/core/errors/failures.dart';
import 'package:sewa_web/core/usecases/usecase.dart';
import 'package:sewa_web/features/queue_management/domain/entities/queue_configuration.dart';
import 'package:sewa_web/features/queue_management/domain/repositories/queue_config_repository.dart';

class UpdateQueueConfigParams {
  final String configId;
  final Map<String, dynamic> configData;

  const UpdateQueueConfigParams({
    required this.configId,
    required this.configData,
  });
}

class UpdateQueueConfigUseCase
    implements UseCase<QueueConfiguration, UpdateQueueConfigParams> {
  final QueueConfigRepository repository;

  UpdateQueueConfigUseCase(this.repository);

  @override
  Future<Either<Failure, QueueConfiguration>> call(
    UpdateQueueConfigParams params,
  ) async {
    if (params.configId.isEmpty) {
      return const Left(ValidationFailure(message: 'Config ID is required'));
    }

    if (params.configData.isEmpty) {
      return const Left(
        ValidationFailure(message: 'At least one field must be updated'),
      );
    }

    return await repository.updateConfig(params.configId, params.configData);
  }
}
