part of 'attendance_bloc.dart';

abstract class AttendanceState extends Equatable {
  const AttendanceState();

  @override
  List<Object?> get props => [];
}

class AttendanceInitial extends AttendanceState {}

class AttendanceLoading extends AttendanceState {}

class PersonsLoaded extends AttendanceState {
  final List<Map<String, String>> persons;

  const PersonsLoaded({required this.persons});

  @override
  List<Object?> get props => [persons];
}

class AttendanceCalendarLoaded extends AttendanceState {
  final AttendanceCalendarData calendarData;

  const AttendanceCalendarLoaded({required this.calendarData});

  List<AttendanceRecord> get attendanceRecords => calendarData.records;
  List<DateTime> get holidays =>
      []; // TODO: Get from calendarData when implemented

  @override
  List<Object?> get props => [calendarData];
}

class AttendanceError extends AttendanceState {
  final String message;

  const AttendanceError({required this.message});

  @override
  List<Object?> get props => [message];
}

class AttendanceOperationInProgress extends AttendanceState {
  final AttendanceCalendarData calendarData;

  const AttendanceOperationInProgress({required this.calendarData});

  @override
  List<Object?> get props => [calendarData];
}

class AttendanceOperationSuccess extends AttendanceState {
  final String message;
  final AttendanceCalendarData calendarData;

  const AttendanceOperationSuccess({
    required this.message,
    required this.calendarData,
  });

  @override
  List<Object?> get props => [message, calendarData];
}

class AttendanceOperationError extends AttendanceState {
  final String message;
  final AttendanceCalendarData calendarData;

  const AttendanceOperationError({
    required this.message,
    required this.calendarData,
  });

  @override
  List<Object?> get props => [message, calendarData];
}
