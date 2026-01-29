import 'package:equatable/equatable.dart';

/// Person type for attendance
enum PersonType {
  staff('STAFF'),
  official('OFFICIAL');

  final String value;
  const PersonType(this.value);

  static PersonType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'STAFF':
        return PersonType.staff;
      case 'OFFICIAL':
        return PersonType.official;
      default:
        return PersonType.staff;
    }
  }
}

/// Attendance status
enum AttendanceStatus {
  present('PRESENT'),
  absent('ABSENT');

  final String value;
  const AttendanceStatus(this.value);

  static AttendanceStatus fromString(String value) {
    switch (value.toUpperCase()) {
      case 'PRESENT':
        return AttendanceStatus.present;
      case 'ABSENT':
        return AttendanceStatus.absent;
      default:
        return AttendanceStatus.present;
    }
  }
}

/// Attendance Record entity
class AttendanceRecord extends Equatable {
  final String id;
  final PersonType personType;
  final String personId;
  final String personName;
  final String? personEmail;
  final DateTime date;
  final AttendanceStatus status;
  final String? reason;
  final bool isSaturday;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AttendanceRecord({
    required this.id,
    required this.personType,
    required this.personId,
    required this.personName,
    this.personEmail,
    required this.date,
    required this.status,
    this.reason,
    required this.isSaturday,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    personType,
    personId,
    personName,
    personEmail,
    date,
    status,
    reason,
    isSaturday,
    createdAt,
    updatedAt,
  ];

  /// Check if person is present
  bool get isPresent => status == AttendanceStatus.present;

  /// Check if person is absent
  bool get isAbsent => status == AttendanceStatus.absent;

  /// Check if it's a staff member
  bool get isStaff => personType == PersonType.staff;

  /// Check if it's an official
  bool get isOfficial => personType == PersonType.official;

  AttendanceRecord copyWith({
    String? id,
    PersonType? personType,
    String? personId,
    String? personName,
    String? personEmail,
    DateTime? date,
    AttendanceStatus? status,
    String? reason,
    bool? isSaturday,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      personType: personType ?? this.personType,
      personId: personId ?? this.personId,
      personName: personName ?? this.personName,
      personEmail: personEmail ?? this.personEmail,
      date: date ?? this.date,
      status: status ?? this.status,
      reason: reason ?? this.reason,
      isSaturday: isSaturday ?? this.isSaturday,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
