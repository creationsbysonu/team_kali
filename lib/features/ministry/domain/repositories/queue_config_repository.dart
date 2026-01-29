import 'package:dartz/dartz.dart';
import 'package:sewa_web/core/errors/failures.dart';
import 'package:sewa_web/features/ministry/domain/entities/queue_configuration.dart';
import 'package:sewa_web/features/ministry/domain/entities/progress_step.dart';

/// Abstract repository for Queue Configuration operations
abstract class QueueConfigRepository {
  /// Get queue config by staff service ID
  Future<Either<Failure, QueueConfiguration?>> getConfigByServiceId(
    String staffServiceId,
  );

  /// Create new queue configuration
  Future<Either<Failure, QueueConfiguration>> createConfig({
    required String staffServiceId,
    required Map<String, dynamic> configData,
    required List<ProgressStep> progressSteps,
  });

  /// Update existing queue configuration
  Future<Either<Failure, QueueConfiguration>> updateConfig({
    required String configId,
    required Map<String, dynamic> configData,
    required List<ProgressStep> progressSteps,
  });

  /// Get config details by ID
  Future<Either<Failure, QueueConfiguration>> getConfigById(String configId);

  /// Delete queue configuration
  Future<Either<Failure, void>> deleteConfig(String configId);

  /// Get progress steps for a config
  Future<Either<Failure, List<ProgressStep>>> getProgressSteps(String configId);
}
