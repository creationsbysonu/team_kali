import 'package:sewa_sathi/features/get_token/domain/entities/queue_token_entity.dart';

/// Progress step model with JSON serialization.
class ProgressStepModel extends ProgressStep {
  const ProgressStepModel({required super.title, required super.completed});

  factory ProgressStepModel.fromJson(Map<String, dynamic> json) {
    return ProgressStepModel(
      title: json['title'] ?? '',
      completed: json['completed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {'title': title, 'completed': completed};
  }
}

/// Token progress model with JSON serialization.
class TokenProgressModel extends TokenProgress {
  const TokenProgressModel({
    required super.totalSteps,
    required super.completedSteps,
    super.currentStep,
    required super.steps,
  });

  factory TokenProgressModel.fromJson(Map<String, dynamic> json) {
    final stepsJson = json['steps'] as List? ?? [];
    return TokenProgressModel(
      totalSteps: json['total_steps'] ?? 0,
      completedSteps: json['completed_steps'] ?? 0,
      currentStep: json['current_step'],
      steps: stepsJson.map((e) => ProgressStepModel.fromJson(e)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_steps': totalSteps,
      'completed_steps': completedSteps,
      'current_step': currentStep,
      'steps': steps.map((e) => (e as ProgressStepModel).toJson()).toList(),
    };
  }
}

/// Queue Token model with JSON serialization.
/// Follows Citizen API v1 Token structure.
class QueueTokenModel extends QueueTokenEntity {
  const QueueTokenModel({
    required super.id,
    required super.tokenNumber,
    required super.bookingType,
    required super.status,
    required super.serviceName,
    super.serviceLogoUrl,
    required super.ministryName,
    super.queuePosition,
    super.estimatedTime,
    super.estimatedWait,
    required super.bookingDate,
    required super.createdAt,
    super.progress,
    // Legacy fields
    super.statusDisplay,
    super.expectedServiceTime,
    super.expectedServiceTimeDisplay,
    super.emergencyFeePaid,
  });

  /// Create from JSON response following Citizen API v1 format.
  ///
  /// Expected JSON structure:
  /// ```json
  /// {
  ///   "id": "token-uuid",
  ///   "token_number": 15,
  ///   "booking_type": "REGULAR",
  ///   "status": "WAITING",
  ///   "service_name": "Citizenship Certificate",
  ///   "service_logo_url": "https://...",
  ///   "ministry_name": "CDO Office",
  ///   "queue_position": 5,
  ///   "estimated_time": "11:30 AM",
  ///   "estimated_wait": "45 minutes",
  ///   "booking_date": "2026-01-29",
  ///   "created_at": "2026-01-29T10:00:00Z",
  ///   "progress": {
  ///     "total_steps": 3,
  ///     "completed_steps": 1,
  ///     "current_step": "Seen by Staff",
  ///     "steps": [...]
  ///   }
  /// }
  /// ```
  factory QueueTokenModel.fromJson(Map<String, dynamic> json) {
    TokenProgressModel? progress;
    if (json['progress'] != null) {
      progress = TokenProgressModel.fromJson(json['progress']);
    }

    return QueueTokenModel(
      id: json['id']?.toString() ?? '',
      tokenNumber: json['token_number'] ?? 0,
      bookingType: json['booking_type'] ?? 'REGULAR',
      status: json['status'] ?? 'WAITING',
      serviceName: json['service_name'] ?? '',
      serviceLogoUrl: json['service_logo_url'],
      ministryName: json['ministry_name'] ?? '',
      queuePosition: json['queue_position'] ?? json['position_in_queue'],
      estimatedTime: json['estimated_time'],
      estimatedWait: json['estimated_wait'],
      bookingDate: json['booking_date'] ?? '',
      createdAt: json['created_at'] ?? '',
      progress: progress,
      // Legacy fields for backward compatibility
      statusDisplay: json['status_display'],
      expectedServiceTime:
          json['expected_service_time'] ?? json['estimated_time'] ?? '',
      expectedServiceTimeDisplay:
          json['expected_service_time_display'] ?? json['estimated_time'] ?? '',
      emergencyFeePaid: json['emergency_fee_paid']?.toString() ?? '0',
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'token_number': tokenNumber,
      'booking_type': bookingType,
      'status': status,
      'service_name': serviceName,
      'service_logo_url': serviceLogoUrl,
      'ministry_name': ministryName,
      'queue_position': queuePosition,
      'estimated_time': estimatedTime,
      'estimated_wait': estimatedWait,
      'booking_date': bookingDate,
      'created_at': createdAt,
      if (progress != null)
        'progress': (progress as TokenProgressModel).toJson(),
    };
  }

  /// Create from entity.
  factory QueueTokenModel.fromEntity(QueueTokenEntity entity) {
    return QueueTokenModel(
      id: entity.id,
      tokenNumber: entity.tokenNumber,
      bookingType: entity.bookingType,
      status: entity.status,
      serviceName: entity.serviceName,
      serviceLogoUrl: entity.serviceLogoUrl,
      ministryName: entity.ministryName,
      queuePosition: entity.queuePosition,
      estimatedTime: entity.estimatedTime,
      estimatedWait: entity.estimatedWait,
      bookingDate: entity.bookingDate,
      createdAt: entity.createdAt,
      progress: entity.progress,
      statusDisplay: entity.statusDisplay,
      expectedServiceTime: entity.expectedServiceTime,
      expectedServiceTimeDisplay: entity.expectedServiceTimeDisplay,
      emergencyFeePaid: entity.emergencyFeePaid,
    );
  }
}
