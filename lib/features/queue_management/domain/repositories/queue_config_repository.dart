import 'package:dartz/dartz.dart';
import 'package:sewa_web/core/errors/failures.dart';
import 'package:sewa_web/features/queue_management/domain/entities/queue_configuration.dart';

/// Queue Configuration Repository Interface
abstract class QueueConfigRepository {
  /// Get all services with their queue configurations
  Future<Either<Failure, Map<String, dynamic>>> getAllServicesWithConfigs(
    String ministryId,
  );

  /// Get queue configuration by staff service ID
  Future<Either<Failure, QueueConfiguration?>> getConfigByService(
    String staffServiceId,
  );

  /// Create queue configuration
  Future<Either<Failure, QueueConfiguration>> createConfig(
    Map<String, dynamic> configData,
  );

  /// Update queue configuration
  Future<Either<Failure, QueueConfiguration>> updateConfig(
    String configId,
    Map<String, dynamic> configData,
  );

  /// Delete queue configuration
  Future<Either<Failure, void>> deleteConfig(String configId);
}
