part of 'service_bloc.dart';

/// Base class for all service events
abstract class ServiceEvent extends Equatable {
  const ServiceEvent();

  @override
  List<Object?> get props => [];
}

/// Load public services for a ministry (for staff login)
class LoadPublicServicesEvent extends ServiceEvent {
  final String placeSlug;
  final String ministrySlug;

  const LoadPublicServicesEvent({
    required this.placeSlug,
    required this.ministrySlug,
  });

  @override
  List<Object?> get props => [placeSlug, ministrySlug];
}

/// Load ministry services (ministry admin)
class LoadMinistryServicesEvent extends ServiceEvent {}

/// Select a service
class SelectServiceEvent extends ServiceEvent {
  final Service service;

  const SelectServiceEvent({required this.service});

  @override
  List<Object?> get props => [service];
}

/// Clear selected service
class ClearSelectedServiceEvent extends ServiceEvent {}

/// Create service (ministry admin)
class CreateServiceEvent extends ServiceEvent {
  final String name;
  final String slug;
  final String? description;
  final ServiceType? serviceType;
  final double? feeAmount;

  const CreateServiceEvent({
    required this.name,
    required this.slug,
    this.description,
    this.serviceType,
    this.feeAmount,
  });

  @override
  List<Object?> get props => [name, slug, description, serviceType, feeAmount];
}

/// Update service
class UpdateServiceEvent extends ServiceEvent {
  final String id;
  final String? name;
  final String? slug;
  final String? description;
  final ServiceType? serviceType;
  final double? feeAmount;
  final bool? isActive;
  final bool? isPublished;

  const UpdateServiceEvent({
    required this.id,
    this.name,
    this.slug,
    this.description,
    this.serviceType,
    this.feeAmount,
    this.isActive,
    this.isPublished,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    slug,
    description,
    serviceType,
    feeAmount,
    isActive,
    isPublished,
  ];
}

/// Delete service
class DeleteServiceEvent extends ServiceEvent {
  final String id;

  const DeleteServiceEvent({required this.id});

  @override
  List<Object?> get props => [id];
}
