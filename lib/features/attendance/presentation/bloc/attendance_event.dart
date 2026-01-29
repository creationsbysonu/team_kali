part of 'attendance_bloc.dart';

abstract class AttendanceEvent extends Equatable {
  const AttendanceEvent();

  @override
  List<Object?> get props => [];
}

class LoadPersonsEvent extends AttendanceEvent {
  final String personType;

  const LoadPersonsEvent({required this.personType});

  @override
  List<Object?> get props => [personType];
}

class MarkAttendanceEvent extends AttendanceEvent {
  final String personType;
  final String personId;
  final DateTime date;
  final String status;
  final String? reason;

  const MarkAttendanceEvent({
    required this.personType,
    required this.personId,
    required this.date,
    required this.status,
    this.reason,
  });

  @override
  List<Object?> get props => [personType, personId, date, status, reason];
}

class LoadAttendanceCalendarEvent extends AttendanceEvent {
  final String personType;
  final String personId;
  final DateTime startDate;
  final DateTime endDate;

  const LoadAttendanceCalendarEvent({
    required this.personType,
    required this.personId,
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [personType, personId, startDate, endDate];
}

class MarkSingleAttendanceEvent extends AttendanceEvent {
  final String personType;
  final String personId;
  final DateTime date;
  final String status;
  final String? reason;

  const MarkSingleAttendanceEvent({
    required this.personType,
    required this.personId,
    required this.date,
    required this.status,
    this.reason,
  });

  @override
  List<Object?> get props => [personType, personId, date, status, reason];
}

class BulkMarkAttendanceEvent extends AttendanceEvent {
  final List<Map<String, dynamic>> attendanceData;

  const BulkMarkAttendanceEvent({required this.attendanceData});

  @override
  List<Object?> get props => [attendanceData];
}
