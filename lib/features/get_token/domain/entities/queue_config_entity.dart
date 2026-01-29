import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:sewa_sathi/features/get_token/domain/entities/staff_service_entity.dart';

/// Booking type for tokens.
enum BookingType { regular, prebooked, emergency }

/// Document required for service.
class DocumentRequired extends Equatable {
  final String name;
  final String? sampleImageUrl;
  final String? description;
  final bool isRequired;

  const DocumentRequired({
    required this.name,
    this.sampleImageUrl,
    this.description,
    this.isRequired = true,
  });

  @override
  List<Object?> get props => [name, sampleImageUrl, description, isRequired];

  bool get hasSample => sampleImageUrl != null && sampleImageUrl!.isNotEmpty;
}

/// Prebooking configuration info.
class PrebookingInfo extends Equatable {
  final bool allowed;
  final int? leadHours;
  final int? quotaPerDay;
  final String message;

  const PrebookingInfo({
    required this.allowed,
    this.leadHours,
    this.quotaPerDay,
    required this.message,
  });

  @override
  List<Object?> get props => [allowed, leadHours, quotaPerDay, message];
}

/// Emergency booking configuration info.
class EmergencyInfo extends Equatable {
  final bool allowed;
  final String? fee;
  final int? quotaPerDay;
  final String message;

  const EmergencyInfo({
    required this.allowed,
    this.fee,
    this.quotaPerDay,
    required this.message,
  });

  @override
  List<Object?> get props => [allowed, fee, quotaPerDay, message];

  /// Get fee as double.
  double get feeAmount {
    if (fee == null) return 0.0;
    return double.tryParse(fee!) ?? 0.0;
  }
}

/// Progress step for multi-step services in queue config.
/// Different from TokenProgressStep which tracks token status progress.
class ConfigProgressStep extends Equatable {
  final String id;
  final int stepOrder;
  final String title;
  final String? description;

  const ConfigProgressStep({
    required this.id,
    required this.stepOrder,
    required this.title,
    this.description,
  });

  @override
  List<Object?> get props => [id, stepOrder, title, description];

  /// Alias for title
  String get name => title;
}

/// Ministry official with attendance.
class Official extends Equatable {
  final String id;
  final String name;
  final String role;
  final String attendanceStatus;
  final bool isPresentToday;
  final String? imageUrl;

  const Official({
    required this.id,
    required this.name,
    required this.role,
    required this.attendanceStatus,
    required this.isPresentToday,
    this.imageUrl,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    role,
    attendanceStatus,
    isPresentToday,
    imageUrl,
  ];

  /// Alias for role
  String get designation => role;

  /// Check if official is available
  bool get isAvailable => isPresentToday;

  /// Check if official has image
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
}

/// Availability status with color coding.
class AvailabilityStatus extends Equatable {
  final bool available;
  final String reason;
  final String reasonCode;
  final int? currentQueueLength;
  final int? estimatedWaitMinutes;
  final String? nextAvailableSlot;

  const AvailabilityStatus({
    required this.available,
    required this.reason,
    required this.reasonCode,
    this.currentQueueLength,
    this.estimatedWaitMinutes,
    this.nextAvailableSlot,
  });

  @override
  List<Object?> get props => [
    available,
    reason,
    reasonCode,
    currentQueueLength,
    estimatedWaitMinutes,
    nextAvailableSlot,
  ];

  /// Alias for available
  bool get isAcceptingTokens => available;

  /// Get estimated wait time display
  String get estimatedWaitTimeDisplay {
    if (estimatedWaitMinutes == null) return 'N/A';
    if (estimatedWaitMinutes! < 60) {
      return '$estimatedWaitMinutes min';
    }
    final hours = estimatedWaitMinutes! ~/ 60;
    final mins = estimatedWaitMinutes! % 60;
    if (mins == 0) return '${hours}h';
    return '${hours}h ${mins}m';
  }

  /// Get status color based on reason code.
  Color get statusColor {
    switch (reasonCode.toUpperCase()) {
      case 'AVAILABLE':
        return const Color(0xFF4CAF50); // Green
      case 'CAPACITY_FULL':
      case 'STAFF_ABSENT':
        return const Color(0xFFDC143C); // Red
      case 'SATURDAY':
      case 'HOLIDAY':
      case 'SERVICE_PAUSED':
        return const Color(0xFFF57C00); // Orange
      default:
        return const Color(0xFF757575); // Grey
    }
  }

