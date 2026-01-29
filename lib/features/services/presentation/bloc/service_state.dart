part of 'service_bloc.dart';

/// Base class for all service states
abstract class ServiceState extends Equatable {
  const ServiceState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class ServiceInitial extends ServiceState {}

/// Loading services
class ServiceLoading extends ServiceState {}

/// Services loaded
class ServicesLoaded extends ServiceState {
  final List<Service> services;

  const ServicesLoaded({required this.services});

  @override
  List<Object?> get props => [services];
}

/// A service has been selected
class ServiceSelected extends ServiceState {
  final Service service;

  const ServiceSelected({required this.service});

  @override
  List<Object?> get props => [service];
}

/// Error loading services
class ServiceError extends ServiceState {
  final String message;

  const ServiceError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Loading for CRUD operation
class ServiceOperationLoading extends ServiceState {}

/// CRUD operation successful
class ServiceOperationSuccess extends ServiceState {
  final String message;
  final Service? service;

  const ServiceOperationSuccess({required this.message, this.service});

  @override
  List<Object?> get props => [message, service];
}

/// CRUD operation error
class ServiceOperationError extends ServiceState {
  final String message;

  const ServiceOperationError({required this.message});

  @override
  List<Object?> get props => [message];
}
