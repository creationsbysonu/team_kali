part of 'staff_bloc.dart';

/// Base class for all staff states
abstract class StaffState extends Equatable {
  const StaffState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class StaffInitial extends StaffState {}

/// Loading staff
class StaffLoading extends StaffState {}

/// Staff loaded
class StaffLoaded extends StaffState {
  final List<StaffMember> staff;

  const StaffLoaded({required this.staff});

  @override
  List<Object?> get props => [staff];
}

/// Error loading staff
class StaffError extends StaffState {
  final String message;

  const StaffError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Loading for CRUD operation
class StaffOperationLoading extends StaffState {}

/// CRUD operation successful
class StaffOperationSuccess extends StaffState {
  final String message;
  final StaffMember? staff;

  const StaffOperationSuccess({required this.message, this.staff});

  @override
  List<Object?> get props => [message, staff];
}

/// CRUD operation error
class StaffOperationError extends StaffState {
  final String message;

  const StaffOperationError({required this.message});

  @override
  List<Object?> get props => [message];
}
