part of 'queue_config_bloc.dart';

/// Base class for all queue configuration events
abstract class QueueConfigEvent extends Equatable {
  const QueueConfigEvent();

  @override
  List<Object?> get props => [];
}

/// Load all services with their queue configurations for a ministry
class LoadQueueConfigsEvent extends QueueConfigEvent {
  final String ministryId;

  const LoadQueueConfigsEvent({required this.ministryId});

  @override
  List<Object?> get props => [ministryId];
}

/// Load configuration for a specific staff service
class LoadConfigByServiceEvent extends QueueConfigEvent {
  final String staffServiceId;

  const LoadConfigByServiceEvent({required this.staffServiceId});

  @override
  List<Object?> get props => [staffServiceId];
}

/// Create a new queue configuration
class CreateConfigEvent extends QueueConfigEvent {
  final Map<String, dynamic> configData;

  const CreateConfigEvent({required this.configData});

  @override
  List<Object?> get props => [configData];
}

/// Update an existing queue configuration
class UpdateConfigEvent extends QueueConfigEvent {
  final String configId;
  final Map<String, dynamic> configData;

  const UpdateConfigEvent({required this.configId, required this.configData});

  @override
  List<Object?> get props => [configId, configData];
}

/// Reset the BLoC state to initial
class ResetQueueConfigStateEvent extends QueueConfigEvent {
  const ResetQueueConfigStateEvent();
}

/// Retry the last failed event
class RetryLastEventEvent extends QueueConfigEvent {
  const RetryLastEventEvent();
}
