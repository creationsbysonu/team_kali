import 'package:dartz/dartz.dart';
import 'package:sewa_web/core/errors/failures.dart';
import 'package:sewa_web/features/places/domain/entities/place.dart';

/// Abstract repository for Place operations
abstract class PlaceRepository {
  /// Get all public places (for selection)
  Future<Either<Failure, List<Place>>> getPublicPlaces();

  /// Get place by slug
  Future<Either<Failure, Place>> getPlaceBySlug(String slug);

  /// Get all places (admin view)
  Future<Either<Failure, List<Place>>> getAllPlaces();

  /// Create a new place (super admin only)
  Future<Either<Failure, Place>> createPlace({
    required String name,
    required String slug,
  });

  /// Update place
  Future<Either<Failure, Place>> updatePlace({
    required String id,
    String? name,
    String? slug,
    bool? isActive,
  });

  /// Delete place
  Future<Either<Failure, void>> deletePlace(String id);
}
