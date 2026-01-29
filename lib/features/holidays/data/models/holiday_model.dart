import 'package:sewa_web/features/holidays/domain/entities/holiday.dart';

/// Holiday Model - extends entity and adds JSON serialization
class HolidayModel extends Holiday {
  const HolidayModel({
    required super.id,
    required super.name,
    required super.date,
    super.description,
    required super.createdAt,
    required super.updatedAt,
  });

  /// Create model from JSON
  factory HolidayModel.fromJson(Map<String, dynamic> json) {
    return HolidayModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      description: json['description']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  /// Convert model to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'date': date.toIso8601String().split('T')[0],
      'description': description,
    };
  }

  /// Create model from entity
  factory HolidayModel.fromEntity(Holiday entity) {
    return HolidayModel(
      id: entity.id,
      name: entity.name,
      date: entity.date,
      description: entity.description,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
