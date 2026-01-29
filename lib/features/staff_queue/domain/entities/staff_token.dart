import 'package:equatable/equatable.dart';

/// Token status enum for new queue system
enum StaffTokenStatus {
  waiting('WAITING'),
  inService('IN_SERVICE'),
  completed('COMPLETED'),
  pending('PENDING'),
  cancelled('CANCELLED');

  final String value;
  const StaffTokenStatus(this.value);

  static StaffTokenStatus fromString(String value) {
    switch (value.toUpperCase()) {
      case 'WAITING':
        return StaffTokenStatus.waiting;
      case 'IN_SERVICE':
        return StaffTokenStatus.inService;
      case 'COMPLETED':
        return StaffTokenStatus.completed;
      case 'PENDING':
        return StaffTokenStatus.pending;
      case 'CANCELLED':
        return StaffTokenStatus.cancelled;
      default:
        return StaffTokenStatus.waiting;
    }
  }

  String get displayName {
    switch (this) {
      case StaffTokenStatus.waiting:
        return 'Waiting in Queue';
      case StaffTokenStatus.inService:
        return 'Being Served';
      case StaffTokenStatus.completed:
        return 'Service Completed';
      case StaffTokenStatus.pending:
        return 'Pending (Govt Fault)';
      case StaffTokenStatus.cancelled:
        return 'Cancelled';
    }
  }
}

/// Booking type enum
enum StaffBookingType {
  regular('REGULAR'),
  prebooked('PREBOOKED'),
  emergency('EMERGENCY');

  final String value;
  const StaffBookingType(this.value);

  static StaffBookingType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'REGULAR':
        return StaffBookingType.regular;
      case 'PREBOOKED':
        return StaffBookingType.prebooked;
      case 'EMERGENCY':
        return StaffBookingType.emergency;
      default:
        return StaffBookingType.regular;
    }
  }

  String get displayName {
    switch (this) {
      case StaffBookingType.regular:
        return 'Regular Booking';
      case StaffBookingType.prebooked:
        return 'Pre-booked';
      case StaffBookingType.emergency:
        return 'Emergency';
    }
  }
}

/// Latest event for token history
class TokenLatestEvent extends Equatable {
  final String event;
  final String eventDisplay;
  final String performedBy;
  final DateTime timestamp;

