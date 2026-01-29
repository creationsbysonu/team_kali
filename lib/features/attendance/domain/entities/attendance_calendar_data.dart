import 'package:equatable/equatable.dart';
import 'package:sewa_web/features/attendance/domain/entities/attendance_record.dart';

/// Attendance Calendar Data - contains attendance records for a person
class AttendanceCalendarData extends Equatable {
  final String personId;
  final String personName;
  final PersonType personType;
  final DateTime startDate;
  final DateTime endDate;
  final List<AttendanceRecord> records;
  final int totalDays;
  final int presentDays;
  final int absentDays;
  final double attendancePercentage;

  const AttendanceCalendarData({
    required this.personId,
    required this.personName,
    required this.personType,
    required this.startDate,
    required this.endDate,
    required this.records,
    required this.totalDays,
    required this.presentDays,
    required this.absentDays,
    required this.attendancePercentage,
  });

  @override
  List<Object?> get props => [
    personId,
    personName,
    personType,
    startDate,
    endDate,
    records,
    totalDays,
    presentDays,
    absentDays,
    attendancePercentage,
  ];

  /// Get attendance record for a specific date
  AttendanceRecord? getRecordForDate(DateTime date) {
    try {
      return records.firstWhere(
        (record) =>
            record.date.year == date.year &&
            record.date.month == date.month &&
            record.date.day == date.day,
      );
    } catch (e) {
      return null;
    }
  }

  AttendanceCalendarData copyWith({
    String? personId,
    String? personName,
    PersonType? personType,
    DateTime? startDate,
    DateTime? endDate,
    List<AttendanceRecord>? records,
    int? totalDays,
    int? presentDays,
    int? absentDays,
    double? attendancePercentage,
  }) {
    return AttendanceCalendarData(
      personId: personId ?? this.personId,
      personName: personName ?? this.personName,
      personType: personType ?? this.personType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      records: records ?? this.records,
      totalDays: totalDays ?? this.totalDays,
      presentDays: presentDays ?? this.presentDays,
      absentDays: absentDays ?? this.absentDays,
      attendancePercentage: attendancePercentage ?? this.attendancePercentage,
    );
  }
}
