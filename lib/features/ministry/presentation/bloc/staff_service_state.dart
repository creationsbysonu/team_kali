part of 'staff_service_bloc.dart';

abstract class StaffServiceState extends Equatable {
  const StaffServiceState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class StaffServiceInitial extends StaffServiceState {}

/// Loading state
class StaffServiceLoading extends StaffServiceState {}

/// Loaded state with list of staff services
class StaffServiceLoaded extends StaffServiceState {
  final List<StaffService> services;

  const StaffServiceLoaded({required this.services});

  @override
  List<Object?> get props => [services];
}

/// Operation in progress (create, update, delete, toggle, reset password)
class StaffServiceOperationInProgress extends StaffServiceState {
  final String
  operationType; // 'create', 'update', 'delete', 'toggle', 'reset_password'
  final List<StaffService> currentServices;

  const StaffServiceOperationInProgress({
    required this.operationType,
    required this.currentServices,
  });

  @override
  List<Object?> get props => [operationType, currentServices];
}

/// Operation success
class StaffServiceOperationSuccess extends StaffServiceState {
  final String message;
  final List<StaffService> updatedServices;

  const StaffServiceOperationSuccess({
    required this.message,
    required this.updatedServices,
  });

  @override
  List<Object?> get props => [message, updatedServices];
}

/// Service created successfully
class StaffServiceCreated extends StaffServiceState {
  final StaffService service;

  const StaffServiceCreated({required this.service});

  @override
  List<Object?> get props => [service];
}

/// Error state
class StaffServiceError extends StaffServiceState {
  final String message;
  final List<StaffService>? currentServices;

  const StaffServiceError({required this.message, this.currentServices});

  @override
  List<Object?> get props => [message, currentServices];
}