  const TokenLatestEvent({
    required this.event,
    required this.eventDisplay,
    required this.performedBy,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [event, eventDisplay, performedBy, timestamp];
}

/// Staff Token entity - represents a token in the queue
class StaffToken extends Equatable {
  final String id;
  final int tokenNumber;
  final String citizenName;
  final String citizenEmail;
  final String? citizenPhone;
  final String serviceName;
  final StaffBookingType bookingType;
  final String bookingTypeDisplay;
  final DateTime? expectedServiceTime;
  final String? expectedServiceTimeNepal;
  final StaffTokenStatus status;
  final String statusDisplay;
  final int noShowCount;
  final bool isBeingServed;
  final int? countdownSeconds;
  final int? serviceTimeRemainingSeconds;
  final DateTime? serviceStartedAt;
  final bool canMarkNoShow;
  final bool canMarkPending;
  final bool active;
  final TokenLatestEvent? latestEvent;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Pending token specific fields
  final String? pendingReason;
  final DateTime? pendingPriorityDate;
  final String? priorityDateDisplay;
  final bool isPriorityToday;
  final DateTime? originalDate;
  final bool emailSent;
  final bool canSendEmail;
  final bool canMarkServed;

  const StaffToken({
    required this.id,
    required this.tokenNumber,
    required this.citizenName,
    required this.citizenEmail,
    this.citizenPhone,
    required this.serviceName,
    required this.bookingType,
    required this.bookingTypeDisplay,
    this.expectedServiceTime,
    this.expectedServiceTimeNepal,
    required this.status,
    required this.statusDisplay,
    this.noShowCount = 0,
    this.isBeingServed = false,
    this.countdownSeconds,
    this.serviceTimeRemainingSeconds,
    this.serviceStartedAt,
    this.canMarkNoShow = false,
    this.canMarkPending = false,
    this.active = true,
    this.latestEvent,
    required this.createdAt,
    this.updatedAt,
    // Pending specific
    this.pendingReason,
    this.pendingPriorityDate,
    this.priorityDateDisplay,
    this.isPriorityToday = false,
    this.originalDate,
    this.emailSent = false,
    this.canSendEmail = false,
    this.canMarkServed = false,
  });

  /// Check if it's this token's turn (waiting with 0 countdown)
  bool get isMyTurn =>
      status == StaffTokenStatus.waiting &&
      (countdownSeconds == null || countdownSeconds == 0);

  /// Check if token has no-show warning
  bool get hasNoShowWarning => noShowCount > 0;

  @override
  List<Object?> get props => [
    id,
    tokenNumber,
    citizenName,
    citizenEmail,
    citizenPhone,
    serviceName,
    bookingType,
    bookingTypeDisplay,
    expectedServiceTime,
    expectedServiceTimeNepal,
    status,
    statusDisplay,
    noShowCount,
    isBeingServed,
    countdownSeconds,
    serviceTimeRemainingSeconds,
    serviceStartedAt,
    canMarkNoShow,
    canMarkPending,
    active,
    latestEvent,
    createdAt,
    updatedAt,
    pendingReason,
    pendingPriorityDate,
    priorityDateDisplay,
    isPriorityToday,
    originalDate,
    emailSent,
    canSendEmail,
    canMarkServed,
  ];

  StaffToken copyWith({
    String? id,
    int? tokenNumber,
    String? citizenName,
    String? citizenEmail,
    String? citizenPhone,
    String? serviceName,
    StaffBookingType? bookingType,
    String? bookingTypeDisplay,
    DateTime? expectedServiceTime,
    String? expectedServiceTimeNepal,
    StaffTokenStatus? status,
    String? statusDisplay,
    int? noShowCount,
    bool? isBeingServed,
    int? countdownSeconds,
    int? serviceTimeRemainingSeconds,
    DateTime? serviceStartedAt,
    bool? canMarkNoShow,
    bool? canMarkPending,
    bool? active,
    TokenLatestEvent? latestEvent,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? pendingReason,
    DateTime? pendingPriorityDate,
    String? priorityDateDisplay,
    bool? isPriorityToday,
    DateTime? originalDate,
    bool? emailSent,
    bool? canSendEmail,
    bool? canMarkServed,
  }) {
    return StaffToken(
      id: id ?? this.id,
      tokenNumber: tokenNumber ?? this.tokenNumber,
      citizenName: citizenName ?? this.citizenName,
      citizenEmail: citizenEmail ?? this.citizenEmail,
      citizenPhone: citizenPhone ?? this.citizenPhone,
      serviceName: serviceName ?? this.serviceName,
      bookingType: bookingType ?? this.bookingType,
      bookingTypeDisplay: bookingTypeDisplay ?? this.bookingTypeDisplay,
      expectedServiceTime: expectedServiceTime ?? this.expectedServiceTime,
      expectedServiceTimeNepal:
          expectedServiceTimeNepal ?? this.expectedServiceTimeNepal,
      status: status ?? this.status,
      statusDisplay: statusDisplay ?? this.statusDisplay,
      noShowCount: noShowCount ?? this.noShowCount,
      isBeingServed: isBeingServed ?? this.isBeingServed,
      countdownSeconds: countdownSeconds ?? this.countdownSeconds,
      serviceTimeRemainingSeconds:
          serviceTimeRemainingSeconds ?? this.serviceTimeRemainingSeconds,
      serviceStartedAt: serviceStartedAt ?? this.serviceStartedAt,
      canMarkNoShow: canMarkNoShow ?? this.canMarkNoShow,
      canMarkPending: canMarkPending ?? this.canMarkPending,
      active: active ?? this.active,
      latestEvent: latestEvent ?? this.latestEvent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pendingReason: pendingReason ?? this.pendingReason,
      pendingPriorityDate: pendingPriorityDate ?? this.pendingPriorityDate,
      priorityDateDisplay: priorityDateDisplay ?? this.priorityDateDisplay,
      isPriorityToday: isPriorityToday ?? this.isPriorityToday,
      originalDate: originalDate ?? this.originalDate,
      emailSent: emailSent ?? this.emailSent,
      canSendEmail: canSendEmail ?? this.canSendEmail,
      canMarkServed: canMarkServed ?? this.canMarkServed,
    );
  }
}

/// Active Tokens Response Data
class ActiveTokensData extends Equatable {
  final List<StaffToken> tokens;
  final int currentServing;
  final int totalWaiting;
  final int totalInService;

  const ActiveTokensData({
    required this.tokens,
    required this.currentServing,
    required this.totalWaiting,
    required this.totalInService,
  });

  @override
  List<Object?> get props => [
    tokens,
    currentServing,
    totalWaiting,
    totalInService,
  ];
}

/// All Tokens Summary
class TokensSummary extends Equatable {
  final int total;
  final int waiting;
  final int inService;
  final int completed;
  final int pending;
  final int cancelled;

  const TokensSummary({
    required this.total,
    required this.waiting,
    required this.inService,
    required this.completed,
    required this.pending,
    required this.cancelled,
  });

  /// Create empty summary for development/demo
  factory TokensSummary.empty() => const TokensSummary(
    total: 0,
    waiting: 0,
    inService: 0,
    completed: 0,
    pending: 0,
    cancelled: 0,
  );

  @override
  List<Object?> get props => [
    total,
    waiting,
    inService,
    completed,
    pending,
    cancelled,
  ];
}

/// All Tokens Response Data
class AllTokensData extends Equatable {
  final List<StaffToken> tokens;
  final TokensSummary summary;

  const AllTokensData({required this.tokens, required this.summary});

  @override
  List<Object?> get props => [tokens, summary];
}

/// Pending Tokens Response Data
class PendingTokensData extends Equatable {
  final List<StaffToken> tokens;
  final int totalPending;
  final int priorityTodayCount;

  const PendingTokensData({
    required this.tokens,
    this.totalPending = 0,
    this.priorityTodayCount = 0,
  });

  /// Get tokens with priority today
  List<StaffToken> get priorityTodayTokens =>
      tokens.where((t) => t.isPriorityToday).toList();

  /// Get tokens with future priority
  List<StaffToken> get futurePriorityTokens =>
      tokens.where((t) => !t.isPriorityToday).toList();

  @override
  List<Object?> get props => [tokens, totalPending, priorityTodayCount];
}

/// Start Service Result
class StartServiceResult extends Equatable {
  final String tokenId;
  final int tokenNumber;
  final StaffTokenStatus status;
  final DateTime serviceStartedAt;
  final int countdownMinutes;

  const StartServiceResult({
    required this.tokenId,
    required this.tokenNumber,
    required this.status,
    required this.serviceStartedAt,
    required this.countdownMinutes,
  });

  @override
  List<Object?> get props => [
    tokenId,
    tokenNumber,
    status,
    serviceStartedAt,
    countdownMinutes,
  ];
}

/// No Show Result
class NoShowResult extends Equatable {
  final String tokenId;
  final int oldTokenNumber;
  final int? newTokenNumber;
  final int noShowCount;
  final DateTime? newExpectedTime;
  final String action; // PUSHED_BACK or CANCELLED

  const NoShowResult({
    required this.tokenId,
    required this.oldTokenNumber,
    this.newTokenNumber,
    required this.noShowCount,
    this.newExpectedTime,
    required this.action,
  });

  bool get isCancelled => action == 'CANCELLED';
  bool get isPushedBack => action == 'PUSHED_BACK';

  @override
  List<Object?> get props => [
    tokenId,
    oldTokenNumber,
    newTokenNumber,
    noShowCount,
    newExpectedTime,
    action,
  ];
}

/// Mark Pending Result
class MarkPendingResult extends Equatable {
  final String tokenId;
  final int tokenNumber;
  final StaffTokenStatus status;
  final String reason;
  final DateTime priorityDate;
  final String citizenEmail;

  const MarkPendingResult({
    required this.tokenId,
    required this.tokenNumber,
    required this.status,
    required this.reason,
    required this.priorityDate,
    required this.citizenEmail,
  });

  @override
  List<Object?> get props => [
    tokenId,
    tokenNumber,
    status,
    reason,
    priorityDate,
    citizenEmail,
  ];
}

/// Mark Pending Served Result
class MarkPendingServedResult extends Equatable {
  final String tokenId;
  final int tokenNumber;
  final StaffTokenStatus status;

  const MarkPendingServedResult({
    required this.tokenId,
    required this.tokenNumber,
    required this.status,
  });

  @override
  List<Object?> get props => [tokenId, tokenNumber, status];
}
