import 'package:dartz/dartz.dart';
import 'package:sewa_web/core/errors/failures.dart';
import 'package:sewa_web/features/services/domain/entities/service.dart';

/// Abstract repository for Service operations
abstract class ServiceRepository {
  /// Get public services for a ministry (for staff login selection)
  Future<Either<Failure, List<Service>>> getPublicServices({
    required String placeSlug,
    required String ministrySlug,
  });

  /// Get all services in ministry (for ministry admin)
  Future<Either<Failure, List<Service>>> getMinistryServices();

  /// Get service by ID
  Future<Either<Failure, Service>> getServiceById(String id);

  /// Create a new service (ministry admin only)
  Future<Either<Failure, Service>> createService({
    required String name,
    required String slug,
    String? description,
    ServiceType? serviceType,
    double? feeAmount,
  });

  /// Update service
  Future<Either<Failure, Service>> updateService({
    required String id,
    String? name,
    String? slug,
    String? description,
    ServiceType? serviceType,
    double? feeAmount,
    bool? isActive,
    bool? isPublished,
  });

  /// Delete service
  Future<Either<Failure, void>> deleteService(String id);
}
