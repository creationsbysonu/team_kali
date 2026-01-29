import 'package:sewa_web/features/staff_queue/domain/entities/staff_token.dart';

/// Token Latest Event Model
class TokenLatestEventModel extends TokenLatestEvent {
  const TokenLatestEventModel({
    required super.event,
    required super.eventDisplay,
    required super.performedBy,
    required super.timestamp,
  });

  factory TokenLatestEventModel.fromJson(Map<String, dynamic> json) {
    return TokenLatestEventModel(
      event: json['event'] ?? '',
      eventDisplay: json['event_display'] ?? '',
      performedBy: json['performed_by'] ?? 'System',
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

/// Staff Token Model
class StaffTokenModel extends StaffToken {
  const StaffTokenModel({
    required super.id,
    required super.tokenNumber,
    required super.citizenName,
    required super.citizenEmail,
    super.citizenPhone,
    required super.serviceName,
    required super.bookingType,
    required super.bookingTypeDisplay,
    super.expectedServiceTime,
    super.expectedServiceTimeNepal,
    required super.status,
    required super.statusDisplay,
    super.noShowCount,
    super.isBeingServed,
    super.countdownSeconds,
    super.serviceTimeRemainingSeconds,
    super.serviceStartedAt,
    super.canMarkNoShow,
    super.canMarkPending,
    super.active,
    super.latestEvent,
    required super.createdAt,
    super.updatedAt,
    super.pendingReason,
    super.pendingPriorityDate,
    super.priorityDateDisplay,
    super.isPriorityToday,
    super.originalDate,
    super.emailSent,
    super.canSendEmail,
    super.canMarkServed,
  });

  factory StaffTokenModel.fromJson(Map<String, dynamic> json) {
    return StaffTokenModel(
      id: json['id']?.toString() ?? '',
      tokenNumber: json['token_number'] ?? 0,
      citizenName: json['citizen_name'] ?? 'Unknown',
      citizenEmail: json['citizen_email'] ?? '',
      citizenPhone: json['citizen_phone'],
      serviceName: json['service_name'] ?? '',
      bookingType: StaffBookingType.fromString(
        json['booking_type'] ?? 'REGULAR',
      ),
      bookingTypeDisplay: json['booking_type_display'] ?? 'Regular Booking',
      expectedServiceTime: json['expected_service_time'] != null
          ? DateTime.tryParse(json['expected_service_time'])
          : null,
      expectedServiceTimeNepal: json['expected_service_time_nepal'],
      status: StaffTokenStatus.fromString(json['status'] ?? 'WAITING'),
      statusDisplay: json['status_display'] ?? 'Waiting in Queue',
      noShowCount: json['no_show_count'] ?? 0,
      isBeingServed: json['is_being_served'] ?? false,
      countdownSeconds: json['countdown_seconds'],
      serviceTimeRemainingSeconds: json['service_time_remaining_seconds'],
      serviceStartedAt: json['service_started_at'] != null
          ? DateTime.tryParse(json['service_started_at'])
          : null,
      canMarkNoShow: json['can_mark_no_show'] ?? false,
      canMarkPending: json['can_mark_pending'] ?? false,
      active: json['active'] ?? true,
      latestEvent: json['latest_event'] != null
          ? TokenLatestEventModel.fromJson(json['latest_event'])
          : null,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
      // Pending specific fields
      pendingReason: json['pending_reason'],
      pendingPriorityDate: json['pending_priority_date'] != null
          ? DateTime.tryParse(json['pending_priority_date'])
          : null,
      priorityDateDisplay: json['priority_date_display'],
      isPriorityToday: json['is_priority_today'] ?? false,
      originalDate: json['original_date'] != null
          ? DateTime.tryParse(json['original_date'])
          : null,
      emailSent: json['email_sent'] ?? false,
      canSendEmail: json['can_send_email'] ?? false,
      canMarkServed: json['can_mark_served'] ?? false,
    );
  }
}

/// Active Tokens Data Model
class ActiveTokensDataModel extends ActiveTokensData {
  const ActiveTokensDataModel({
    required super.tokens,
    required super.currentServing,
    required super.totalWaiting,
    required super.totalInService,
  });

  factory ActiveTokensDataModel.fromJson(Map<String, dynamic> json) {
    final tokensJson = json['tokens'] as List<dynamic>? ?? [];
    final tokens = tokensJson.map((t) => StaffTokenModel.fromJson(t)).toList();

    return ActiveTokensDataModel(
      tokens: tokens,
      currentServing: json['current_serving'] ?? 0,
      totalWaiting: json['total_waiting'] ?? 0,
      totalInService: json['total_in_service'] ?? 0,
    );
  }
}

/// Tokens Summary Model
class TokensSummaryModel extends TokensSummary {
  const TokensSummaryModel({
    required super.total,
    required super.waiting,
    required super.inService,
    required super.completed,
    required super.pending,
    required super.cancelled,
  });

  factory TokensSummaryModel.fromJson(Map<String, dynamic> json) {
    return TokensSummaryModel(
      total: json['total'] ?? 0,
      waiting: json['waiting'] ?? 0,
      inService: json['in_service'] ?? 0,
      completed: json['completed'] ?? 0,
      pending: json['pending'] ?? 0,
      cancelled: json['cancelled'] ?? 0,
    );
  }
}

/// All Tokens Data Model
class AllTokensDataModel extends AllTokensData {
  const AllTokensDataModel({required super.tokens, required super.summary});

  factory AllTokensDataModel.fromJson(Map<String, dynamic> json) {
    final tokensJson = json['tokens'] as List<dynamic>? ?? [];
    final tokens = tokensJson.map((t) => StaffTokenModel.fromJson(t)).toList();

    return AllTokensDataModel(
      tokens: tokens,
      summary: json['summary'] != null
          ? TokensSummaryModel.fromJson(json['summary'])
          : const TokensSummaryModel(
              total: 0,
              waiting: 0,
              inService: 0,
              completed: 0,
              pending: 0,
              cancelled: 0,
            ),
    );
  }
}

/// Pending Tokens Data Model
class PendingTokensDataModel extends PendingTokensData {
  const PendingTokensDataModel({
    required super.tokens,
    required super.totalPending,
    required super.priorityTodayCount,
  });

  factory PendingTokensDataModel.fromJson(Map<String, dynamic> json) {
    final tokensJson = json['tokens'] as List<dynamic>? ?? [];
    final tokens = tokensJson.map((t) => StaffTokenModel.fromJson(t)).toList();

    return PendingTokensDataModel(
      tokens: tokens,
      totalPending: json['total_pending'] ?? tokens.length,
      priorityTodayCount: json['priority_today_count'] ?? 0,
    );
  }
}

/// Start Service Result Model
class StartServiceResultModel extends StartServiceResult {
  const StartServiceResultModel({
    required super.tokenId,
    required super.tokenNumber,
    required super.status,
    required super.serviceStartedAt,
    required super.countdownMinutes,
  });

  factory StartServiceResultModel.fromJson(Map<String, dynamic> json) {
    return StartServiceResultModel(
      tokenId: json['token_id']?.toString() ?? '',
      tokenNumber: json['token_number'] ?? 0,
      status: StaffTokenStatus.fromString(json['status'] ?? 'IN_SERVICE'),
      serviceStartedAt:
          DateTime.tryParse(json['service_started_at'] ?? '') ?? DateTime.now(),
      countdownMinutes: json['countdown_minutes'] ?? 10,
    );
  }
}

/// No Show Result Model
class NoShowResultModel extends NoShowResult {
  const NoShowResultModel({
    required super.tokenId,
    required super.oldTokenNumber,
    super.newTokenNumber,
    required super.noShowCount,
    super.newExpectedTime,
    required super.action,
  });

  factory NoShowResultModel.fromJson(Map<String, dynamic> json) {
    return NoShowResultModel(
      tokenId: json['token_id']?.toString() ?? '',
      oldTokenNumber: json['old_token_number'] ?? json['token_number'] ?? 0,
      newTokenNumber: json['new_token_number'],
      noShowCount: json['no_show_count'] ?? 0,
      newExpectedTime: json['new_expected_time'] != null
          ? DateTime.tryParse(json['new_expected_time'])
          : null,
      action: json['action'] ?? 'PUSHED_BACK',
    );
  }
}

/// Mark Pending Result Model
class MarkPendingResultModel extends MarkPendingResult {
  const MarkPendingResultModel({
    required super.tokenId,
    required super.tokenNumber,
    required super.status,
    required super.reason,
    required super.priorityDate,
    required super.citizenEmail,
  });

  factory MarkPendingResultModel.fromJson(Map<String, dynamic> json) {
    return MarkPendingResultModel(
      tokenId: json['token_id']?.toString() ?? '',
      tokenNumber: json['token_number'] ?? 0,
      status: StaffTokenStatus.fromString(json['status'] ?? 'PENDING'),
      reason: json['reason'] ?? '',
      priorityDate:
          DateTime.tryParse(json['priority_date'] ?? '') ??
          DateTime.now().add(const Duration(days: 1)),
      citizenEmail: json['citizen_email'] ?? '',
    );
  }
}

/// Mark Pending Served Result Model
class MarkPendingServedResultModel extends MarkPendingServedResult {
  const MarkPendingServedResultModel({
    required super.tokenId,
    required super.tokenNumber,
    required super.status,
  });

  factory MarkPendingServedResultModel.fromJson(Map<String, dynamic> json) {
    return MarkPendingServedResultModel(
      tokenId: json['token_id']?.toString() ?? '',
      tokenNumber: json['token_number'] ?? 0,
      status: StaffTokenStatus.fromString(json['status'] ?? 'COMPLETED'),
    );
  }
}
