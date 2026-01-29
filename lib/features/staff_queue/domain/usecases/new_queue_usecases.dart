import 'package:dartz/dartz.dart';
import 'package:sewa_web/core/errors/failures.dart';
import 'package:sewa_web/core/usecases/usecase.dart';
import 'package:sewa_web/features/staff_queue/domain/entities/staff_token.dart';
import 'package:sewa_web/features/staff_queue/domain/repositories/staff_queue_repository.dart';

/// Get Active Tokens Use Case
class GetActiveTokensUseCase implements UseCase<ActiveTokensData, String> {
  final StaffQueueRepository repository;

  GetActiveTokensUseCase(this.repository);

  @override
  Future<Either<Failure, ActiveTokensData>> call(String staffServiceId) {
    return repository.getActiveTokens(staffServiceId);
  }
}

/// Get All Tokens Use Case
class GetAllTokensUseCase implements UseCase<AllTokensData, String> {
  final StaffQueueRepository repository;

  GetAllTokensUseCase(this.repository);

  @override
  Future<Either<Failure, AllTokensData>> call(String staffServiceId) {
    return repository.getAllTokens(staffServiceId);
  }
}

/// Get Pending Tokens Use Case
class GetPendingTokensUseCase implements UseCase<PendingTokensData, String> {
  final StaffQueueRepository repository;

  GetPendingTokensUseCase(this.repository);

  @override
  Future<Either<Failure, PendingTokensData>> call(String staffServiceId) {
    return repository.getPendingTokens(staffServiceId);
  }
}

/// Start Service Use Case
class StartServiceUseCase implements UseCase<StartServiceResult, String> {
  final StaffQueueRepository repository;

  StartServiceUseCase(this.repository);

  @override
  Future<Either<Failure, StartServiceResult>> call(String tokenId) {
    return repository.startService(tokenId);
  }
}

/// Mark No Show Use Case
class MarkNoShowUseCase implements UseCase<NoShowResult, String> {
  final StaffQueueRepository repository;

  MarkNoShowUseCase(this.repository);

  @override
  Future<Either<Failure, NoShowResult>> call(String tokenId) {
    return repository.markNoShow(tokenId);
  }
}

/// Mark Pending Params
class MarkPendingParams {
  final String tokenId;
  final String reason;

  MarkPendingParams({required this.tokenId, required this.reason});
}

/// Mark Pending Use Case
class MarkPendingUseCase
    implements UseCase<MarkPendingResult, MarkPendingParams> {
  final StaffQueueRepository repository;

  MarkPendingUseCase(this.repository);

  @override
  Future<Either<Failure, MarkPendingResult>> call(MarkPendingParams params) {
    return repository.markPending(params.tokenId, params.reason);
  }
}

/// Send Pending Email Use Case
class SendPendingEmailUseCase implements UseCase<void, String> {
  final StaffQueueRepository repository;

  SendPendingEmailUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String tokenId) {
    return repository.sendPendingEmail(tokenId);
  }
}

/// Mark Pending Served Use Case
class MarkPendingServedUseCase
    implements UseCase<MarkPendingServedResult, String> {
  final StaffQueueRepository repository;

  MarkPendingServedUseCase(this.repository);

  @override
  Future<Either<Failure, MarkPendingServedResult>> call(String tokenId) {
    return repository.markPendingServed(tokenId);
  }
}
