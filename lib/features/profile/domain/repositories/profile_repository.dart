import 'package:dartz/dartz.dart';
import 'package:sewa_sathi/core/errors/failures.dart';
import 'package:sewa_sathi/features/profile/domain/entities/place_entity.dart';
import 'package:sewa_sathi/features/profile/domain/entities/profile_entity.dart';

/// Abstract repository for profile-related operations.
abstract class ProfileRepository {
  /// Check if the user's profile is complete.
  ///
  /// Returns [ProfileEntity] if profile exists and is complete,
  /// returns null if profile is incomplete or doesn't exist.
  Future<Either<Failure, ProfileEntity?>> checkProfileStatus();

  /// Get the list of available places.
  Future<Either<Failure, List<PlaceEntity>>> getPlaces();

  /// Setup a new profile with full name and selected place.
  Future<Either<Failure, ProfileEntity>> setupProfile({
    required String fullName,
    required String placeId,
  });

  /// Update existing profile (name and/or place).
  Future<Either<Failure, ProfileEntity>> updateProfile({
    String? fullName,
    String? placeId,
  });
}
