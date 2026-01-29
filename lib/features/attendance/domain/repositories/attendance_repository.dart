import 'package:dartz/dartz.dart';
import 'package:sewa_web/core/errors/failures.dart';
import 'package:sewa_web/features/attendance/domain/entities/attendance_calendar_data.dart';
import 'package:sewa_web/features/attendance/domain/entities/attendance_record.dart';

/// Attendance Repository Interface
abstract class AttendanceRepository {
  /// Get list of persons (staff or officials) for selection
  Future<Either<Failure, List<Map<String, String>>>> getPersons({
    required String personType,
    String? ministryId,
  });

  /// Get attendance calendar for a person
  Future<Either<Failure, AttendanceCalendarData>> getAttendanceCalendar({
    required String personType,
    required String personId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Mark attendance for a single person
  Future<Either<Failure, AttendanceRecord>> markAttendance({
    required String personType,
    required String personId,
    required DateTime date,
    required String status,
    String? reason,
  });

  /// Bulk mark attendance for multiple people
  Future<Either<Failure, List<AttendanceRecord>>> bulkMarkAttendance({
    required List<Map<String, dynamic>> attendanceData,
  });
}
