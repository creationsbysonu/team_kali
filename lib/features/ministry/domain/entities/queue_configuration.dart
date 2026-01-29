import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Document required for a service
class DocumentRequired extends Equatable {
  final String name;
  final String sampleImageUrl;

  const DocumentRequired({required this.name, required this.sampleImageUrl});

  @override
  List<Object?> get props => [name, sampleImageUrl];

  DocumentRequired copyWith({String? name, String? sampleImageUrl}) {
    return DocumentRequired(
      name: name ?? this.name,
      sampleImageUrl: sampleImageUrl ?? this.sampleImageUrl,
    );
  }
}

/// Queue Configuration for a staff service
class QueueConfiguration extends Equatable {
  final String id;
  final String staffServiceId;
  final String staffServiceName;
  final String? ministryId;
  final String? ministryName;

  // Office Hours
  final TimeOfDay officeStartTime;
  final TimeOfDay officeEndTime;
  final TimeOfDay? lunchStartTime;
  final TimeOfDay? lunchEndTime;
  final int averageServiceTimeMinutes;
  final int calculatedDailyCapacity;

  // Documents
  final List<DocumentRequired> documentsRequired;

  // Prebooking
  final bool prebookingAllowed;
  final int? prebookingLeadHours;
  final int? prebookingQuotaPerDay;

  // Emergency
  final bool emergencyAllowed;
  final double? emergencyFee;
  final int? emergencyQuotaPerDay;

  // Higher Official
  final String? higherOfficialId;
  final String? higherOfficialName;
  final String? higherOfficialRole;

  // Progress
  final bool enableProgressTracking;

  // Status
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;

  const QueueConfiguration({
    required this.id,
    required this.staffServiceId,
    required this.staffServiceName,
    this.ministryId,
    this.ministryName,
    required this.officeStartTime,
    required this.officeEndTime,
    this.lunchStartTime,
    this.lunchEndTime,
    required this.averageServiceTimeMinutes,
    required this.calculatedDailyCapacity,
    required this.documentsRequired,
    required this.prebookingAllowed,
    this.prebookingLeadHours,
    this.prebookingQuotaPerDay,
    required this.emergencyAllowed,
    this.emergencyFee,
    this.emergencyQuotaPerDay,
    this.higherOfficialId,
    this.higherOfficialName,
    this.higherOfficialRole,
    required this.enableProgressTracking,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    staffServiceId,
    staffServiceName,
    ministryId,
    ministryName,
    officeStartTime,
    officeEndTime,
    lunchStartTime,
    lunchEndTime,
    averageServiceTimeMinutes,
    calculatedDailyCapacity,
    documentsRequired,
    prebookingAllowed,
    prebookingLeadHours,
    prebookingQuotaPerDay,
    emergencyAllowed,
    emergencyFee,
    emergencyQuotaPerDay,
    higherOfficialId,
    higherOfficialName,
    higherOfficialRole,
    enableProgressTracking,
    active,
    createdAt,
    updatedAt,
  ];

  /// Calculate working hours in minutes
  int get workingMinutes {
    int totalMinutes =
        (officeEndTime.hour * 60 + officeEndTime.minute) -
        (officeStartTime.hour * 60 + officeStartTime.minute);

    if (lunchStartTime != null && lunchEndTime != null) {
      int lunchMinutes =
          (lunchEndTime!.hour * 60 + lunchEndTime!.minute) -
          (lunchStartTime!.hour * 60 + lunchStartTime!.minute);
      totalMinutes -= lunchMinutes;
    }

    return totalMinutes;
  }

  /// Calculate regular quota (total - prebooking - emergency)
  int get regularQuota {
    int quota = calculatedDailyCapacity;
    if (prebookingAllowed && prebookingQuotaPerDay != null) {
      quota -= prebookingQuotaPerDay!;
    }
    if (emergencyAllowed && emergencyQuotaPerDay != null) {
      quota -= emergencyQuotaPerDay!;
    }
    return quota > 0 ? quota : 0;
  }

  QueueConfiguration copyWith({
    String? id,
    String? staffServiceId,
    String? staffServiceName,
    String? ministryId,
    String? ministryName,
    TimeOfDay? officeStartTime,
    TimeOfDay? officeEndTime,
    TimeOfDay? lunchStartTime,
    TimeOfDay? lunchEndTime,
    int? averageServiceTimeMinutes,
    int? calculatedDailyCapacity,
    List<DocumentRequired>? documentsRequired,
    bool? prebookingAllowed,
    int? prebookingLeadHours,
    int? prebookingQuotaPerDay,
    bool? emergencyAllowed,
    double? emergencyFee,
    int? emergencyQuotaPerDay,
    String? higherOfficialId,
    String? higherOfficialName,
    String? higherOfficialRole,
    bool? enableProgressTracking,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return QueueConfiguration(
      id: id ?? this.id,
      staffServiceId: staffServiceId ?? this.staffServiceId,
      staffServiceName: staffServiceName ?? this.staffServiceName,
      ministryId: ministryId ?? this.ministryId,
      ministryName: ministryName ?? this.ministryName,
      officeStartTime: officeStartTime ?? this.officeStartTime,
      officeEndTime: officeEndTime ?? this.officeEndTime,
      lunchStartTime: lunchStartTime ?? this.lunchStartTime,
      lunchEndTime: lunchEndTime ?? this.lunchEndTime,
      averageServiceTimeMinutes:
          averageServiceTimeMinutes ?? this.averageServiceTimeMinutes,
      calculatedDailyCapacity:
          calculatedDailyCapacity ?? this.calculatedDailyCapacity,
      documentsRequired: documentsRequired ?? this.documentsRequired,
      prebookingAllowed: prebookingAllowed ?? this.prebookingAllowed,
      prebookingLeadHours: prebookingLeadHours ?? this.prebookingLeadHours,
      prebookingQuotaPerDay:
          prebookingQuotaPerDay ?? this.prebookingQuotaPerDay,
      emergencyAllowed: emergencyAllowed ?? this.emergencyAllowed,
      emergencyFee: emergencyFee ?? this.emergencyFee,
      emergencyQuotaPerDay: emergencyQuotaPerDay ?? this.emergencyQuotaPerDay,
      higherOfficialId: higherOfficialId ?? this.higherOfficialId,
      higherOfficialName: higherOfficialName ?? this.higherOfficialName,
      higherOfficialRole: higherOfficialRole ?? this.higherOfficialRole,
      enableProgressTracking:
          enableProgressTracking ?? this.enableProgressTracking,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
