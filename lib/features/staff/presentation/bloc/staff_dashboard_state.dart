part of 'staff_dashboard_bloc.dart';

/// Base class for all staff dashboard states
abstract class StaffDashboardState extends Equatable {
  const StaffDashboardState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any action
class StaffDashboardInitial extends StaffDashboardState {}

/// Loading state - loading dashboard data
class StaffDashboardLoading extends StaffDashboardState {}

/// Reloading state - keeps previous data visible while refreshing
class StaffDashboardReloading extends StaffDashboardState {
  final StaffDashboardLoaded previousState;

  const StaffDashboardReloading({required this.previousState});

  @override
  List<Object?> get props => [previousState];
}

/// Dashboard data loaded successfully
class StaffDashboardLoaded extends StaffDashboardState {
  final ServiceContext service;
  final MinistryContext? ministry;
  final PlaceContext? place;
  final UserEntity user;

  const StaffDashboardLoaded({
    required this.service,
    this.ministry,
    this.place,
    required this.user,
  });

  @override
  List<Object?> get props => [service, ministry, place, user];
}

/// Error state with error message
class StaffDashboardError extends StaffDashboardState {
  final String message;

  const StaffDashboardError({required this.message});

  @override
  List<Object?> get props => [message];
}
