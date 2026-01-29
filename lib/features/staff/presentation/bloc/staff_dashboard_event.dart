part of 'staff_dashboard_bloc.dart';

abstract class StaffDashboardEvent extends Equatable {
  const StaffDashboardEvent();

  @override
  List<Object?> get props => [];
}

class LoadStaffDashboardEvent extends StaffDashboardEvent {
  final UserEntity user;

  const LoadStaffDashboardEvent({required this.user});

  @override
  List<Object?> get props => [user];
}

class RefreshStaffDashboardEvent extends StaffDashboardEvent {
  const RefreshStaffDashboardEvent();
}
