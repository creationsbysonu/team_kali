import 'package:dartz/dartz.dart';
import 'package:sewa_web/core/errors/failures.dart';
import 'package:sewa_web/features/auth/domain/entities/ministry.dart';

/// Repository for public ministry operations (no authentication required)
abstract class PublicMinistryRepository {
  /// Get list of active ministries in a specific place
  Future<Either<Failure, List<Ministry>>> getMinistriesByPlace(
    String placeSlug,
  );

  /// Get ministry details by place and ministry slug
  Future<Either<Failure, Ministry>> getMinistryDetail(
    String placeSlug,
    String ministrySlug,
  );
}
