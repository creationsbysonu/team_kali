import 'package:dartz/dartz.dart';
import 'package:sewa_web/core/errors/failures.dart';
import 'package:sewa_web/features/ministry/domain/entities/ministry_official.dart';

/// Abstract repository for Officials operations
abstract class OfficialsRepository {
  /// List all officials (with optional filters)
  Future<Either<Failure, List<MinistryOfficial>>> getOfficials({
    String? ministryId,
    bool? isActive,
  });

  /// Get official by ID
  Future<Either<Failure, MinistryOfficial>> getOfficialById(String id);

  /// Create new official
  Future<Either<Failure, MinistryOfficial>> createOfficial({
    required String ministryId,
    required String name,
    required String role,
    bool isActive = true,
  });

  /// Update official
  Future<Either<Failure, MinistryOfficial>> updateOfficial({
    required String id,
    String? name,
    String? role,
    bool? isActive,
  });

  /// Delete official
  Future<Either<Failure, void>> deleteOfficial(String id);

  /// Toggle official status
  Future<Either<Failure, MinistryOfficial>> toggleOfficialStatus(String id);
}
