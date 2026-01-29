import 'package:equatable/equatable.dart';
import 'package:sewa_web/features/attendance/domain/entities/attendance_day.dart';
import 'package:sewa_web/features/attendance/domain/entities/attendance_record.dart';

/// Complete attendance data for a month with computed states
class AttendanceMonthData extends Equatable {
  final String personId;
  final String personName;
  final PersonType personType;
  final int year;
  final int month;
  final List<AttendanceDay> days;

  const AttendanceMonthData({
    required this.personId,
    required this.personName,
    required this.personType,
    required this.year,
    required this.month,
    required this.days,
  });

  @override
  List<Object?> get props => [
    personId,
    personName,
    personType,
    year,
    month,
    days,
  ];

  /// Get attendance day for a specific date
  AttendanceDay? getDayForDate(DateTime date) {
    try {
      return days.firstWhere(
        (day) =>
            day.date.year == date.year &&
            day.date.month == date.month &&
            day.date.day == date.day,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get total present days
  int get totalPresentDays =>
      days.where((day) => day.type == AttendanceDayType.present).length;

  /// Get total absent days (manual only)
  int get totalAbsentDays =>
      days.where((day) => day.type == AttendanceDayType.absent).length;

  /// Get total Saturdays
  int get totalSaturdays =>
      days.where((day) => day.type == AttendanceDayType.saturday).length;

  /// Get total holidays
  int get totalHolidays =>
      days.where((day) => day.type == AttendanceDayType.holiday).length;

  /// Get working days (exclude Saturdays and holidays)
  int get totalWorkingDays => days.length - totalSaturdays - totalHolidays;

  /// Get attendance percentage (present / working days)
  double get attendancePercentage {
    if (totalWorkingDays == 0) return 0.0;
    return (totalPresentDays / totalWorkingDays) * 100;
  }

  AttendanceMonthData copyWith({
    String? personId,
    String? personName,
    PersonType? personType,
    int? year,
    int? month,
    List<AttendanceDay>? days,
  }) {
    return AttendanceMonthData(
      personId: personId ?? this.personId,
      personName: personName ?? this.personName,
      personType: personType ?? this.personType,
      year: year ?? this.year,
      month: month ?? this.month,
      days: days ?? this.days,
    );
  }
}
