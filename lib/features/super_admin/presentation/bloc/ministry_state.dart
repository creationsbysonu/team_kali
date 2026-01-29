part of 'ministry_bloc.dart';

abstract class MinistryState extends Equatable {
  const MinistryState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class MinistryInitial extends MinistryState {}

/// Loading ministries
class MinistryLoading extends MinistryState {}

/// Places for filter loaded
class PlacesForFilterLoaded extends MinistryState {
  final List<PlaceFilterOption> places;

  const PlacesForFilterLoaded({required this.places});

  @override
  List<Object?> get props => [places];
}

/// Refreshing ministries (keeps current data)
class MinistryRefreshing extends MinistryState {
  final List<Ministry> ministries;

  const MinistryRefreshing({required this.ministries});

  @override
  List<Object?> get props => [ministries];
}

/// Ministries loaded successfully
class MinistryLoaded extends MinistryState {
  final List<Ministry> ministries;
  final String? selectedPlaceId;

  const MinistryLoaded({required this.ministries, this.selectedPlaceId});

  @override
  List<Object?> get props => [ministries, selectedPlaceId];
}

/// Deleted ministries loaded
class DeletedMinistriesLoaded extends MinistryState {
  final List<Ministry> ministries;

  const DeletedMinistriesLoaded({required this.ministries});

  @override
  List<Object?> get props => [ministries];
}

/// Deleted ministries refreshing (keeps current data)
class DeletedMinistriesRefreshing extends MinistryState {
  final List<Ministry> ministries;

  const DeletedMinistriesRefreshing({required this.ministries});

  @override
  List<Object?> get props => [ministries];
}

/// Error loading ministries
class MinistryError extends MinistryState {
  final String message;

  const MinistryError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Creating a ministry (preserves current list for UI)
class MinistryCreating extends MinistryState {
  final List<Ministry> ministries;
  final List<Ministry> deletedMinistries;

  const MinistryCreating({
    this.ministries = const [],
    this.deletedMinistries = const [],
  });

  @override
  List<Object?> get props => [ministries, deletedMinistries];
}

/// Updating a ministry (preserves current list for UI)
class MinistryUpdating extends MinistryState {
  final List<Ministry> ministries;
  final List<Ministry> deletedMinistries;

  const MinistryUpdating({
    this.ministries = const [],
    this.deletedMinistries = const [],
  });

  @override
  List<Object?> get props => [ministries, deletedMinistries];
}

/// Ministry created successfully
class MinistryCreated extends MinistryState {
  final Ministry ministry;

  const MinistryCreated({required this.ministry});

  @override
  List<Object?> get props => [ministry];
}

/// Ministry updated successfully
class MinistryUpdated extends MinistryState {
  final Ministry ministry;

  const MinistryUpdated({required this.ministry});

  @override
  List<Object?> get props => [ministry];
}

/// Ministry activated successfully
class MinistryActivated extends MinistryState {
  final Ministry ministry;

  const MinistryActivated({required this.ministry});

  @override
  List<Object?> get props => [ministry];
}

/// Ministry suspended successfully
class MinistrySuspended extends MinistryState {
  final Ministry ministry;

  const MinistrySuspended({required this.ministry});

  @override
  List<Object?> get props => [ministry];
}

/// Ministry deleted (soft) successfully
class MinistryDeleted extends MinistryState {
  final String ministryId;

  const MinistryDeleted({required this.ministryId});

  @override
  List<Object?> get props => [ministryId];
}

/// Ministry restored successfully
class MinistryRestored extends MinistryState {
  final Ministry ministry;

  const MinistryRestored({required this.ministry});

  @override
  List<Object?> get props => [ministry];
}

/// Ministry hard deleted (permanent)
class MinistryHardDeleted extends MinistryState {
  final String ministryId;

  const MinistryHardDeleted({required this.ministryId});

  @override
  List<Object?> get props => [ministryId];
}

/// Ministry password reset successfully
class MinistryPasswordReset extends MinistryState {
  final String ministryId;

  const MinistryPasswordReset({required this.ministryId});

  @override
  List<Object?> get props => [ministryId];
}

/// Operation error (create/update/delete failed)
class MinistryOperationError extends MinistryState {
  final String message;

  const MinistryOperationError({required this.message});

  @override
  List<Object?> get props => [message];
}
