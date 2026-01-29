import 'package:dartz/dartz.dart';
import 'package:sewa_web/core/errors/exceptions.dart';
import 'package:sewa_web/core/errors/failures.dart';
import 'package:sewa_web/core/network/network_info.dart';
import 'package:sewa_web/features/places/data/data_sources/place_remote_data_source.dart';
import 'package:sewa_web/features/places/domain/entities/place.dart';
import 'package:sewa_web/features/places/domain/repositories/place_repository.dart';

/// Implementation of PlaceRepository
class PlaceRepositoryImpl implements PlaceRepository {
  final PlaceRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  PlaceRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<Place>>> getPublicPlaces() async {
    if (await networkInfo.isConnected) {
      try {
        final places = await remoteDataSource.getPublicPlaces();
        return Right(places);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, Place>> getPlaceBySlug(String slug) async {
    if (await networkInfo.isConnected) {
      try {
        final place = await remoteDataSource.getPlaceBySlug(slug);
        return Right(place);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, List<Place>>> getAllPlaces() async {
    if (await networkInfo.isConnected) {
      try {
        final places = await remoteDataSource.getAllPlaces();
        return Right(places);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, Place>> createPlace({
    required String name,
    required String slug,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final place = await remoteDataSource.createPlace(
          name: name,
          slug: slug,
        );
        return Right(place);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, Place>> updatePlace({
    required String id,
    String? name,
    String? slug,
    bool? isActive,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final place = await remoteDataSource.updatePlace(
          id: id,
          name: name,
          slug: slug,
          isActive: isActive,
        );
        return Right(place);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deletePlace(String id) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deletePlace(id);
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }
}
