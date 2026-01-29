import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Token status enum following Citizen API v1.
enum TokenStatus { waiting, inService, pending, completed, cancelled }

/// Progress step entity for token workflow.
class ProgressStep extends Equatable {
  final String title;
  final bool completed;

  const ProgressStep({required this.title, required this.completed});

  @override
  List<Object?> get props => [title, completed];
}

/// Token progress entity.
class TokenProgress extends Equatable {
  final int totalSteps;
  final int completedSteps;
  final String? currentStep;
  final List<ProgressStep> steps;

  const TokenProgress({
    required this.totalSteps,
    required this.completedSteps,
    this.currentStep,
    required this.steps,
  });

  @override
  List<Object?> get props => [totalSteps, completedSteps, currentStep, steps];

  /// Progress as a fraction (0.0 to 1.0).
  double get progressFraction =>
      totalSteps > 0 ? completedSteps / totalSteps : 0.0;
}

/// Queue Token entity representing a booked token.
/// Follows Citizen API v1 Token structure.
class QueueTokenEntity extends Equatable {
  final String id;
  final int tokenNumber;
  final String bookingType;
  final String status;
  final String serviceName;
  final String? serviceLogoUrl;
  final String ministryName;
  final int? queuePosition;
  final String? estimatedTime;
  final String? estimatedWait;
  final String bookingDate;
  final String createdAt;
  final TokenProgress? progress;

  // Legacy fields for backward compatibility
  final String? statusDisplay;
  final String? expectedServiceTime;
  final String? expectedServiceTimeDisplay;
  final String? emergencyFeePaid;

  const QueueTokenEntity({
    required this.id,
    required this.tokenNumber,
    required this.bookingType,
    required this.status,
    required this.serviceName,
    this.serviceLogoUrl,
    required this.ministryName,
    this.queuePosition,
    this.estimatedTime,
    this.estimatedWait,
    required this.bookingDate,
    required this.createdAt,
    this.progress,
    // Legacy fields
    this.statusDisplay,
    this.expectedServiceTime,
    this.expectedServiceTimeDisplay,
    this.emergencyFeePaid,
  });

  @override
  List<Object?> get props => [
    id,
    tokenNumber,
    bookingType,
    status,
    serviceName,
    serviceLogoUrl,
    ministryName,
    queuePosition,
    estimatedTime,
    estimatedWait,
    bookingDate,
    createdAt,
    progress,
  ];

  /// Check if token can be cancelled.
  bool get canCancel => status == 'WAITING' || status == 'PENDING';

  /// Check if token is active (not completed/cancelled).
  bool get isActive =>
      status == 'WAITING' || status == 'IN_SERVICE' || status == 'PENDING';

  /// Check if token is completed.
  bool get isCompleted => status.toUpperCase() == 'COMPLETED';

  /// Check if token is cancelled.
  bool get isCancelled => status.toUpperCase() == 'CANCELLED';

  /// Check if it's user's turn.
  bool get isMyTurn => status.toUpperCase() == 'IN_SERVICE';

  /// Get token status enum.
  TokenStatus get tokenStatus {
    switch (status.toUpperCase()) {
      case 'WAITING':
        return TokenStatus.waiting;
      case 'IN_SERVICE':
        return TokenStatus.inService;
      case 'PENDING':
        return TokenStatus.pending;
      case 'COMPLETED':
        return TokenStatus.completed;
      case 'CANCELLED':
        return TokenStatus.cancelled;
      default:
        return TokenStatus.waiting;
    }
  }

  /// Get status color following Citizen API guidelines.
  Color get statusColor {
    switch (tokenStatus) {
      case TokenStatus.waiting:
        return const Color(0xFF2196F3); // Blue - Show position, wait time
      case TokenStatus.inService:
        return const Color(0xFF4CAF50); // Green - "Your turn!" alert
      case TokenStatus.pending:
        return const Color(0xFFF57C00); // Orange - Show reason, priority date
      case TokenStatus.completed:
        return const Color(0xFF757575); // Grey - Green checkmark
      case TokenStatus.cancelled:
        return const Color(0xFFDC143C); // Red - Gray, strikethrough
    }
  }

  /// Get status display text.
  String get statusDisplayText {
    if (statusDisplay != null && statusDisplay!.isNotEmpty) {
      return statusDisplay!;
    }
    switch (tokenStatus) {
      case TokenStatus.waiting:
        return 'Waiting';
      case TokenStatus.inService:
        return 'Your Turn!';
      case TokenStatus.pending:
        return 'Pending';
      case TokenStatus.completed:
        return 'Completed';
      case TokenStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Check if this is an emergency booking.
  bool get isEmergency => bookingType.toUpperCase() == 'EMERGENCY';

  /// Check if this is a prebooked token.
  bool get isPrebooked => bookingType.toUpperCase() == 'PREBOOKED';

  /// Check if this is a regular booking.
  bool get isRegular => bookingType.toUpperCase() == 'REGULAR';

  /// Get emergency fee as double.
  double get emergencyFee => double.tryParse(emergencyFeePaid ?? '0') ?? 0.0;

  /// Position in queue for display (null if not waiting).
  int? get positionInQueue => queuePosition;

  /// Get expected time display - returns the formatted time or fallback.
  String get expectedTimeDisplayText {
    if (expectedServiceTimeDisplay != null &&
        expectedServiceTimeDisplay!.isNotEmpty) {
      return expectedServiceTimeDisplay!;
    }
    if (estimatedTime != null && estimatedTime!.isNotEmpty) {
      return estimatedTime!;
    }
    if (estimatedWait != null && estimatedWait!.isNotEmpty) {
      return 'In $estimatedWait';
    }
    return 'TBD';
  }
}
