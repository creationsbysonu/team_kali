import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:sewa_web/core/errors/failures.dart';
import 'package:sewa_web/core/usecases/usecase.dart';
import 'package:sewa_web/features/ministry/domain/entities/queue_configuration.dart';
import 'package:sewa_web/features/ministry/domain/entities/progress_step.dart';
import 'package:sewa_web/features/ministry/domain/repositories/queue_config_repository.dart';

class CreateConfigParams extends Equatable {
  final String staffServiceId;
  final Map<String, dynamic> configData;
  final List<ProgressStep> progressSteps;

  const CreateConfigParams({
    required this.staffServiceId,
    required this.configData,
    required this.progressSteps,
  });

  @override
  List<Object?> get props => [staffServiceId, configData, progressSteps];
}

/// Create new queue configuration
class CreateQueueConfigUseCase
    implements UseCase<QueueConfiguration, CreateConfigParams> {
  final QueueConfigRepository repository;

  CreateQueueConfigUseCase(this.repository);

  @override
  Future<Either<Failure, QueueConfiguration>> call(
    CreateConfigParams params,
  ) async {
    // Business validation
    if (params.staffServiceId.isEmpty) {
      return const Left(
        ValidationFailure(message: "Staff service ID is required"),
      );
    }

    return await repository.createConfig(
      staffServiceId: params.staffServiceId,
      configData: params.configData,
      progressSteps: params.progressSteps,
    );
  }
}
