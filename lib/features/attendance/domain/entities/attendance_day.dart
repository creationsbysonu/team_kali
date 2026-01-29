import 'package:equatable/equatable.dart';
import 'package:sewa_web/features/attendance/domain/entities/holiday.dart';

/// Represents the attendance state for a single day
enum AttendanceDayType {
  present, // Default - Green
  absent, // Manual absence - Red
  saturday, // Auto absent - Gray
  holiday, // Auto absent - Orange
}

/// Single day attendance state with all metadata
class AttendanceDay extends Equatable {
  final DateTime date;
  final AttendanceDayType type;
  final String? recordId; // Backend record ID if exists
  final String? reason; // Absence reason
  final Holiday? holiday; // Holiday details if applicable
  final bool isEditable; // Can user click to change?

  const AttendanceDay({
    required this.date,
    required this.type,
    this.recordId,
    this.reason,
    this.holiday,
    required this.isEditable,
  });

  @override
  List<Object?> get props => [
    date,
    type,
    recordId,
    reason,
    holiday,
    isEditable,
  ];

  /// Check if this day is present (green)
  bool get isPresent => type == AttendanceDayType.present;

  /// Check if this day is manually marked absent (red)
  bool get isAbsent => type == AttendanceDayType.absent;

  /// Check if this day is Saturday (gray)
  bool get isSaturday => type == AttendanceDayType.saturday;

  /// Check if this day is a holiday (orange)
  bool get isHoliday => type == AttendanceDayType.holiday;

  /// Get display color
  String get displayColor {
    switch (type) {
      case AttendanceDayType.present:
        return '#4CAF50'; // Green
      case AttendanceDayType.absent:
        return '#F44336'; // Red
      case AttendanceDayType.saturday:
        return '#9E9E9E'; // Gray
      case AttendanceDayType.holiday:
        return '#FF9800'; // Orange
    }
  }

  /// Get status text
  String get statusText {
    switch (type) {
      case AttendanceDayType.present:
        return 'Present';
      case AttendanceDayType.absent:
        return reason ?? 'Absent';
      case AttendanceDayType.saturday:
        return 'Saturday';
      case AttendanceDayType.holiday:
        return holiday?.name ?? 'Holiday';
    }
  }

  AttendanceDay copyWith({
    DateTime? date,
    AttendanceDayType? type,
    String? recordId,
    String? reason,
    Holiday? holiday,
    bool? isEditable,
  }) {
    return AttendanceDay(
      date: date ?? this.date,
      type: type ?? this.type,
      recordId: recordId ?? this.recordId,
      reason: reason ?? this.reason,
      holiday: holiday ?? this.holiday,
      isEditable: isEditable ?? this.isEditable,
    );
  }
}
