import 'package:dartz/dartz.dart';
import 'package:sewa_sathi/core/errors/exceptions.dart';
import 'package:sewa_sathi/core/errors/failures.dart';
import 'package:sewa_sathi/core/network/network_info.dart';
import 'package:sewa_sathi/features/profile/data/data_sources/profile_local_data_source.dart';
import 'package:sewa_sathi/features/profile/data/data_sources/profile_remote_data_source.dart';
import 'package:sewa_sathi/features/profile/domain/entities/place_entity.dart';
import 'package:sewa_sathi/features/profile/domain/entities/profile_entity.dart';
import 'package:sewa_sathi/features/profile/domain/repositories/profile_repository.dart';

/// Implementation of ProfileRepository.
class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;
  final ProfileLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  ProfileRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, ProfileEntity?>> checkProfileStatus() async {
    if (await networkInfo.isConnected) {
      try {
        final profile = await remoteDataSource.checkProfileStatus();

        // Cache the profile if it exists and is complete
        if (profile != null && profile.isProfileComplete) {
          await localDataSource.cacheProfile(profile);
        }

        return Right(profile);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } on AuthenticationException catch (e) {
        return Left(AuthenticationFailure(message: e.message));
      } catch (e) {
        return const Left(ServerFailure(message: 'Failed to check profile status'));
      }
    } else {
      // Try to get cached profile when offline
      try {
        final cachedProfile = await localDataSource.getCachedProfile();
        return Right(cachedProfile);
      } catch (e) {
        return const Left(NetworkFailure(message: 'No internet connection'));
      }
    }
  }

  @override
  Future<Either<Failure, List<PlaceEntity>>> getPlaces() async {
    if (await networkInfo.isConnected) {
      try {
        final places = await remoteDataSource.getPlaces();
        return Right(places);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } on AuthenticationException catch (e) {
        return Left(AuthenticationFailure(message: e.message));
      } catch (e) {
        return const Left(ServerFailure(message: 'Failed to fetch places'));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, ProfileEntity>> setupProfile({
    required String fullName,
    required String placeId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final profile = await remoteDataSource.setupProfile(
          fullName: fullName,
          placeId: placeId,
        );

        // Cache the newly created profile
        await localDataSource.cacheProfile(profile);

        return Right(profile);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } on AuthenticationException catch (e) {
        return Left(AuthenticationFailure(message: e.message));
      } catch (e) {
        return const Left(ServerFailure(message: 'Failed to setup profile'));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, ProfileEntity>> updateProfile({
    String? fullName,
    String? placeId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final profile = await remoteDataSource.updateProfile(
          fullName: fullName,
          placeId: placeId,
        );

        // Cache the updated profile
        await localDataSource.cacheProfile(profile);

        return Right(profile);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } on AuthenticationException catch (e) {
        return Left(AuthenticationFailure(message: e.message));
      } catch (e) {
        return const Left(ServerFailure(message: 'Failed to update profile'));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }
}
