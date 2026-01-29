part of 'attendance_calendar_bloc.dart';

/// States for attendance calendar
abstract class AttendanceCalendarState extends Equatable {
  const AttendanceCalendarState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class AttendanceCalendarInitial extends AttendanceCalendarState {}

/// Loading persons list
class LoadingPersonsList extends AttendanceCalendarState {}

/// Persons list loaded
class PersonsListLoaded extends AttendanceCalendarState {
  final List<Map<String, String>> persons;

  const PersonsListLoaded({required this.persons});

  @override
  List<Object?> get props => [persons];
}

/// Loading month data
class LoadingMonthData extends AttendanceCalendarState {
  final AttendanceMonthData? previousData;

  const LoadingMonthData({this.previousData});

  @override
  List<Object?> get props => [previousData];
}

/// Month data loaded successfully
class MonthDataLoaded extends AttendanceCalendarState {
  final AttendanceMonthData monthData;

  const MonthDataLoaded({required this.monthData});

  @override
  List<Object?> get props => [monthData];

  /// Copy with to update specific fields
  MonthDataLoaded copyWith({AttendanceMonthData? monthData}) {
    return MonthDataLoaded(monthData: monthData ?? this.monthData);
  }
}

/// Processing an action (mark/remove)
class ProcessingAction extends AttendanceCalendarState {
  final AttendanceMonthData currentData;
  final String message;

  const ProcessingAction({required this.currentData, required this.message});

  @override
  List<Object?> get props => [currentData, message];
}

/// Action completed successfully
class ActionCompleted extends AttendanceCalendarState {
  final AttendanceMonthData updatedData;
  final String message;

  const ActionCompleted({required this.updatedData, required this.message});

  @override
  List<Object?> get props => [updatedData, message];
}

/// Error state
class AttendanceCalendarError extends AttendanceCalendarState {
  final String message;
  final AttendanceMonthData? currentData;

  const AttendanceCalendarError({required this.message, this.currentData});

  @override
  List<Object?> get props => [message, currentData];
}
