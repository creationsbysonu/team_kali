part of 'queue_config_bloc.dart';

/// Operation types for tracking what action is in progress
enum OperationType { create, update, delete }

/// Base class for all queue configuration states
abstract class QueueConfigState extends Equatable {
  const QueueConfigState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any action
class QueueConfigInitial extends QueueConfigState {}

/// Loading state for single config operations
class QueueConfigLoading extends QueueConfigState {}

/// Loading state that preserves previous config data for smooth UI
class QueueConfigReloading extends QueueConfigState {
  final QueueConfiguration previousConfig;

  const QueueConfigReloading({required this.previousConfig});

  @override
  List<Object?> get props => [previousConfig];
}

/// Loading state for list operations that preserves previous data
class QueueConfigsLoading extends QueueConfigState {
  final List<dynamic>? previousServices;
  final Map<String, bool>? previousConfigExists;

  const QueueConfigsLoading({this.previousServices, this.previousConfigExists});

  @override
  List<Object?> get props => [previousServices, previousConfigExists];
}

/// Single configuration loaded successfully
class QueueConfigLoaded extends QueueConfigState {
  final QueueConfiguration config;

  const QueueConfigLoaded({required this.config});

  @override
  List<Object?> get props => [config];
}

/// All services with their config status loaded successfully
/// configExists: Map<serviceId, bool> - just indicates if config exists
class QueueConfigsLoaded extends QueueConfigState {
  final List<dynamic> services;
  final Map<String, bool> configExists;

  const QueueConfigsLoaded({
    required this.services,
    required this.configExists,
  });

  @override
  List<Object?> get props => [services, configExists];
}

/// No configuration found for the requested service
class QueueConfigNotFound extends QueueConfigState {
  final String staffServiceId;

  const QueueConfigNotFound({required this.staffServiceId});

  @override
  List<Object?> get props => [staffServiceId];
}

/// Error state with retry capability
class QueueConfigError extends QueueConfigState {
  final String message;
  final bool canRetry;

  const QueueConfigError({required this.message, this.canRetry = false});

  @override
  List<Object?> get props => [message, canRetry];
}

/// Operation (create/update) in progress
class QueueConfigOperationInProgress extends QueueConfigState {
  final OperationType operationType;
  final String message;

  const QueueConfigOperationInProgress({
    required this.operationType,
    required this.message,
  });

  @override
  List<Object?> get props => [operationType, message];
}

/// Operation completed successfully
class QueueConfigOperationSuccess extends QueueConfigState {
  final String message;
  final OperationType operationType;
  final QueueConfiguration? resultConfig;

  const QueueConfigOperationSuccess({
    required this.message,
    required this.operationType,
    this.resultConfig,
  });

  @override
  List<Object?> get props => [message, operationType, resultConfig];
}

/// Operation failed with error
class QueueConfigOperationError extends QueueConfigState {
  final String message;
  final OperationType operationType;

  const QueueConfigOperationError({
    required this.message,
    required this.operationType,
  });

  @override
  List<Object?> get props => [message, operationType];
}
