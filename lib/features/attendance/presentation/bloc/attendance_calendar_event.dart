part of 'attendance_calendar_bloc.dart';

/// Events for attendance calendar
abstract class AttendanceCalendarEvent extends Equatable {
  const AttendanceCalendarEvent();

  @override
  List<Object?> get props => [];
}

/// Load persons list (staff or officials)
class LoadPersonsListEvent extends AttendanceCalendarEvent {
  final String personType;

  const LoadPersonsListEvent({required this.personType});

  @override
  List<Object?> get props => [personType];
}

/// Load attendance month data
class LoadAttendanceMonthEvent extends AttendanceCalendarEvent {
  final String personType;
  final String personId;
  final int year;
  final int month;

  const LoadAttendanceMonthEvent({
    required this.personType,
    required this.personId,
    required this.year,
    required this.month,
  });

  @override
  List<Object?> get props => [personType, personId, year, month];
}

/// Mark a day as absent
class MarkDayAbsentEvent extends AttendanceCalendarEvent {
  final DateTime date;
  final String reason;

  const MarkDayAbsentEvent({required this.date, required this.reason});

  @override
  List<Object?> get props => [date, reason];
}

/// Remove an absence record (back to present)
class RemoveAbsenceEvent extends AttendanceCalendarEvent {
  final String recordId;
  final DateTime date;

  const RemoveAbsenceEvent({required this.recordId, required this.date});

  @override
  List<Object?> get props => [recordId, date];
}

/// Change selected person
class ChangePersonEvent extends AttendanceCalendarEvent {
  final String personId;
  final String personName;

  const ChangePersonEvent({required this.personId, required this.personName});

  @override
  List<Object?> get props => [personId, personName];
}

/// Change month/year
class ChangeMonthEvent extends AttendanceCalendarEvent {
  final int year;
  final int month;

  const ChangeMonthEvent({required this.year, required this.month});

  @override
  List<Object?> get props => [year, month];
}
