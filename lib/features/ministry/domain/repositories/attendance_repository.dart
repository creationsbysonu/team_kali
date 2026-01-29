import 'package:dartz/dartz.dart';
import 'package:sewa_web/core/errors/failures.dart';
import 'package:sewa_web/features/ministry/domain/entities/attendance_record.dart';

/// Attendance calendar data with holidays
class AttendanceCalendarData {
  final List<AttendanceRecord> attendances;
  final List<DateTime> holidays;
  final List<DateTime> saturdays;

  const AttendanceCalendarData({
    required this.attendances,
    required this.holidays,
    required this.saturdays,
  });
}

/// Abstract repository for Attendance operations
abstract class AttendanceRepository {
  /// Get attendance calendar for a person
  Future<Either<Failure, AttendanceCalendarData>> getAttendanceCalendar({
    required PersonType personType,
    required String personId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Mark attendance for a single date
  Future<Either<Failure, AttendanceRecord>> markAttendance({
    required PersonType personType,
    required String personId,
    required DateTime date,
    required AttendanceStatus status,
    String? reason,
  });

  /// Bulk mark attendance for a date range
  Future<Either<Failure, int>> bulkMarkAttendance({
    required PersonType personType,
    required String personId,
    required DateTime startDate,
    required DateTime endDate,
    required AttendanceStatus status,
    String? reason,
  });

  /// Get attendance record by ID
  Future<Either<Failure, AttendanceRecord>> getAttendanceById(String id);

  /// Update attendance record
  Future<Either<Failure, AttendanceRecord>> updateAttendance({
    required String id,
    required AttendanceStatus status,
    String? reason,
  });
}
