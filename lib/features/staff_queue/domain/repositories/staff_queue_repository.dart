import 'package:dartz/dartz.dart';
import 'package:sewa_web/core/errors/failures.dart';
import 'package:sewa_web/features/staff_queue/domain/entities/staff_token.dart';

/// Staff Queue Repository Interface (New Queue System)
///
/// This repository handles all staff queue operations including:
/// - Active tokens (WAITING, IN_SERVICE)
/// - All tokens (complete history)
/// - Pending tokens (government fault)
/// - Token actions (start service, no-show, pending, etc.)
abstract class StaffQueueRepository {
  /// Get active tokens (WAITING, IN_SERVICE)
  Future<Either<Failure, ActiveTokensData>> getActiveTokens(
    String staffServiceId,
  );

  /// Get all tokens (complete history)
  Future<Either<Failure, AllTokensData>> getAllTokens(String staffServiceId);

  /// Get pending tokens (government fault)
  Future<Either<Failure, PendingTokensData>> getPendingTokens(
    String staffServiceId,
  );

  /// Start service for a token (begins countdown)
  Future<Either<Failure, StartServiceResult>> startService(String tokenId);

  /// Mark token as no-show (citizen absent)
  Future<Either<Failure, NoShowResult>> markNoShow(String tokenId);

  /// Mark token as pending (government/system fault)
  Future<Either<Failure, MarkPendingResult>> markPending(
    String tokenId,
    String reason,
  );

  /// Send pending email notification to citizen
  Future<Either<Failure, void>> sendPendingEmail(String tokenId);

  /// Mark pending token as served (on priority date)
  Future<Either<Failure, MarkPendingServedResult>> markPendingServed(
    String tokenId,
  );
}
