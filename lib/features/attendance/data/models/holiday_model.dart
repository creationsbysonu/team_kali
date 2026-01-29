import 'package:sewa_web/features/attendance/domain/entities/holiday.dart';

/// Holiday model with JSON serialization
class HolidayModel extends Holiday {
  const HolidayModel({
    required super.id,
    required super.name,
    required super.date,
    super.description,
    super.isRecurring,
  });

  factory HolidayModel.fromJson(Map<String, dynamic> json) {
    return HolidayModel(
      id: json['id'].toString(),
      name: json['name'] ?? json['title'] ?? 'Holiday',
      date: DateTime.parse(json['date']),
      description: json['description'],
      isRecurring: json['is_recurring'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'date': date.toIso8601String(),
      'description': description,
      'is_recurring': isRecurring,
    };
  }

  factory HolidayModel.fromEntity(Holiday entity) {
    return HolidayModel(
      id: entity.id,
      name: entity.name,
      date: entity.date,
      description: entity.description,
      isRecurring: entity.isRecurring,
    );
  }
}
