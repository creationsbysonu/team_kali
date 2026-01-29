import 'package:dartz/dartz.dart';
import 'package:sewa_web/core/errors/failures.dart';
import 'package:sewa_web/core/usecases/usecase.dart';
import 'package:sewa_web/features/queue_management/domain/entities/queue_configuration.dart';
import 'package:sewa_web/features/queue_management/domain/repositories/queue_config_repository.dart';

class CreateQueueConfigParams {
  final Map<String, dynamic> configData;

  const CreateQueueConfigParams({required this.configData});
}

class CreateQueueConfigUseCase
    implements UseCase<QueueConfiguration, CreateQueueConfigParams> {
  final QueueConfigRepository repository;

  CreateQueueConfigUseCase(this.repository);

  @override
  Future<Either<Failure, QueueConfiguration>> call(
    CreateQueueConfigParams params,
  ) async {
    // Validation
    if (params.configData['staff_service'] == null) {
      return const Left(
        ValidationFailure(message: 'Staff Service is required'),
      );
    }

    if (params.configData['office_start_time'] == null) {
      return const Left(
        ValidationFailure(message: 'Office start time is required'),
      );
    }

    if (params.configData['office_end_time'] == null) {
      return const Left(
        ValidationFailure(message: 'Office end time is required'),
      );
    }

    if (params.configData['average_service_time_minutes'] == null) {
      return const Left(
        ValidationFailure(message: 'Average service time is required'),
      );
    }

    return await repository.createConfig(params.configData);
  }
}
