import 'package:equatable/equatable.dart';

/// Token action type
enum TokenActionType {
  served('SERVED'),
  noShow('NO_SHOW'),
  cancel('CANCEL');

  final String value;
  const TokenActionType(this.value);
}

/// Token action request
class TokenAction extends Equatable {
  final String tokenId;
  final TokenActionType action;
  final String? reason;

  const TokenAction({required this.tokenId, required this.action, this.reason});

  @override
  List<Object?> get props => [tokenId, action, reason];
}

/// Token action response
class TokenActionResult extends Equatable {
  final bool success;
  final String message;
  final int? nextTokenNumber;
  final int? newTokenNumber; // For NO_SHOW (pushed back position)

  const TokenActionResult({
    required this.success,
    required this.message,
    this.nextTokenNumber,
    this.newTokenNumber,
  });

  @override
  List<Object?> get props => [
    success,
    message,
    nextTokenNumber,
    newTokenNumber,
  ];
}

/// Progress step completion request
class CompleteProgressStep extends Equatable {
  final String stepId;
  final String? notes;

  const CompleteProgressStep({required this.stepId, this.notes});

  @override
  List<Object?> get props => [stepId, notes];
}

/// Progress step completion result
class ProgressStepResult extends Equatable {
  final bool success;
  final String message;
  final String tokenId;
  final int stepOrder;
  final String stepTitle;
  final DateTime completedAt;
  final int remainingSteps;

  const ProgressStepResult({
    required this.success,
    required this.message,
    required this.tokenId,
    required this.stepOrder,
    required this.stepTitle,
    required this.completedAt,
    required this.remainingSteps,
  });

  @override
  List<Object?> get props => [
    success,
    message,
    tokenId,
    stepOrder,
    stepTitle,
    completedAt,
    remainingSteps,
  ];
}
