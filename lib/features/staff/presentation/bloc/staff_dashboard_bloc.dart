import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sewa_web/features/auth/domain/entities/user_entity.dart';

part 'staff_dashboard_event.dart';
part 'staff_dashboard_state.dart';

/// Staff Dashboard BLoC
/// Manages state for staff dashboard - displays service info and provides navigation
///
/// Features:
/// - Loads and displays staff's assigned service information
/// - Shows ministry and place context
/// - Supports refresh for data updates
class StaffDashboardBloc
    extends Bloc<StaffDashboardEvent, StaffDashboardState> {
  StaffDashboardBloc() : super(StaffDashboardInitial()) {
    on<LoadStaffDashboardEvent>(_onLoadDashboard);
    on<RefreshStaffDashboardEvent>(_onRefreshDashboard);
  }

  /// Load staff dashboard with user's service information
  Future<void> _onLoadDashboard(
    LoadStaffDashboardEvent event,
    Emitter<StaffDashboardState> emit,
  ) async {
    try {
      emit(StaffDashboardLoading());

      // Validate user has required service information
      if (event.user.service == null) {
        emit(
          const StaffDashboardError(
            message:
                'No service associated with this account. '
                'Please contact your administrator.',
          ),
        );
        return;
      }

      // Emit loaded state with all dashboard data
      emit(
        StaffDashboardLoaded(
          service: event.user.service!,
          ministry: event.user.ministry,
          place: event.user.place,
          user: event.user,
        ),
      );
    } catch (e) {
      emit(
        StaffDashboardError(
          message: 'Failed to load dashboard: ${e.toString()}',
        ),
      );
    }
  }

  /// Refresh dashboard data while preserving current state
  Future<void> _onRefreshDashboard(
    RefreshStaffDashboardEvent event,
    Emitter<StaffDashboardState> emit,
  ) async {
    try {
      // Only refresh if we already have loaded state
      if (state is StaffDashboardLoaded) {
        final currentState = state as StaffDashboardLoaded;

        // Keep current state visible while refreshing
        emit(StaffDashboardReloading(previousState: currentState));

        // Re-emit the current state (in future, fetch fresh data from API)
        emit(currentState);
      }
    } catch (e) {
      emit(
        StaffDashboardError(
          message: 'Failed to refresh dashboard: ${e.toString()}',
        ),
      );
    }
  }
}
