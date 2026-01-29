import 'package:dartz/dartz.dart';
import 'package:sewa_web/features/officials/domain/entities/official.dart';
import 'package:sewa_web/core/errors/failures.dart';

/// Officials Repository Interface
abstract class OfficialsRepository {
  /// Get all officials for a ministry
  Future<Either<Failure, List<Official>>> getOfficials(String ministryId);

  /// Get a single official by ID
  Future<Either<Failure, Official>> getOfficialById(String officialId);

  /// Create a new official
  Future<Either<Failure, Official>> createOfficial({
    required String ministryId,
    required String name,
    required String role,
  });

  /// Update an existing official
  Future<Either<Failure, Official>> updateOfficial({
    required String officialId,
    required String name,
    required String role,
    required bool isActive,
  });

  /// Delete an official
  Future<Either<Failure, void>> deleteOfficial(String officialId);
}
