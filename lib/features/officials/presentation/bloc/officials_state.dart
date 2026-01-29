part of 'officials_bloc.dart';

/// Base state class for Officials feature
abstract class OfficialsState extends Equatable {
  const OfficialsState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class OfficialsInitial extends OfficialsState {}

/// Loading officials list
class OfficialsLoading extends OfficialsState {}

/// Officials list loaded successfully
class OfficialsLoaded extends OfficialsState {
  final List<Official> officials;

  const OfficialsLoaded({required this.officials});

  @override
  List<Object?> get props => [officials];
}

/// Loading single official detail
class OfficialDetailLoading extends OfficialsState {}

/// Official detail loaded successfully
class OfficialDetailLoaded extends OfficialsState {
  final Official official;

  const OfficialDetailLoaded({required this.official});

  @override
  List<Object?> get props => [official];
}

/// Creating a new official
class OfficialCreating extends OfficialsState {}

/// Official created successfully
class OfficialCreated extends OfficialsState {
  final Official official;

  const OfficialCreated({required this.official});

  @override
  List<Object?> get props => [official];
}

/// Updating an official
class OfficialUpdating extends OfficialsState {}

/// Official updated successfully
class OfficialUpdated extends OfficialsState {
  final Official official;

  const OfficialUpdated({required this.official});

  @override
  List<Object?> get props => [official];
}

/// Deleting an official
class OfficialDeleting extends OfficialsState {}

/// Official deleted successfully
class OfficialDeleted extends OfficialsState {
  const OfficialDeleted();
}

/// Error state
class OfficialsError extends OfficialsState {
  final String message;

  const OfficialsError({required this.message});

  @override
  List<Object?> get props => [message];
}
