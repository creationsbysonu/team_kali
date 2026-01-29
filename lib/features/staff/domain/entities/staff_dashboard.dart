import 'package:equatable/equatable.dart';
import 'package:sewa_web/features/ministry/domain/entities/queue_token.dart';

/// Staff Dashboard Summary
class StaffDashboardSummary extends Equatable {
  final NormalQueueSummary normalQueue;
  final ProgressWorkbenchSummary progressWorkbench;

  const StaffDashboardSummary({
    required this.normalQueue,
    required this.progressWorkbench,
  });

  @override
  List<Object?> get props => [normalQueue, progressWorkbench];
}

/// Normal Queue Summary
class NormalQueueSummary extends Equatable {
  final int activeTokens;
  final int servedToday;
  final int noShowsToday;
  final int cancelledToday;

  const NormalQueueSummary({
    required this.activeTokens,
    required this.servedToday,
    required this.noShowsToday,
    required this.cancelledToday,
  });

  @override
  List<Object?> get props => [
    activeTokens,
    servedToday,
    noShowsToday,
    cancelledToday,
  ];

  int get total => activeTokens + servedToday + noShowsToday + cancelledToday;
}

/// Progress Workbench Summary
class ProgressWorkbenchSummary extends Equatable {
  final int totalProgressTokens;
  final int pendingSteps;
  final int completedSteps;

  const ProgressWorkbenchSummary({
    required this.totalProgressTokens,
    required this.pendingSteps,
    required this.completedSteps,
  });

  @override
  List<Object?> get props => [
    totalProgressTokens,
    pendingSteps,
    completedSteps,
  ];
}

/// Normal Queue Data for staff
class NormalQueueData extends Equatable {
  final String queueName;
  final DateTime serviceDate;
  final NormalQueueSummary stats;
  final List<QueueToken> tokens;

  const NormalQueueData({
    required this.queueName,
    required this.serviceDate,
    required this.stats,
    required this.tokens,
  });

  @override
  List<Object?> get props => [queueName, serviceDate, stats, tokens];

  /// Get active tokens only
  List<QueueToken> get activeTokens => tokens.where((t) => t.isActive).toList();

  /// Get served tokens
  List<QueueToken> get servedTokens => tokens.where((t) => t.isServed).toList();

  /// Get no-show tokens
  List<QueueToken> get noShowTokens => tokens.where((t) => t.isNoShow).toList();

  /// Get cancelled tokens
  List<QueueToken> get cancelledTokens =>
      tokens.where((t) => t.isCancelled).toList();

  /// Get current token (first active token)
  QueueToken? get currentToken =>
      activeTokens.isNotEmpty ? activeTokens.first : null;
}
