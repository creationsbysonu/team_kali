import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Availability codes from backend.
/// Used to determine UI treatment for service availability.
enum AvailabilityCode {
  available,
  noQueueConfig,
  queueInactive,
  saturday,
  holiday,
  staffAbsent,
  unknown,
}

/// Staff Service entity representing a service provided by a staff member.
/// Follows Citizen API v1 ServiceListItem structure.
class StaffServiceEntity extends Equatable {
  final String id;
  final String serviceName;
  final String? serviceLogoUrl;
  final String staffName;
  final String? staffImageUrl;
  final bool isAvailableToday;
  final String? availabilityReason;
  final String? availabilityCode;
  final int tokensAvailable;
  final int? currentQueuePosition;

  const StaffServiceEntity({
    required this.id,
    required this.serviceName,
    this.serviceLogoUrl,
    required this.staffName,
    this.staffImageUrl,
    required this.isAvailableToday,
    this.availabilityReason,
    this.availabilityCode,
    this.tokensAvailable = 0,
    this.currentQueuePosition,
  });

  @override
  List<Object?> get props => [
    id,
    serviceName,
    serviceLogoUrl,
    staffName,
    staffImageUrl,
    isAvailableToday,
    availabilityReason,
    availabilityCode,
    tokensAvailable,
    currentQueuePosition,
  ];

  /// Check if service has a logo.
  bool get hasLogo => serviceLogoUrl != null && serviceLogoUrl!.isNotEmpty;

  /// Check if staff has an image.
  bool get hasStaffImage => staffImageUrl != null && staffImageUrl!.isNotEmpty;

  /// Check if service is unavailable.
  bool get isUnavailable => !isAvailableToday;

  /// Check if user can book this service.
  bool get canBook => isAvailableToday && tokensAvailable > 0;

  /// Parse availability code string to enum.
  AvailabilityCode get availabilityCodeEnum {
    switch (availabilityCode?.toUpperCase()) {
      case 'AVAILABLE':
        return AvailabilityCode.available;
      case 'NO_QUEUE_CONFIG':
        return AvailabilityCode.noQueueConfig;
      case 'QUEUE_INACTIVE':
        return AvailabilityCode.queueInactive;
      case 'SATURDAY':
        return AvailabilityCode.saturday;
      case 'HOLIDAY':
        return AvailabilityCode.holiday;
      case 'STAFF_ABSENT':
        return AvailabilityCode.staffAbsent;
      default:
        return AvailabilityCode.unknown;
    }
  }

  /// Get status color based on availability.
  Color get statusColor {
    if (!isAvailableToday) return const Color(0xFFDC143C); // Red
    if (tokensAvailable == 0) return const Color(0xFFF57C00); // Orange
    return const Color(0xFF4CAF50); // Green
  }

  /// Get display text for availability status.
  String get availabilityDisplayText {
    if (availabilityReason != null && availabilityReason!.isNotEmpty) {
      return availabilityReason!;
    }

    switch (availabilityCodeEnum) {
      case AvailabilityCode.available:
        return tokensAvailable > 0
            ? '$tokensAvailable tokens available'
            : 'No tokens available';
      case AvailabilityCode.noQueueConfig:
        return 'Not configured';
      case AvailabilityCode.queueInactive:
        return 'Queue closed';
      case AvailabilityCode.saturday:
        return 'Weekend';
      case AvailabilityCode.holiday:
        return 'Holiday';
      case AvailabilityCode.staffAbsent:
        return 'Staff absent';
      case AvailabilityCode.unknown:
        return 'Unavailable';
    }
  }
}
