import 'package:sewa_web/features/attendance/domain/entities/attendance_record.dart';

/// Attendance Record Model - extends entity with JSON serialization
class AttendanceRecordModel extends AttendanceRecord {
  const AttendanceRecordModel({
    required super.id,
    required super.personType,
    required super.personId,
    required super.personName,
    super.personEmail,
    required super.date,
    required super.status,
    super.reason,
    required super.isSaturday,
    required super.createdAt,
    required super.updatedAt,
  });

  factory AttendanceRecordModel.fromJson(Map<String, dynamic> json) {
    // Backend returns simple record structure without person metadata
    return AttendanceRecordModel(
      id:
          json['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      personType: PersonType.staff, // Will be set by caller
      personId: json['person_id']?.toString() ?? '',
      personName: json['person_name']?.toString() ?? '',
      personEmail: json['person_email'],
      date: DateTime.parse(json['date']),
      status: AttendanceStatus.fromString(json['status']),
      reason: json['reason'],
      isSaturday: json['is_saturday'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'person_type': personType.value,
      'person_id': personId,
      'person_name': personName,
      'person_email': personEmail,
      'date': date.toIso8601String(),
      'status': status.value,
      'reason': reason,
      'is_saturday': isSaturday,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory AttendanceRecordModel.fromEntity(AttendanceRecord entity) {
    return AttendanceRecordModel(
      id: entity.id,
      personType: entity.personType,
      personId: entity.personId,
      personName: entity.personName,
      personEmail: entity.personEmail,
      date: entity.date,
      status: entity.status,
      reason: entity.reason,
      isSaturday: entity.isSaturday,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
