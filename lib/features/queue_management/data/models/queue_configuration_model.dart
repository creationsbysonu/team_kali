import 'package:flutter/material.dart';
import 'package:sewa_web/features/queue_management/domain/entities/progress_step.dart';
import 'package:sewa_web/features/queue_management/domain/entities/queue_configuration.dart';

/// Progress Step Model - extends entity with JSON serialization
class ProgressStepModel extends ProgressStep {
  const ProgressStepModel({
    required super.id,
    required super.title,
    required super.stepOrder,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ProgressStepModel.fromJson(Map<String, dynamic> json) {
    return ProgressStepModel(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      stepOrder: json['step_order'] ?? 0,
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
      'title': title,
      'step_order': stepOrder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// For creating new steps (without id)
  Map<String, dynamic> toCreateJson() {
    return {'title': title, 'step_order': stepOrder};
  }
}

/// Higher Official Detail Model
class HigherOfficialDetailModel extends HigherOfficialDetail {
  const HigherOfficialDetailModel({
    required super.id,
    required super.name,
    required super.role,
  });

  factory HigherOfficialDetailModel.fromJson(Map<String, dynamic> json) {
    return HigherOfficialDetailModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'role': role};
  }
}

/// Queue Configuration Model - extends entity with JSON serialization
class QueueConfigurationModel extends QueueConfiguration {
  const QueueConfigurationModel({
    required super.id,
    required super.staffServiceId,
    required super.staffServiceName,
    super.ministryId,
    super.ministryName,
    required super.officeStartTime,
    required super.officeEndTime,
    super.lunchStartTime,
    super.lunchEndTime,
    required super.averageServiceTimeMinutes,
    required super.calculatedDailyCapacity,
    required super.documentsRequired,
    required super.prebookingAllowed,
    super.prebookingLeadHours,
    super.prebookingQuotaPerDay,
    required super.emergencyAllowed,
    super.emergencyFee,
    super.emergencyQuotaPerDay,
    super.higherOfficialIds = const [],
    super.higherOfficialsDetails = const [],
    required super.enableProgressTracking,
    super.progressSteps = const [],
    required super.active,
    required super.createdAt,
    required super.updatedAt,
  });

  factory QueueConfigurationModel.fromJson(Map<String, dynamic> json) {
    return QueueConfigurationModel(
      id: json['id'].toString(),
      staffServiceId: json['staff_service'].toString(),
      staffServiceName: json['staff_service_name'] ?? '',
      ministryId: json['ministry']?.toString(),
      ministryName: json['ministry_name'],
      officeStartTime: _parseTime(json['office_start_time']),
      officeEndTime: _parseTime(json['office_end_time']),
      lunchStartTime: json['lunch_start_time'] != null
          ? _parseTime(json['lunch_start_time'])
          : null,
      lunchEndTime: json['lunch_end_time'] != null
          ? _parseTime(json['lunch_end_time'])
          : null,
      averageServiceTimeMinutes: json['average_service_time_minutes'] ?? 0,
      calculatedDailyCapacity: json['calculated_daily_capacity'] ?? 0,
      documentsRequired:
          (json['documents_required'] as List?)
              ?.map(
                (doc) => DocumentRequired(
                  name: doc['name'] ?? '',
                  sampleImageUrl: doc['sample_image_url'] ?? '',
                ),
              )
              .toList() ??
          [],
      prebookingAllowed: json['prebooking_allowed'] ?? false,
      prebookingLeadHours: json['prebooking_lead_hours'],
      prebookingQuotaPerDay: json['prebooking_quota_per_day'],
      emergencyAllowed: json['emergency_allowed'] ?? false,
      emergencyFee: json['emergency_fee']?.toDouble(),
      emergencyQuotaPerDay: json['emergency_quota_per_day'],
      // Parse multiple higher officials
      higherOfficialIds:
          (json['higher_officials'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      higherOfficialsDetails:
          (json['higher_officials_details'] as List?)
              ?.map((e) => HigherOfficialDetailModel.fromJson(e))
              .toList() ??
          [],
      enableProgressTracking: json['progress_tracking_enabled'] ?? false,
      progressSteps:
          (json['progress_steps'] as List?)
              ?.map((step) => ProgressStepModel.fromJson(step))
              .toList() ??
          [],
      active: json['active'] ?? true,
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
      'staff_service': staffServiceId,
      'staff_service_name': staffServiceName,
      'ministry': ministryId,
      'ministry_name': ministryName,
      'office_start_time': _formatTime(officeStartTime),
      'office_end_time': _formatTime(officeEndTime),
      'lunch_start_time': lunchStartTime != null
          ? _formatTime(lunchStartTime!)
          : null,
      'lunch_end_time': lunchEndTime != null
          ? _formatTime(lunchEndTime!)
          : null,
      'average_service_time_minutes': averageServiceTimeMinutes,
      'calculated_daily_capacity': calculatedDailyCapacity,
      'documents_required': documentsRequired
          .map(
            (doc) => {'name': doc.name, 'sample_image_url': doc.sampleImageUrl},
          )
          .toList(),
      'prebooking_allowed': prebookingAllowed,
      'prebooking_lead_hours': prebookingLeadHours,
      'prebooking_quota_per_day': prebookingQuotaPerDay,
      'emergency_allowed': emergencyAllowed,
      'emergency_fee': emergencyFee,
      'emergency_quota_per_day': emergencyQuotaPerDay,
      'higher_officials': higherOfficialIds,
      'progress_tracking_enabled': enableProgressTracking,
      'progress_steps': progressSteps
          .map((step) => {'title': step.title, 'step_order': step.stepOrder})
          .toList(),
      'active': active,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  static String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
  }

  factory QueueConfigurationModel.fromEntity(QueueConfiguration entity) {
    return QueueConfigurationModel(
      id: entity.id,
      staffServiceId: entity.staffServiceId,
      staffServiceName: entity.staffServiceName,
      ministryId: entity.ministryId,
      ministryName: entity.ministryName,
      officeStartTime: entity.officeStartTime,
      officeEndTime: entity.officeEndTime,
      lunchStartTime: entity.lunchStartTime,
      lunchEndTime: entity.lunchEndTime,
      averageServiceTimeMinutes: entity.averageServiceTimeMinutes,
      calculatedDailyCapacity: entity.calculatedDailyCapacity,
      documentsRequired: entity.documentsRequired,
      prebookingAllowed: entity.prebookingAllowed,
      prebookingLeadHours: entity.prebookingLeadHours,
      prebookingQuotaPerDay: entity.prebookingQuotaPerDay,
      emergencyAllowed: entity.emergencyAllowed,
      emergencyFee: entity.emergencyFee,
      emergencyQuotaPerDay: entity.emergencyQuotaPerDay,
      higherOfficialIds: entity.higherOfficialIds,
      higherOfficialsDetails: entity.higherOfficialsDetails,
      enableProgressTracking: entity.enableProgressTracking,
      progressSteps: entity.progressSteps,
      active: entity.active,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
