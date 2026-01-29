import 'package:sewa_web/features/attendance/domain/entities/attendance_day.dart';
import 'package:sewa_web/features/attendance/domain/entities/attendance_month_data.dart';
import 'package:sewa_web/features/attendance/domain/entities/attendance_record.dart';
import 'package:sewa_web/features/attendance/domain/entities/holiday.dart';

/// Service to build attendance month data with proper logic
/// - Default: PRESENT (green)
/// - Saturdays: ABSENT (gray, not editable)
/// - Holidays: ABSENT (orange, not editable)
/// - Manual absence: ABSENT (red, editable)
class AttendanceMonthBuilder {
  /// Build complete month data from absence records and holidays
  static AttendanceMonthData buildMonth({
    required String personId,
    required String personName,
    required PersonType personType,
    required int year,
    required int month,
    required List<AttendanceRecord> absenceRecords,
    required List<Holiday> holidays,
  }) {
    // Get all days in the month
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final days = <AttendanceDay>[];

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      days.add(_buildDay(date, absenceRecords, holidays));
    }

    return AttendanceMonthData(
      personId: personId,
      personName: personName,
      personType: personType,
      year: year,
      month: month,
      days: days,
    );
  }

  /// Build a single attendance day with proper logic
  static AttendanceDay _buildDay(
    DateTime date,
    List<AttendanceRecord> absenceRecords,
    List<Holiday> holidays,
  ) {
    // Priority 1: Check if it's Saturday
    if (date.weekday == DateTime.saturday) {
      return AttendanceDay(
        date: date,
        type: AttendanceDayType.saturday,
        reason: 'Saturday - Weekly Holiday',
        isEditable: false, // Cannot click/edit
      );
    }

    // Priority 2: Check if it's a holiday
    final holiday = holidays.where((h) => h.fallsOn(date)).firstOrNull;
    if (holiday != null) {
      return AttendanceDay(
        date: date,
        type: AttendanceDayType.holiday,
        holiday: holiday,
        reason: holiday.name,
        isEditable: false, // Cannot click/edit
      );
    }

    // Priority 3: Check if there's a manual absence record
    final absenceRecord = absenceRecords
        .where(
          (record) =>
              record.date.year == date.year &&
              record.date.month == date.month &&
              record.date.day == date.day &&
              record.status == AttendanceStatus.absent,
        )
        .firstOrNull;

    if (absenceRecord != null) {
      return AttendanceDay(
        date: date,
        type: AttendanceDayType.absent,
        recordId: absenceRecord.id,
        reason: absenceRecord.reason,
        isEditable: true, // Can click to view/remove
      );
    }

    // Default: PRESENT (no record exists)
    return AttendanceDay(
      date: date,
      type: AttendanceDayType.present,
      isEditable: true, // Can click to mark absent
    );
  }

  /// Update a day in the month data (after marking/removing absence)
  static AttendanceMonthData updateDay({
    required AttendanceMonthData monthData,
    required AttendanceDay updatedDay,
  }) {
    final updatedDays = monthData.days.map((day) {
      if (day.date.year == updatedDay.date.year &&
          day.date.month == updatedDay.date.month &&
          day.date.day == updatedDay.date.day) {
        return updatedDay;
      }
      return day;
    }).toList();

    return monthData.copyWith(days: updatedDays);
  }
}

/// Extension to safely get first element or null
extension IterableExtension<T> on Iterable<T> {
  T? get firstOrNull {
    try {
      return first;
    } catch (e) {
      return null;
    }
  }
}
