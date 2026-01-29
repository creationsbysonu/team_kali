import 'package:equatable/equatable.dart';

/// Progress step status
enum ProgressStepStatus {
  completed('COMPLETED'),
  pending('PENDING'),
  notStarted('NOT_STARTED');

  final String value;
  const ProgressStepStatus(this.value);

  static ProgressStepStatus fromString(String value) {
    switch (value.toUpperCase()) {
      case 'COMPLETED':
        return ProgressStepStatus.completed;
      case 'PENDING':
        return ProgressStepStatus.pending;
      case 'NOT_STARTED':
        return ProgressStepStatus.notStarted;
      default:
        return ProgressStepStatus.notStarted;
    }
  }
}

/// Progress step in progress token
class TokenProgressStep extends Equatable {
  final String id;
  final int stepNumber;
  final String title;
  final ProgressStepStatus status;
  final DateTime? completedAt;
  final String? completedBy;
  final String? notes;

  const TokenProgressStep({
    required this.id,
    required this.stepNumber,
    required this.title,
    required this.status,
    this.completedAt,
    this.completedBy,
    this.notes,
  });

  @override
  List<Object?> get props => [
    id,
    stepNumber,
    title,
    status,
    completedAt,
    completedBy,
    notes,
  ];

  bool get isCompleted => status == ProgressStepStatus.completed;
  bool get isPending => status == ProgressStepStatus.pending;
  bool get isNotStarted => status == ProgressStepStatus.notStarted;
}

/// Progress Token entity for staff workbench
class ProgressToken extends Equatable {
  final String id;
  final int tokenNumber;
  final String citizenName;
  final String? citizenPhone;
  final String serviceName;
  final DateTime serviceDate;
  final int totalSteps;
  final int completedSteps;
  final List<TokenProgressStep> progressSteps;

  const ProgressToken({
    required this.id,
    required this.tokenNumber,
    required this.citizenName,
    this.citizenPhone,
    required this.serviceName,
    required this.serviceDate,
    required this.totalSteps,
    required this.completedSteps,
    required this.progressSteps,
  });

  @override
  List<Object?> get props => [
    id,
    tokenNumber,
    citizenName,
    citizenPhone,
    serviceName,
    serviceDate,
    totalSteps,
    completedSteps,
    progressSteps,
  ];

  /// Check if all steps are completed
  bool get isFullyCompleted => completedSteps == totalSteps;

  /// Get progress percentage
  double get progressPercentage =>
      totalSteps > 0 ? (completedSteps / totalSteps) * 100 : 0;

  /// Get next pending step
  TokenProgressStep? get nextPendingStep {
    try {
      return progressSteps.firstWhere((step) => step.isPending);
    } catch (e) {
      return null;
    }
  }

  /// Get all completed steps
  List<TokenProgressStep> get completedStepsList =>
      progressSteps.where((step) => step.isCompleted).toList();

  /// Get all pending steps
  List<TokenProgressStep> get pendingStepsList =>
      progressSteps.where((step) => step.isPending).toList();
}
