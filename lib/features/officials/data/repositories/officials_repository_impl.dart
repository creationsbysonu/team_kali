import 'package:dartz/dartz.dart';
import 'package:sewa_web/core/errors/exceptions.dart';
import 'package:sewa_web/core/errors/failures.dart';
import 'package:sewa_web/core/network/network_info.dart';
import 'package:sewa_web/features/officials/data/data_sources/officials_remote_data_source.dart';
import 'package:sewa_web/features/officials/domain/entities/official.dart';
import 'package:sewa_web/features/officials/domain/repositories/officials_repository.dart';

/// Officials Repository Implementation
class OfficialsRepositoryImpl implements OfficialsRepository {
  final OfficialsRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  OfficialsRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<Official>>> getOfficials(
    String ministryId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final officials = await remoteDataSource.getOfficials(ministryId);
        return Right(officials);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure(message: "No internet connection"));
    }
  }

  @override
  Future<Either<Failure, Official>> getOfficialById(String officialId) async {
    if (await networkInfo.isConnected) {
      try {
        final official = await remoteDataSource.getOfficialById(officialId);
        return Right(official);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure(message: "No internet connection"));
    }
  }

  @override
  Future<Either<Failure, Official>> createOfficial({
    required String ministryId,
    required String name,
    required String role,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final officialData = {
          'ministry': ministryId,
          'name': name,
          'role': role,
        };
        final official = await remoteDataSource.createOfficial(officialData);
        return Right(official);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure(message: "No internet connection"));
    }
  }

  @override
  Future<Either<Failure, Official>> updateOfficial({
    required String officialId,
    required String name,
    required String role,
    required bool isActive,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final officialData = {
          'name': name,
          'role': role,
          'is_active': isActive,
        };
        final official = await remoteDataSource.updateOfficial(
          officialId,
          officialData,
        );
        return Right(official);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure(message: "No internet connection"));
    }
  }

  @override
  Future<Either<Failure, void>> deleteOfficial(String officialId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteOfficial(officialId);
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure(message: "No internet connection"));
    }
  }
}