  /// Get availability code enum.
  AvailabilityCode get code {
    switch (reasonCode.toUpperCase()) {
      case 'AVAILABLE':
        return AvailabilityCode.available;
      case 'QUEUE_INACTIVE':
      case 'SERVICE_INACTIVE':
      case 'SERVICE_PAUSED':
        return AvailabilityCode.queueInactive;
      case 'NO_QUEUE_CONFIG':
        return AvailabilityCode.noQueueConfig;
      case 'SATURDAY':
        return AvailabilityCode.saturday;
      case 'HOLIDAY':
        return AvailabilityCode.holiday;
      case 'STAFF_ABSENT':
      case 'CAPACITY_FULL':
        return AvailabilityCode.staffAbsent;
      default:
        return AvailabilityCode.unknown;
    }
  }
}

/// Complete queue configuration details for a service.
class QueueConfigEntity extends Equatable {
  final String id;
  final String serviceName;
  final String? serviceLogoUrl;
  final String staffName;
  final String? staffImageUrl;
  final String ministryName;

  // Office hours
  final String officeHours;
  final String officeStartTime;
  final String officeEndTime;
  final String? lunchBreak;
  final String? lunchStartTime;
  final String? lunchEndTime;

  // Service timing
  final int averageServiceTimeMinutes;
  final String averageServiceTimeDisplay;
  final int dailyCapacity;

  // Required documents
  final List<DocumentRequired> documentsRequired;

  // Prebooking config
  final bool prebookingAllowed;
  final PrebookingInfo? prebookingInfo;

  // Emergency config
  final bool emergencyAllowed;
  final EmergencyInfo? emergencyInfo;

  // Progress tracking
  final bool progressTrackingEnabled;
  final List<ConfigProgressStep> progressSteps;

  // Officials
  final List<Official> officials;

  // Availability
  final bool isAvailableToday;
  final AvailabilityStatus availabilityStatus;
  final int tokensAvailableToday;
  final int tokensBookedToday;
  final int? currentToken;
  final String estimatedWaitTime;

  final bool active;

  const QueueConfigEntity({
    required this.id,
    required this.serviceName,
    this.serviceLogoUrl,
    required this.staffName,
    this.staffImageUrl,
    required this.ministryName,
    required this.officeHours,
    required this.officeStartTime,
    required this.officeEndTime,
    this.lunchBreak,
    this.lunchStartTime,
    this.lunchEndTime,
    required this.averageServiceTimeMinutes,
    required this.averageServiceTimeDisplay,
    required this.dailyCapacity,
    required this.documentsRequired,
    required this.prebookingAllowed,
    this.prebookingInfo,
    required this.emergencyAllowed,
    this.emergencyInfo,
    required this.progressTrackingEnabled,
    required this.progressSteps,
    required this.officials,
    required this.isAvailableToday,
    required this.availabilityStatus,
    required this.tokensAvailableToday,
    required this.tokensBookedToday,
    this.currentToken,
    required this.estimatedWaitTime,
    required this.active,
  });

  @override
  List<Object?> get props => [
    id,
    serviceName,
    serviceLogoUrl,
    staffName,
    staffImageUrl,
    ministryName,
    officeHours,
    officeStartTime,
    officeEndTime,
    lunchBreak,
    lunchStartTime,
    lunchEndTime,
    averageServiceTimeMinutes,
    averageServiceTimeDisplay,
    dailyCapacity,
    documentsRequired,
    prebookingAllowed,
    prebookingInfo,
    emergencyAllowed,
    emergencyInfo,
    progressTrackingEnabled,
    progressSteps,
    officials,
    isAvailableToday,
    availabilityStatus,
    tokensAvailableToday,
    tokensBookedToday,
    currentToken,
    estimatedWaitTime,
    active,
  ];

  /// Calculate remaining slots.
  int get remainingSlots => tokensAvailableToday;

  /// Check if has lunch break.
  bool get hasLunchBreak => lunchBreak != null && lunchBreak!.isNotEmpty;

  /// Check if has documents.
  bool get hasDocuments => documentsRequired.isNotEmpty;

  /// Check if has officials.
  bool get hasOfficials => officials.isNotEmpty;

  /// Check if all officials are present.
  bool get allOfficialsPresent => officials.every((o) => o.isPresentToday);

  /// Get absent officials.
  List<Official> get absentOfficials =>
      officials.where((o) => !o.isPresentToday).toList();

  /// Alias getters for UI compatibility
  String get openingTime => officeStartTime;
  String get closingTime => officeEndTime;
  int get dailyTokenLimit => dailyCapacity;

  /// Check if prebooking is enabled
  bool get isPrebookingEnabled => prebookingAllowed;

  /// Check if emergency is enabled
  bool get isEmergencyEnabled => emergencyAllowed;
}
