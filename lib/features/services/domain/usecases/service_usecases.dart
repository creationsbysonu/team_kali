import 'package:dartz/dartz.dart';
import 'package:sewa_web/core/errors/failures.dart';
import 'package:sewa_web/core/usecases/usecase.dart';
import 'package:sewa_web/features/services/domain/entities/service.dart';
import 'package:sewa_web/features/services/domain/repositories/service_repository.dart';

/// Get public services params
class GetPublicServicesParams {
  final String placeSlug;
  final String ministrySlug;

  const GetPublicServicesParams({
    required this.placeSlug,
    required this.ministrySlug,
  });
}

/// Get public services for staff login selection
class GetPublicServicesUseCase
    implements UseCase<List<Service>, GetPublicServicesParams> {
  final ServiceRepository repository;

  GetPublicServicesUseCase(this.repository);

  @override
  Future<Either<Failure, List<Service>>> call(GetPublicServicesParams params) {
    return repository.getPublicServices(
      placeSlug: params.placeSlug,
      ministrySlug: params.ministrySlug,
    );
  }
}

/// Get ministry services (for ministry admin)
class GetMinistryServicesUseCase implements UseCase<List<Service>, NoParams> {
  final ServiceRepository repository;

  GetMinistryServicesUseCase(this.repository);

  @override
  Future<Either<Failure, List<Service>>> call(NoParams params) {
    return repository.getMinistryServices();
  }
}

/// Get service by ID
class GetServiceByIdUseCase implements UseCase<Service, String> {
  final ServiceRepository repository;

  GetServiceByIdUseCase(this.repository);

  @override
  Future<Either<Failure, Service>> call(String id) {
    return repository.getServiceById(id);
  }
}

/// Create service params
class CreateServiceParams {
  final String name;
  final String slug;
  final String? description;
  final ServiceType? serviceType;
  final double? feeAmount;

  const CreateServiceParams({
    required this.name,
    required this.slug,
    this.description,
    this.serviceType,
    this.feeAmount,
  });
}

/// Create service
class CreateServiceUseCase implements UseCase<Service, CreateServiceParams> {
  final ServiceRepository repository;

  CreateServiceUseCase(this.repository);

  @override
  Future<Either<Failure, Service>> call(CreateServiceParams params) {
    return repository.createService(
      name: params.name,
      slug: params.slug,
      description: params.description,
      serviceType: params.serviceType,
      feeAmount: params.feeAmount,
    );
  }
}

/// Update service params
class UpdateServiceParams {
  final String id;
  final String? name;
  final String? slug;
  final String? description;
  final ServiceType? serviceType;
  final double? feeAmount;
  final bool? isActive;
  final bool? isPublished;

  const UpdateServiceParams({
    required this.id,
    this.name,
    this.slug,
    this.description,
    this.serviceType,
    this.feeAmount,
    this.isActive,
    this.isPublished,
  });
}

/// Update service
class UpdateServiceUseCase implements UseCase<Service, UpdateServiceParams> {
  final ServiceRepository repository;

  UpdateServiceUseCase(this.repository);

  @override
  Future<Either<Failure, Service>> call(UpdateServiceParams params) {
    return repository.updateService(
      id: params.id,
      name: params.name,
      slug: params.slug,
      description: params.description,
      serviceType: params.serviceType,
      feeAmount: params.feeAmount,
      isActive: params.isActive,
      isPublished: params.isPublished,
    );
  }
}

/// Delete service
class DeleteServiceUseCase implements UseCase<void, String> {
  final ServiceRepository repository;

  DeleteServiceUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String id) {
    return repository.deleteService(id);
  }
}
