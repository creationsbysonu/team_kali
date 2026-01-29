import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sewa_web/features/queue_management/domain/entities/queue_configuration.dart';
import 'package:sewa_web/features/queue_management/domain/usecases/queue_config_usecases.dart';

part 'queue_config_event.dart';
part 'queue_config_state.dart';

/// Queue Configuration BLoC
///
/// Manages queue configuration state with optimized transitions for
/// smooth UI rendering and fast backend response handling.
///
/// Features:
/// - Preserves previous data during loading for smooth UI
/// - Supports retry on errors
/// - Tracks operation types for appropriate UI feedback
/// - Emits sequential states for proper listener handling
class QueueConfigBloc extends Bloc<QueueConfigEvent, QueueConfigState> {
  final GetAllServicesWithConfigsUseCase getAllServicesWithConfigs;
  final GetConfigByServiceUseCase getConfigByService;
  final CreateQueueConfigUseCase createConfig;
  final UpdateQueueConfigUseCase updateConfig;

  QueueConfigBloc({
    required this.getAllServicesWithConfigs,
    required this.getConfigByService,
    required this.createConfig,
    required this.updateConfig,
  }) : super(QueueConfigInitial()) {
    on<LoadQueueConfigsEvent>(_onLoadQueueConfigs);
    on<LoadConfigByServiceEvent>(_onLoadConfigByService);
    on<CreateConfigEvent>(_onCreateConfig);
    on<UpdateConfigEvent>(_onUpdateConfig);
    on<ResetQueueConfigStateEvent>(_onResetState);
    on<RetryLastEventEvent>(_onRetryLastEvent);
  }

  // Store last event for retry functionality
  QueueConfigEvent? _lastEvent;

  /// Load all services with their queue configurations
  Future<void> _onLoadQueueConfigs(
    LoadQueueConfigsEvent event,
    Emitter<QueueConfigState> emit,
  ) async {
    _lastEvent = event;

    // Preserve previous data during loading for smooth UI
    final currentState = state;
    if (currentState is QueueConfigsLoaded) {
      emit(
        QueueConfigsLoading(
          previousServices: currentState.services,
          previousConfigExists: currentState.configExists,
        ),
      );
    } else {
      emit(QueueConfigLoading());
    }

    final result = await getAllServicesWithConfigs(
      GetAllServicesWithConfigsParams(ministryId: event.ministryId),
    );

    result.fold(
      (failure) =>
          emit(QueueConfigError(message: failure.message, canRetry: true)),
      (data) {
        final services = data['services'] as List;
        final configExists = data['configExists'] as Map<String, bool>;
        emit(
          QueueConfigsLoaded(services: services, configExists: configExists),
        );
      },
    );
  }

  /// Load configuration for a specific service
  Future<void> _onLoadConfigByService(
    LoadConfigByServiceEvent event,
    Emitter<QueueConfigState> emit,
  ) async {
    _lastEvent = event;

    // Preserve previous config during reload
    final currentState = state;
    if (currentState is QueueConfigLoaded) {
      emit(QueueConfigReloading(previousConfig: currentState.config));
    } else {
      emit(QueueConfigLoading());
    }

    final result = await getConfigByService(
      GetConfigByServiceParams(staffServiceId: event.staffServiceId),
    );

    result.fold(
      (failure) =>
          emit(QueueConfigError(message: failure.message, canRetry: true)),
      (config) {
        if (config == null) {
          emit(QueueConfigNotFound(staffServiceId: event.staffServiceId));
        } else {
          emit(QueueConfigLoaded(config: config));
        }
      },
    );
  }

  /// Create a new queue configuration
  Future<void> _onCreateConfig(
    CreateConfigEvent event,
    Emitter<QueueConfigState> emit,
  ) async {
    emit(
      const QueueConfigOperationInProgress(
        operationType: OperationType.create,
        message: 'Creating queue configuration...',
      ),
    );

    final result = await createConfig(
      CreateQueueConfigParams(configData: event.configData),
    );

    result.fold(
      (failure) => emit(
        QueueConfigOperationError(
          message: failure.message,
          operationType: OperationType.create,
        ),
      ),
      (config) {
        // Emit success first for snackbar/listener
        emit(
          QueueConfigOperationSuccess(
            message: 'Queue configuration created successfully',
            operationType: OperationType.create,
            resultConfig: config,
          ),
        );
      },
    );
  }

  /// Update an existing queue configuration
  Future<void> _onUpdateConfig(
    UpdateConfigEvent event,
    Emitter<QueueConfigState> emit,
  ) async {
    emit(
      const QueueConfigOperationInProgress(
        operationType: OperationType.update,
        message: 'Saving changes...',
      ),
    );

    final result = await updateConfig(
      UpdateQueueConfigParams(
        configId: event.configId,
        configData: event.configData,
      ),
    );

    result.fold(
      (failure) => emit(
        QueueConfigOperationError(
          message: failure.message,
          operationType: OperationType.update,
        ),
      ),
      (config) {
        // Emit success for listener handling
        emit(
          QueueConfigOperationSuccess(
            message: 'Queue configuration updated successfully',
            operationType: OperationType.update,
            resultConfig: config,
          ),
        );
      },
    );
  }

  /// Reset to initial state
  void _onResetState(
    ResetQueueConfigStateEvent event,
    Emitter<QueueConfigState> emit,
  ) {
    _lastEvent = null;
    emit(QueueConfigInitial());
  }

  /// Retry the last failed event
  void _onRetryLastEvent(
    RetryLastEventEvent event,
    Emitter<QueueConfigState> emit,
  ) {
    if (_lastEvent != null) {
      add(_lastEvent!);
    }
  }
}
