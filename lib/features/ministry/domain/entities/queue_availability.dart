import 'package:equatable/equatable.dart';

/// Capacity information for a queue
class CapacityInfo extends Equatable {
  final int totalCapacity;
  final int totalBooked;
  final int totalRemaining;

  // Regular
  final int regularQuota;
  final int regularBooked;
  final int regularRemaining;

  // Prebooking
  final bool prebookingAllowed;
  final int? prebookingQuota;
  final int? prebookingBooked;
  final int? prebookingRemaining;
  final int? prebookingLeadHours;

  // Emergency
  final bool emergencyAllowed;
  final double? emergencyFee;
  final int? emergencyQuota;
  final int? emergencyBooked;
  final int? emergencyRemaining;

  const CapacityInfo({
    required this.totalCapacity,
    required this.totalBooked,
    required this.totalRemaining,
    required this.regularQuota,
    required this.regularBooked,
    required this.regularRemaining,
    required this.prebookingAllowed,
    this.prebookingQuota,
    this.prebookingBooked,
    this.prebookingRemaining,
    this.prebookingLeadHours,
    required this.emergencyAllowed,
    this.emergencyFee,
    this.emergencyQuota,
    this.emergencyBooked,
    this.emergencyRemaining,
  });

  @override
  List<Object?> get props => [
    totalCapacity,
    totalBooked,
    totalRemaining,
    regularQuota,
    regularBooked,
    regularRemaining,
    prebookingAllowed,
    prebookingQuota,
    prebookingBooked,
    prebookingRemaining,
    prebookingLeadHours,
    emergencyAllowed,
    emergencyFee,
    emergencyQuota,
    emergencyBooked,
    emergencyRemaining,
  ];

  /// Check if queue is fully booked
  bool get isFull => totalRemaining <= 0;

  /// Check if regular tokens available
  bool get hasRegularSlots => regularRemaining > 0;

  /// Check if prebooking slots available
  bool get hasPrebookingSlots =>
      prebookingAllowed && (prebookingRemaining ?? 0) > 0;

  /// Check if emergency slots available
  bool get hasEmergencySlots =>
      emergencyAllowed && (emergencyRemaining ?? 0) > 0;
}

/// Queue Availability entity
class QueueAvailability extends Equatable {
  final bool queueAvailable;
  final String? message;
  final String? dailyQueueId;
  final CapacityInfo? capacityInfo;

  const QueueAvailability({
    required this.queueAvailable,
    this.message,
    this.dailyQueueId,
    this.capacityInfo,
  });

  @override
  List<Object?> get props => [
    queueAvailable,
    message,
    dailyQueueId,
    capacityInfo,
  ];

  /// Check if any booking type is available
  bool get hasAnySlots {
    if (!queueAvailable || capacityInfo == null) return false;
    return capacityInfo!.hasRegularSlots ||
        capacityInfo!.hasPrebookingSlots ||
        capacityInfo!.hasEmergencySlots;
  }
}
